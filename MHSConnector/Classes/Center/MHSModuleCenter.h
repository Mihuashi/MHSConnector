//
//  MHSModuleCenter.h
//  MHSConnector
//
//  Created by 赵柳 on 2025/4/21.
//

#import <Foundation/Foundation.h>
#import "MHSModuleProtocol.h"

@interface MHSModuleCenter : NSObject

/// 组件对象信息
@property (nonatomic, strong) NSMutableArray<id<MHSModuleProtocol>> *moduleInstances;

#pragma mark - public method
+ (instancetype)shared;

/** 准备注册的组件
 *  @param moduleClass 组件类
 */
- (void)addReadyRegisterModule:(Class)moduleClass;

/// 注册所有组件
- (void)registerAllModules;

/** 动态注册组件
 *  @param moduleClass 组件类
 */
- (void)registerModule:(Class)moduleClass;

/** 动态注册组件
 *  @param moduleClass 注解类
 *  @param shouldInit 组件注册后是否初始化
 */
- (void)registerModule:(Class)moduleClass shouldInit:(BOOL)shouldInit;

/** 给指定的组件注册自定义事件，触发此事件后只要注册的组件才会接收
 *  @param key 事件
 *  @param moduleInstance 组件对象
 */
- (void)registerCustomEvent:(NSString *)key moduleInstance:(id)moduleInstance;

/** 注销指定组件的自定义事件
 *  @param key 事件
 *  @param moduleInstance 组件对象
 */
- (void)unregisterCustomEvent:(NSString *)key moduleInstance:(id)moduleInstance;

/** 注销指定组件的所有自定义事件
 *  @param moduleInstance 组件对象
 */
- (void)unregisterCustomEvent:(id)moduleInstance;

/** 动态注销组件
 *  @param moduleClass 组件类型
 */
- (void)unregisterDynamicModule:(Class)moduleClass;

/// 触发首页加载完成
- (void)triggerAppEnvironmentDidSetup;

/** 触发自定义事件
 *  @param key 自定义的关键字
 *  @param customParam 参数
 */
- (void)triggerCustomEvent:(NSString *)key customParam:(id)customParam;

/** 注册分发器
 * @param dispatcher 分发器
 * @param moduleInstance Module实例
 */
- (void)registerDispatcher:(Class)dispatcher forModuleInstance:(id<MHSModuleProtocol>)moduleInstance;

/** 触发分发器对应的Module初始化
 * @param dispatcher 分发器
 */
- (void)triggerModuleInitIfNeededForDispatcher:(Class)dispatcher;

/** 触发系统事件
 * @param block block
 */
- (void)triggerSystemEvent:(void(^)(id<MHSModuleProtocol> module))block;

/// 根据moduleClass 获取moduleInstance
- (id)getInstanceWithModuleClass:(Class)moduleClass;


@end
