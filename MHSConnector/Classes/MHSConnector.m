//
//  MHSConnector.m
//  MHSConnector
//
//  Created by 赵柳 on 2022/4/13.
//

#import "MHSConnector.h"
#import "MHSModuleCenter.h"
#import "MHSServiceCenter.h"

#import <objc/runtime.h>

@implementation MHSConnector

- (instancetype)init {
    self = [super init];
    if (self) {
        _applicationDelegate = [[MHSApplicationDelegate alloc] init];
    }
    
    return self;
}

#pragma mark - public
+ (instancetype)shared {
    static dispatch_once_t p;
    static id instance = nil;
    dispatch_once(&p, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

+ (void)registerCustomEvent:(NSString *)key moduleInstance:(id)moduleInstance {
    [[MHSModuleCenter shared] registerCustomEvent:key moduleInstance:moduleInstance];
}

+ (void)unregisterCustomEvent:(NSString *)key moduleInstance:(id)moduleInstance {
    [[MHSModuleCenter shared] unregisterCustomEvent:key moduleInstance:moduleInstance];
}

+ (void)unregisterCustomEvent:(id)moduleInstance {
    [[MHSModuleCenter shared] unregisterCustomEvent:moduleInstance];
}

+ (void)triggerCustomEvent:(NSString *)key {
    [[MHSModuleCenter shared] triggerCustomEvent:key customParam:nil];
}

+ (void)triggerCustomEvent:(NSString *)key customParam:(id)customParam {
    [[MHSModuleCenter shared] triggerCustomEvent:key customParam:customParam];
}

+ (void)applicationEnvironmentDidSetup {
    [[MHSModuleCenter shared] triggerAppEnvironmentDidSetup];
}

+ (void)applicationMakeKeyWindowAndVisible {
    [[MHSModuleCenter shared] triggerSystemEvent:^(id<MHSModuleProtocol> module) {
        if ([module respondsToSelector:@selector(applicationMakeKeyWindowAndVisible)]) {
            [module applicationMakeKeyWindowAndVisible];
        }
    }];
}

+ (id)mhsPerformSelector:(MHSConnectorItem *)item {
    if (item.alias.length == 0 || !item.selector) {
        return nil;
    }
    SEL sel = NSSelectorFromString(item.alias);
    SEL action = item.selector;

    Class clazz = [[MHSServiceCenter shared] createClassServiceWithAlias:sel];
    id instance = [[MHSModuleCenter shared] getInstanceWithModuleClass:clazz];
    
    if (instance && clazz && [clazz respondsToSelector:action]) {
        return [self safePerformAction:action target:clazz params:item.params];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//        return [clazz performSelector:action withObject:item.params];
#pragma clang diagnostic pop
        
    } else {
#if DEBUG
        if (!instance) {
            NSLog(@"组件已注销");
        } else {
            NSLog(@"selector 错误");
        }
#endif
    }
    
    return nil;
}

+ (id)mhsPerformSelector:(MHSConnectorItem *)item asynCompletion:(void (^)(id result))asynCompletion {
    if (asynCompletion) {
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithDictionary:item.params];
        [dic setValue:asynCompletion forKey:@"asynCompletion"];
        item.params = dic;
    }
    
    return [MHSConnector mhsPerformSelector:item];
}

#pragma mark - module
+ (void)addReadyRegisterModule:(Class)moduleClass {
    [[MHSModuleCenter shared] addReadyRegisterModule:moduleClass];
}

+ (void)registerModule:(Class)moduleClass {
    [self registerModule:moduleClass shouldInit: NO];
}

+ (void)registerModule:(Class)moduleClass shouldInit:(BOOL)shouldInit {
    [[MHSModuleCenter shared] registerModule:moduleClass shouldInit:shouldInit];
}

+ (void)unregisterDynamicModule:(Class)moduleClass {
    [[MHSModuleCenter shared] unregisterDynamicModule:moduleClass];
}

+ (void)registerDispatcher:(Class)dispatcher forModuleInstance:(id<MHSModuleProtocol>)moduleInstance {
    [[MHSModuleCenter shared] registerDispatcher:dispatcher forModuleInstance:moduleInstance];
}

+ (void)triggerModuleInitIfNeededForDispatcher:(Class)dispatcher {
    [[MHSModuleCenter shared] triggerModuleInitIfNeededForDispatcher:dispatcher];
}

#pragma mark - service
+ (id)createService:(Protocol *)protocol {
    return [[MHSServiceCenter shared] createService:protocol];
}

+ (Class)createClassService:(Protocol *)protocol {
    return [[MHSServiceCenter shared] createClassService:protocol];
}

+ (Class)createClassService:(Protocol *)protocol externIdentifier:(NSString *)externIdentifier {
    return [[MHSServiceCenter shared] createClassService:protocol externIdentifier:externIdentifier];
}

+ (NSArray<Class> *)createClassServicesForRegisterProtocol:(Protocol *)protocol {
    return [[MHSServiceCenter shared] createClassServicesForRegisterProtocol:protocol];
}

+ (id)createService:(Protocol *)protocol externIdentifier:(NSString *)externIdentifier {
    return [[MHSServiceCenter shared] createService:protocol externIdentifier:externIdentifier];
}

+ (void)registerService:(Protocol *)protocol implClass:(Class) serviceClass {
    [[MHSServiceCenter shared] registerService:protocol implClass:serviceClass];
}

+ (void)registerAlias:(SEL)selector forService:(Protocol *)protocol {
    [[MHSServiceCenter shared] registerAlias:selector forService:protocol];
}

+ (void)unregisterService:(Protocol *)protocol {
    [[MHSServiceCenter shared] unregisterService:protocol];
}

+ (void)registerExternService:(Protocol *)externProtocol implClass:(Class)implClass identifier:(NSString *)identifier {
    [[MHSServiceCenter shared] registerExternService:externProtocol implClass:implClass identifier:identifier];
}

+ (NSArray *)createServicesForRegisterProtocol:(Protocol *)protocol {
    return [[MHSServiceCenter shared] createServicesForRegisterProtocol:protocol];
}

#pragma mark - runtime
Class JDCFetchService(id self, SEL _cmd) {
    Class clazz = [[MHSServiceCenter shared] createClassServiceWithAlias:_cmd];
    id instance = [[MHSModuleCenter shared] getInstanceWithModuleClass:clazz];
    if ((clazz == nil) || (instance == nil)) {
        NSLog(@"【MHSConnector Warning】%@ Alias NOT Found!", NSStringFromSelector(_cmd));
        
        return nil;
    }
    
    return clazz;
}

+ (BOOL)resolveClassMethod:(SEL)sel {
    class_addMethod(object_getClass([MHSConnector class]), sel, (IMP)JDCFetchService, "#:@");
    
    return YES;
}

#pragma mark - setter
- (void)setContext:(MHSContext *)context {
    _context = context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [MHSServiceCenter shared].enableException = self.enableException;
        [[MHSModuleCenter shared] registerAllModules];
        
    });
}

#pragma mark - private method
+ (id)safePerformAction:(SEL)action target:(Class)target params:(NSDictionary *)params {
    NSMethodSignature *methodSig = [target methodSignatureForSelector:action];
    if (methodSig == nil) {
        return nil;
    }
    const char *retType = [methodSig methodReturnType];
    
    if (strcmp(retType, @encode(void)) == 0) {
        [self invokeWithMethodSig:methodSig action:action target:target params:params];
        
        return nil;
    }
    
    if (strcmp(retType, @encode(NSInteger)) == 0) {
        NSInvocation *invocation = [self invokeWithMethodSig:methodSig action:action target:target params:params];
        
        NSInteger result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }
    
    if (strcmp(retType, @encode(BOOL)) == 0) {
        NSInvocation *invocation = [self invokeWithMethodSig:methodSig action:action target:target params:params];
        
        BOOL result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }
    
    if (strcmp(retType, @encode(CGFloat)) == 0) {
        NSInvocation *invocation = [self invokeWithMethodSig:methodSig action:action target:target params:params];
        
        CGFloat result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }
    
    if (strcmp(retType, @encode(NSUInteger)) == 2) {
        NSInvocation *invocation = [self invokeWithMethodSig:methodSig action:action target:target params:params];
        
        NSUInteger result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
}

+ (NSInvocation *)invokeWithMethodSig:(NSMethodSignature *)methodSig action:(SEL)action target:(Class)target params:(NSDictionary *)params {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
    [invocation setSelector:action];
    [invocation setTarget:target];
    // https://www.cnblogs.com/KrystalNa/p/4813800.html
    if ([[params allKeys] count] > 0) {
        [invocation setArgument:&params atIndex:2];
    }
    [invocation invoke];
    
    return invocation;
}


@end
