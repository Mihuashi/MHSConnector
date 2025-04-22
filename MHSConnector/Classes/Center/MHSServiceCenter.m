//
//  MHSServiceCenter.m
//  MHSConnector
//
//  Created by 赵柳 on 2025/4/21.
//

#import "MHSServiceCenter.h"
#import "MHSConnector.h"
#import "MHSModuleCenter.h"

#import <objc/runtime.h>

/// 默认的IdentifierKey，用于区别外部传入的Identitifier，便于统一处理
static NSString *kJDCServiceDefaultIdentifierKey = @"kJDCServiceDefaultIdentifierKey";

@interface MHSServiceCenter ()

/// 服务及实体集合
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *serviceEntities;
/// 注册的服务信息
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *registeredServices;
/// 服务别名
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *servicesAlias;
/// 锁
@property (nonatomic, strong) NSRecursiveLock *lock;

@end


@implementation MHSServiceCenter

- (instancetype)init {
    self = [super init];
    if (self) {
        _serviceEntities  = [NSMutableDictionary dictionary];
        _lock = [[NSRecursiveLock alloc] init];
        _registeredServices = [NSMutableDictionary dictionary];
        _servicesAlias = [NSMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark - public method
+ (instancetype)shared {
    static id center = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        center = [[self alloc] init];
    });
    
    return center;
}

- (void)registerService:(Protocol *)protocol implClass:(Class)implClass {
    [self registerService:protocol impl:implClass identifier:kJDCServiceDefaultIdentifierKey];
}

- (void)registerAlias:(SEL)selector forService:(Protocol *)protocol;{
    if (!selector || !protocol) {
        return;
    }
    [self addAliasDict:NSStringFromSelector(selector) forService:NSStringFromProtocol(protocol)];
}

- (void)registerExternService:(Protocol *)externProtocol implClass:(Class)implClass identifier:(NSString *)identifier {
    [self registerService:externProtocol impl:implClass identifier:identifier];
}

- (void)unregisterService:(Protocol *)protocol {
    [self removeServicesDict:protocol identifier:kJDCServiceDefaultIdentifierKey];
}

- (void)unregisterExternService:(Protocol *)externProtocol identifier:(NSString *)identifier {
    [self removeServicesDict:externProtocol identifier:identifier];
}

- (id)createService:(Protocol *)protocol {
    return [self createService:protocol identifier:kJDCServiceDefaultIdentifierKey];
}

- (id)createService:(Protocol *)protocol externIdentifier:(NSString *)externIdentifier {
    return [self createService:protocol identifier:externIdentifier];
}

- (Class)createClassService:(Protocol *)protocol {
    if (!protocol) {
        return nil;
    }
    Class implClass = [self serviceImplClass:protocol identifier:kJDCServiceDefaultIdentifierKey];
    [[MHSModuleCenter shared] triggerModuleInitIfNeededForDispatcher:implClass];
    
    return implClass;
}

- (Class)createClassServiceWithAlias:(SEL)selector {
    if (!selector) { return nil; }
    [_lock lock];
    Protocol *protocol = NSProtocolFromString(self.servicesAlias[NSStringFromSelector(selector)]);
    [_lock unlock];
    if (!protocol) { return nil; }
    
    Class implClass = [self serviceImplClass:protocol identifier:kJDCServiceDefaultIdentifierKey];
    [[MHSModuleCenter shared] triggerModuleInitIfNeededForDispatcher:implClass];
    
    return implClass;
}

- (NSArray *)createServicesForRegisterProtocol:(Protocol *)protocol {
    NSMutableArray *services = [NSMutableArray array];
    NSDictionary *serviceDict = [self servicesDict:NSStringFromProtocol(protocol)];
    for (NSString *identifier in serviceDict.allKeys) {
        id service = [self createService:protocol identifier:identifier];
        if (service) {
            [services addObject:service];
        }
    }
    
    return [services copy];
}

#pragma mark - private
- (void)addServiceWithImplInstance:(id)implInstance
                       serviceName:(NSString *)serviceName
                        identifier:(NSString *)identifier {
    if (!implInstance || !serviceName || !identifier) {
        return;
    }
    id implValue = _serviceEntities[serviceName];
    NSMutableDictionary *instanceDict;
    if (implValue && [implValue isKindOfClass:[NSDictionary class]]) {
        instanceDict = [NSMutableDictionary dictionaryWithDictionary:implValue];
    } else {
        instanceDict = [NSMutableDictionary dictionary];
    }
    [_lock lock];
    instanceDict[identifier] = implInstance;
    _serviceEntities[serviceName] = instanceDict;
    [_lock unlock];
}

- (id)serviceInstanceFromServiceName:(NSString *)serviceName identifier:(NSString *)identifier {
    if (!serviceName || !identifier) {
        return nil;
    }
    id implValue = _serviceEntities[serviceName];
    if (implValue && [implValue isKindOfClass:[NSDictionary class]]) {
        NSDictionary *instanceDict = implValue;
        return instanceDict[identifier];
    }
    return nil;
}

- (Class)serviceImplClass:(Protocol *)protocol identifier:(NSString *)identifier {
    if (!protocol) {
        return nil;
    }
    NSString *protocolStr = NSStringFromProtocol(protocol);
    if (!protocolStr) {
        NSAssert(protocolStr == nil, @"Assertion failure:protocol can not be NIL");
        return nil;
    }
    NSString *serviceImpl = [self serviceClassName:protocolStr identifier:identifier];
    if (serviceImpl.length > 0) {
        return NSClassFromString(serviceImpl);
    }
    return [self serviceClassBySubfix:protocol];
}

- (BOOL)checkValidService:(Protocol *)protocol identifier:(NSString *)identifier {
    if (!protocol || !identifier) {
        return NO;
    }
    NSString *protocolStr = NSStringFromProtocol(protocol);
    if (!protocolStr) {
        return NO;
    }
    NSString *serviceImpl = [self serviceClassName:protocolStr identifier:identifier];
    if (serviceImpl.length > 0) {
        return YES;
    }
    return NO;
}

/** 根据命名规则获取服务
 *  @param protocol 协议
 *  @return 实现类名
 */
- (Class)serviceClassBySubfix:(Protocol *)protocol {
    if (MHSConnectorContext.protocolSubfix) {
        NSString *protocolStr = NSStringFromProtocol(protocol);
        if (![protocolStr isKindOfClass:[NSString class]]) {
            return nil;
        }
        NSString *impl = [protocolStr stringByReplacingOccurrencesOfString:MHSConnectorContext.protocolSubfix withString:@""];
        Class implClass = NSClassFromString(impl);
        if (impl && implClass &&
            [implClass conformsToProtocol:protocol]) {
            return implClass;
        }
    }
    return nil;
}

/** 从注册服务信息中获取实现类名
 *  @param protocol 协议
 *  @param identifier 标识
 *  @return 实现类名
 */
- (NSString *)serviceClassName:(NSString *)protocol identifier:(NSString *)identifier {
    NSString *serviceImpl = nil;
    [_lock lock];
    if (protocol && identifier) {
        NSDictionary *dict = _registeredServices[protocol];
        if (dict.count > 0) {
            serviceImpl = dict[identifier];
        }
    }
    [_lock unlock];
    return serviceImpl;
}

/** 从注册服务信息中获取特定服务注册信息
 *  @param protocol 协议
 *  @return 服务注册信息
 */
- (NSDictionary *)servicesDict:(NSString *)protocol {
    NSDictionary *dict = nil;
    [_lock lock];
    if (protocol) {
        dict = [_registeredServices[protocol] copy];
    }
    [_lock unlock];
    
    return dict;
}

- (NSDictionary *)allServicesDict {
    NSDictionary *dict = nil;
    [_lock lock];
    dict = [_registeredServices copy];
    [_lock unlock];
    return dict;
}

- (void)removeAllServices {
    [_registeredServices removeAllObjects];
    [_serviceEntities removeAllObjects];
    [_servicesAlias removeAllObjects];
}

/** 获取服务
 *  @param protocol 协议
 *  @param identifier 标识
 *  @return 服务
 */
- (id)createService:(Protocol *)protocol identifier:(NSString *)identifier {
    if (!protocol || !identifier) {
        return nil;
    }
    if (![self checkValidService:protocol identifier:identifier]) {
        Class implClass = [self serviceClassBySubfix:protocol];
        if (!implClass && self.enableException) {
            NSString *sel = NSStringFromProtocol(protocol);
            NSString *reason = [NSString stringWithFormat:@"【MHSConnector Log】%@ protocol does not been registed", sel];
            NSLog(@"%@", reason);
        }
    }
    NSString *serviceStr = NSStringFromProtocol(protocol);
    id protocolImpl = [self serviceInstanceFromServiceName:serviceStr identifier:identifier];
    if (protocolImpl) {
        return protocolImpl;
    }
    Class implClass = [self serviceImplClass:protocol identifier:identifier];
    if ([[implClass class] respondsToSelector:@selector(singleton)]) {
        if ([[implClass class] singleton]) {
            id implInstance = nil;
            if ([[implClass class] respondsToSelector:@selector(sharedInstance)]) {
                implInstance = [[implClass class] sharedInstance];
            } else {
                implInstance = [[implClass alloc] init];
            }
            [self addServiceWithImplInstance:implInstance serviceName:serviceStr identifier:identifier];
            return implInstance;
        }
    }
    [[MHSModuleCenter shared] triggerModuleInitIfNeededForDispatcher:implClass];
    
    return [[implClass alloc] init];
}

/** 注册服务
 *  @param protocol 协议
 *  @param implClass 实现类
 *  @param identifier 标识
 */
- (void)registerService:(Protocol *)protocol impl:(Class)implClass identifier:(NSString *)identifier {
    if (!protocol || !implClass) {
        return;
    }
    NSParameterAssert(implClass != nil);
    if (!identifier || ![identifier isKindOfClass:[NSString class]] || identifier.length == 0) {
        identifier = kJDCServiceDefaultIdentifierKey;
    }
    NSString *errorReason = nil;
    if (![implClass conformsToProtocol:protocol]) {
        errorReason = [NSString stringWithFormat:@"【MHSConnector Log】%@ module does not comply with %@ protocol",
                       NSStringFromClass(implClass), NSStringFromProtocol(protocol)];
    } else if ([self checkValidService:protocol identifier:identifier]) {
        errorReason = [NSString stringWithFormat:@"【MHSConnector Log】%@ protocol has been registed",
                       NSStringFromProtocol(protocol)];
    }
    if (errorReason && self.enableException) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:errorReason userInfo:nil];
    }
    
    NSString *key = NSStringFromProtocol(protocol);
    NSString *value = NSStringFromClass(implClass);
    if (key.length > 0 && value.length > 0) {
        [_lock lock];
        id implValue = _registeredServices[key];
        NSMutableDictionary *dict;
        if (implValue && [implValue isKindOfClass:[NSDictionary class]]) {
            dict = [NSMutableDictionary dictionaryWithDictionary:implValue];
        } else {
            dict = [NSMutableDictionary dictionary];
        }
        dict[identifier] = value;
        _registeredServices[key] = dict;
        [_lock unlock];
    }
}

- (void)addAliasDict:(NSString *)selector forService:(NSString *)protocol {
    if (![protocol isKindOfClass:[NSString class]] ||
        ![selector isKindOfClass:[NSString class]] ||
        selector.length == 0) {
        return;
    }
    
    [self.lock lock];
    self.servicesAlias[selector] = protocol;
    [self.lock unlock];
}

- (Class)createClassService:(Protocol *)protocol externIdentifier:(NSString *)externIdentifier {
    if (!protocol) {
        return nil;
    }
    Class implClass = [self serviceImplClass:protocol identifier:externIdentifier];
    [[MHSModuleCenter shared] triggerModuleInitIfNeededForDispatcher:implClass];
    
    return implClass;
}

- (NSArray<Class> *)createClassServicesForRegisterProtocol:(Protocol *)protocol {
    NSMutableArray *services = [NSMutableArray array];
    NSDictionary *serviceDict = [self servicesDict:NSStringFromProtocol(protocol)];
    for (NSString *identifier in serviceDict.allKeys) {
        id service = [self createClassService:protocol externIdentifier:identifier];
        if (service) {
            [services addObject:service];
        }
    }
    
    return [services copy];
}

- (void)removeServicesDict:(Protocol *)protocol identifier:(NSString *)identifier {
    if (!protocol || !identifier) {
        return;
    }
    NSString *serviceStr = NSStringFromProtocol(protocol);
    if (serviceStr && identifier && [self checkValidService:protocol identifier:identifier]) {
        [_lock lock];
        id implValue = _registeredServices[serviceStr];
        if (implValue && [implValue isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:implValue];
            [dict removeObjectForKey:identifier];
            _registeredServices[serviceStr] = dict;
        }
        implValue = _serviceEntities[serviceStr];
        if (implValue && [implValue isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *instanceDict = [NSMutableDictionary dictionaryWithDictionary:implValue];
            [instanceDict removeObjectForKey:identifier];
            _serviceEntities[serviceStr] = instanceDict;
        }
        [_lock unlock];
    }
}


@end
