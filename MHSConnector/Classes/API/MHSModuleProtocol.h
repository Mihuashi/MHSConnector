//
//  MHSModuleProtocol.h
//  MHSConnector
//
//  Created by 赵柳 on 2025/4/21.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

@class MHSContext;

/// 组件优先级，层级越低应该优先级越高，需要根据逻辑来指定优先级
typedef NS_ENUM(NSInteger, JDCModulePriority) {
    JDCModulePriorityDefault = 0,
    JDCModulePriorityLow = 100,
    JDCModulePriorityModdle = 500,
    JDCModulePriorityHigh = 1000
};

NS_ASSUME_NONNULL_BEGIN

/// 组件基础协议，获取优先级，系统事件，生命周期和自定义事件
@protocol MHSModuleProtocol <UIApplicationDelegate, UNUserNotificationCenterDelegate>

@optional

/** 组件加载的优先级，值越大优先级越高，不实现该方法为最低优先级，对应层级上，层级越低应该优先级越高
 *  @return 优先级
 */
+ (NSInteger)modulePriority;

/** 触发注册组件，MHSConnector初始化时调用，尽量不要有耗时操作
 *  @param context App上下文
 */
- (void)moduleRegister:(MHSContext *)context;

/** 触发初始化组件，App环境搭建（App启动必要数据）完成事件后或者手动调用，可以有耗时操作
 *  @param context App上下文
 */
- (void)moduleInit:(MHSContext *)context;

/** 触发销毁组件
 *  @param context App上下文
 */
- (void)moduleTearDown:(MHSContext *)context;

/** 触发自定义事件
 *  @param key 关键字
 *  @param customParam App上下文
 */
- (void)moduleDidCustomEvent:(NSString *)key customParam:(id)customParam;

/** 环境搭建（App启动必要数据）完成事件
 *  @param context App上下文
 */
- (void)applicationEnvironmentDidSetup:(MHSContext *)context;

/// KeyWindow显示完成
- (void)applicationMakeKeyWindowAndVisible;


@end

NS_ASSUME_NONNULL_END
