//
//  MHSConnector+Module.h
//  MHSConnector
//
//  Created by 赵柳 on 2025/4/21.
//

#import <Foundation/Foundation.h>
#import "MHSConnector.h"

@protocol MHSModuleProtocol;

@interface MHSConnector (Module)

/** 准备注册的组件
 *  @param moduleClass 组件类
 */
+ (void)addReadyRegisterModule:(Class)moduleClass;

/** 动态注册组件
 *  @param moduleClass 注解类
 *  @param shouldInit 组件注册后是否初始化
 */
+ (void)registerModule:(Class)moduleClass shouldInit:(BOOL)shouldInit;

/** 动态注册组件，不执行初始化
 *  @param moduleClass 注解类
 */
+ (void)registerModule:(Class)moduleClass;

/** 动态注销组件
 *  @param moduleClass 组件类型
 */
+ (void)unregisterDynamicModule:(Class)moduleClass;

/** 注册分发器
 *  @param dispatcher 分发器
 *  @param moduleInstance Module实例
 */
+ (void)registerDispatcher:(Class)dispatcher forModuleInstance:(id<MHSModuleProtocol>)moduleInstance;

/** 触发分发器对应的Module初始化
 *  @param dispatcher 分发器
 */
+ (void)triggerModuleInitIfNeededForDispatcher:(Class)dispatcher;


@end
