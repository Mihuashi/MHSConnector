//
//  JDCModuleManager.m
//  JDComConnector
//
//  Created by 靳海涛 on 2022/4/13.
//

#import "MHSModuleCenter.h"
#import "MHSConnector.h"

#import <objc/runtime.h>

@interface MHSModuleCenter ()

/// 已经注册的组件
@property (nonatomic, strong) NSMutableArray<NSString *> *moduleClasses;
/// 未注册的组件
@property (nonatomic, strong) NSMutableArray<Class> *unregisterModules;
/// 自定义事件注册信息
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<id<MHSModuleProtocol>> *> *customEventDict;
/// 分发器注册信息
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<MHSModuleProtocol>> *dispatcherDict;
/// 锁
@property (nonatomic, strong) NSRecursiveLock *lock;
/// 环境搭建是否完成，避免重复初始化组件
@property (nonatomic, assign) BOOL isAppEnvironmentSetup;

@end


@implementation MHSModuleCenter

- (instancetype)init {
    self = [super init];
    if (self) {
        _moduleClasses = [NSMutableArray array];
        _moduleInstances = [NSMutableArray array];
        _unregisterModules = [NSMutableArray array];
        _customEventDict = [NSMutableDictionary dictionary];
        _dispatcherDict = [[NSMutableDictionary alloc] init];
        _lock = [[NSRecursiveLock alloc] init];
        _isAppEnvironmentSetup = NO;
    }
    
    return self;
}

#pragma mark - public method
+ (instancetype)shared {
    static id center = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [[MHSModuleCenter alloc] init];
    });
    
    return center;
}

- (void)addReadyRegisterModule:(Class)moduleClass {
    if (moduleClass) {
        [_unregisterModules addObject:moduleClass];
    }
}

- (void)registerAllModules {
    [_unregisterModules sortUsingComparator:^NSComparisonResult(Class  _Nonnull obj1, Class  _Nonnull obj2) {
        NSInteger priority1 = 0;
        if ([obj1 conformsToProtocol:@protocol(MHSModuleProtocol)]
            && [obj1 respondsToSelector:@selector(modulePriority)]) {
            priority1 = [obj1 modulePriority];
        }
        NSInteger priority2 = 0;
        if ([obj2 conformsToProtocol:@protocol(MHSModuleProtocol)]
            && [obj2 respondsToSelector:@selector(modulePriority)]) {
            priority2 = [obj2 modulePriority];
        }
        return priority1 < priority2;
    }];

    [_unregisterModules enumerateObjectsUsingBlock:^(Class  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self registerModule:obj];
    }];
    [_unregisterModules removeAllObjects];
    // 延迟5秒触发首页加载完成事件，如果已经触发过则忽略
    int64_t delay = (int64_t)(MHSConnectorContext.environmentSetupInterval * NSEC_PER_SEC);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue(), ^{
        [self triggerAppEnvironmentDidSetup];
    });
}

- (void)registerModule:(Class)moduleClass {
    [self registerModule:moduleClass shouldInit:NO];
}

- (void)registerModule:(Class)moduleClass shouldInit:(BOOL)shouldInit {
    [_lock lock];
    NSString *className = NSStringFromClass(moduleClass);
    if (!className ||
        [_moduleClasses containsObject:className] ||
        ![self conformModuleProtocol:moduleClass]) {
        [_lock unlock];
        return;
    }
    id<MHSModuleProtocol> instance = [[moduleClass alloc] init];
    [_moduleInstances addObject:instance];
    [_moduleClasses addObject:className];
    [_moduleInstances sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [self modulePriority:obj1] < [self modulePriority:obj2];
    }];
    [_lock unlock];
    MHSContext *context = [MHSConnectorContext copy];
    SEL selector = @selector(moduleRegister:);
    if ([instance respondsToSelector:selector]) {
        [self handleModulesState:selector instance:instance context:context];
    }
    if (shouldInit) {
        selector = @selector(moduleInit:);
        if ([instance respondsToSelector:selector]) {
            [self handleModulesState:selector instance:instance context:context];
        }
    }
}

- (void)registerCustomEvent:(NSString *)key moduleInstance:(id)moduleInstance {
    if (!key || !moduleInstance || ![self conformModuleProtocol:moduleInstance]) {
        return;
    }
    [_lock lock];
    NSMutableArray *array;
    if (_customEventDict[key]) {
        array = [NSMutableArray arrayWithArray:_customEventDict[key]];
    } else {
        array = [NSMutableArray array];
    }
    [array addObject:moduleInstance];
    _customEventDict[key] = array;
    [_lock unlock];
}

- (void)unregisterCustomEvent:(NSString *)key moduleInstance:(id)moduleInstance {
    if (!key || !moduleInstance || ![self conformModuleProtocol:moduleInstance]) {
        return;
    }
    [_lock lock];
    if (_customEventDict[key]) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:_customEventDict[key]];
        [array removeObject:moduleInstance];
        _customEventDict[key] = array;
    }
    [_lock unlock];
}

- (void)unregisterCustomEvent:(id)moduleInstance {
    if (!moduleInstance || ![self conformModuleProtocol:moduleInstance]) {
        return;
    }
    NSArray *keys = [_customEventDict allKeys];
    [keys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self unregisterCustomEvent:obj moduleInstance:moduleInstance];
    }];
}

- (void)unregisterDynamicModule:(Class)moduleClass {
    if (!moduleClass || !NSStringFromClass(moduleClass)) {
        return;
    }
    [_lock lock];
    __block id<MHSModuleProtocol> tempInstance;
    NSArray *moduls = [_moduleInstances copy];
    [moduls enumerateObjectsUsingBlock:^(id<MHSModuleProtocol> instance, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([instance isKindOfClass:moduleClass]) {
            tempInstance = instance;
            *stop = YES;
        }
    }];
    if (tempInstance) {
        [self handleModulesState:@selector(moduleTearDown:) instance:tempInstance context:[MHSConnectorContext copy]];
        [_moduleInstances removeObject:tempInstance];
        [_moduleClasses removeObject:NSStringFromClass(moduleClass)];
    }
    [_lock unlock];
}

- (void)triggerAppEnvironmentDidSetup {
    if (!_isAppEnvironmentSetup) {
        _isAppEnvironmentSetup = YES;
        [self handleModulesState:@selector(moduleInit:)];
        [self triggerSystemEvent:^(id<MHSModuleProtocol> module) {
            if ([module respondsToSelector:@selector(applicationEnvironmentDidSetup:)]) {
                [module applicationEnvironmentDidSetup:[MHSConnectorContext copy]];
            }
        }];
    }
}

- (void)triggerCustomEvent:(NSString *)key customParam:(id)customParam {
    if (!key) {
        return;
    }
    NSArray *array;
    if (_customEventDict[key]) {
        array = [_customEventDict[key] copy];
    } else {
        array = [_moduleInstances copy];
    }
    SEL selector = @selector(moduleDidCustomEvent:customParam:);
    [array enumerateObjectsUsingBlock:^(id<MHSModuleProtocol> instance, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([instance respondsToSelector:selector]) {
//            NSString *className = NSStringFromClass([instance class]);
            NSString *selectorName = NSStringFromSelector(selector);
//            NSString *eventName = [NSString stringWithFormat:@"%@(%@)", selectorName, key];
            [instance moduleDidCustomEvent:key customParam:customParam];
        }
    }];
}

- (void)registerDispatcher:(Class)dispatcher forModuleInstance:(id<MHSModuleProtocol>)moduleInstance {
    NSString *dispatcherKey = NSStringFromClass(dispatcher);
    if (dispatcherKey.length == 0) {
        return;
    }
    [_lock lock];
    self.dispatcherDict[dispatcherKey] = moduleInstance;
    [_lock unlock];
}

- (void)triggerModuleInitIfNeededForDispatcher:(Class)dispatcher {
    NSString *dispatcherKey = NSStringFromClass(dispatcher);
    if (dispatcherKey.length == 0) {
        return;
    }
    id<MHSModuleProtocol> moduleInstance = nil;
    [_lock lock];
    moduleInstance = self.dispatcherDict[dispatcherKey];
    [_lock unlock];
    [self handleModulesState:@selector(moduleInit:) instance:moduleInstance context:[MHSConnectorContext copy]];
}

- (void)triggerSystemEvent:(void(^)(id<MHSModuleProtocol> module))block {
    NSArray *modules = [_moduleInstances copy];
    [modules enumerateObjectsUsingBlock:^(id<MHSModuleProtocol> instance, NSUInteger idx, BOOL * _Nonnull stop) {
        block(instance);
    }];
}

- (id)getInstanceWithModuleClass:(Class)moduleClass {
    if (!moduleClass || !NSStringFromClass(moduleClass)) {
        return nil;
    }
    [_lock lock];
    NSString *dispatcherKey = NSStringFromClass(moduleClass);
    id<MHSModuleProtocol> moduleInstance = self.dispatcherDict[dispatcherKey];
    __block id<MHSModuleProtocol> tempInstance = nil;
    NSArray *moduls = [_moduleInstances copy];
    [moduls enumerateObjectsUsingBlock:^(id<MHSModuleProtocol> instance, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([instance isKindOfClass:moduleInstance.class]) {
            tempInstance = instance;
            *stop = YES;
        }
    }];
    [_lock unlock];
    
    return tempInstance;
}

#pragma mark - private method
- (NSInteger)modulePriority:(id)instance {
    NSInteger priority = 0;
    if ([self conformModuleProtocol:instance] &&
        [[instance class] respondsToSelector:@selector(modulePriority)]) {
        priority = [[instance class] modulePriority];
    }
    
    return priority;
}

/** 处理生命周期事件
 *  @param selector 处理生命周期方法
 */
- (void)handleModulesState:(SEL)selector {
    if (!selector) {
        return;
    }
    MHSContext *context = [MHSConnectorContext copy];
    NSArray *modules = [_moduleInstances copy];
    [modules enumerateObjectsUsingBlock:^(id<MHSModuleProtocol> instance, NSUInteger idx, BOOL * _Nonnull stop) {
        [self handleModulesState:selector instance:instance context:context];
    }];
}

- (void)handleModulesState:(SEL)selector instance:(id<MHSModuleProtocol>)instance context:(MHSContext *)context {
    if (selector && instance && [instance respondsToSelector:selector]) {
        if ([objc_getAssociatedObject(instance, selector) boolValue]) { return; }
        if (selector == @selector(moduleInit:)) {
            NSLog(@"%@ init!", [instance class]);
        }
        
//        NSString *className = NSStringFromClass([instance class]);
//        NSString *selectorName = NSStringFromSelector(selector);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [instance performSelector:selector withObject:context];
#pragma clang diagnostic pop
        objc_setAssociatedObject(instance, selector, @(YES), OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

- (void)handleModulesTearDown {
    MHSContext *context = [MHSConnectorContext copy];
    SEL selector = @selector(moduleTearDown:);
    for (NSInteger i = _moduleInstances.count - 1; i >= 0; i--) {
        id<MHSModuleProtocol> instance = _moduleInstances[i];
        if ([instance respondsToSelector:selector]) {
            [self handleModulesState:selector instance:instance context:context];;
        }
    }
}

- (void)removeAllModules {
    [_moduleInstances removeAllObjects];
    [_moduleClasses removeAllObjects];
    [_customEventDict removeAllObjects];
}

/** 是否遵守组件通用协议
 *  @param instance 对象
 *  @return 结果
 */
- (BOOL)conformModuleProtocol:(id)instance {
    return [instance conformsToProtocol:@protocol(MHSModuleProtocol)];
}


@end
