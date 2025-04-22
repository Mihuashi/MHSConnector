//
//  MHSConnector.h
//  MHSConnector
//
//  Created by 赵柳 on 2025/4/21.
//

#import <Foundation/Foundation.h>
#import "MHSContext.h"
#import "MHSConnectorItem.h"
#import "MHSModuleProtocol.h"
#import "MHSServiceProtocol.h"
#import "MHSApplicationDelegate.h"

#define MHSConnectorContext ([MHSConnector shared].context)
#define MHSConnectorAppDelegate ([MHSConnector shared].applicationDelegate)
#define MHSConnectorCreateService(p) ([MHSConnector createService:@protocol(p)])

#define AliasService(Protocol, Selector) \
@protocol Protocol; \
@protocol MHSConnector_##Protocol \
+ (Class<Protocol>)Selector; \
@end \
@interface MHSConnector(Protocol)<MHSConnector_##Protocol> \
@end

/// MHSConnector框架主类，包含环境变量，注册，获取和触发组件，服务和事件等功能
@interface MHSConnector : NSObject

/// app参数存放对象
@property (nonatomic, strong) MHSContext *context;

/// app事件接收
@property (nonatomic, strong) MHSApplicationDelegate *applicationDelegate;
/// 开启异常崩溃，建议debug下开启
@property (nonatomic, assign) BOOL enableException;

#pragma mark - public method
+ (instancetype)shared;

/** 给指定的组件注册自定义事件，触发此事件后只要注册的组件才会接收
 *  @param key 事件
 *  @param moduleInstance 组件对象
 */
+ (void)registerCustomEvent:(NSString *)key moduleInstance:(id)moduleInstance;

/** 注销指定组件的自定义事件
 *  @param key 事件
 *  @param moduleInstance 组件对象
 */
+ (void)unregisterCustomEvent:(NSString *)key moduleInstance:(id)moduleInstance;

/** 注销指定组件的所有自定义事件
 *  @param moduleInstance 组件对象
 */
+ (void)unregisterCustomEvent:(id)moduleInstance;

/** 触发自定义事件
 *  @param key 事件
 */
+ (void)triggerCustomEvent:(NSString *)key;

/** 触发自定义事件
 *  @param key 事件
 *  @param customParam 参数
 */
+ (void)triggerCustomEvent:(NSString *)key customParam:(id)customParam;

/// App环境加载完成调用，如：首页加载完成
+ (void)applicationEnvironmentDidSetup;

/// Window加载完成调用
+ (void)applicationMakeKeyWindowAndVisible;

/// 同步（返回值为id类型）
+ (id)mhsPerformSelector:(MHSConnectorItem *)item;
/** 异步（返回值为id类型）
 *  user 获取block
 *  void (^asynCompletion)(id result) = params[@"asynCompletion"];
 */
+ (id)mhsPerformSelector:(MHSConnectorItem *)item asynCompletion:(void (^)(id result))asynCompletion;

@end


#import "MHSConnectorItem.h"
#import "MHSConnector+Module.h"
#import "MHSConnector+Service.h"

/// 注册Service
#define registerService(Protocol, Implementation) \
do { \
    [MHSConnector registerService:@protocol(Protocol) implClass:[Implementation class]]; \
    [MHSConnector registerDispatcher:[Implementation class] forModuleInstance:self]; \
} while(0)

/// 注册Service和别名
#define registerServiceWithAlias(Protocol, Implementation, Alias) \
do {  \
    [MHSConnector registerService:@protocol(Protocol) implClass:[Implementation class]];\
    [MHSConnector registerAlias:@selector(Alias) forService:@protocol(Protocol)]; \
    [MHSConnector registerDispatcher:[Implementation class] forModuleInstance:self]; \
} while(0)

/// 注册外部Service
#define registerServiceWithIdentifier(Protocol, Implementation, identifier) \
do {  \
    [MHSConnector registerExternService:@protocol(Protocol) implClass:[Implementation class] identifier:identifier];\
} while(0)

/// 定义组件
#define ModuleDefine(Module) \
__attribute__((constructor)) \
static void registerModuleFor##Module(void) { \
    [MHSConnector addReadyRegisterModule:[Module class]]; \
}

/// 定义Service
#define ServiceDefine(Protocol, Implementation) \
__attribute__((constructor)) \
static void registerModuleFor##MODULE(void) { \
    [MHSConnector registerService:@protocol(Protocol) implClass:[Implementation class]]; \
}

/// 定义Service别名
#define ServiceDefineWithAlias(Protocol, Implementation, Alias) \
__attribute__((constructor)) \
static void registerModuleFor##MODULE(void) { \
    [MHSConnector registerService:@protocol(Protocol) implClass:[Implementation class]]; \
    [MHSConnector registerAlias:@selector(Alias) forService:@protocol(Protocol)];\
}

/** 函数说明
 *  __attribute__((constructor))        保证在main函数调用前，先调用了这个方法
 *  __attribute__((destructor))         保证在main函数调用后，采用这个方法
 */
