//
//  MHSServiceCenter.h
//  MHSConnector
//
//  Created by 赵柳 on 2025/4/21.
//

#import <Foundation/Foundation.h>

@class MHSContext;

@interface MHSServiceCenter : NSObject

/// 抛出异常
@property (nonatomic, assign) BOOL enableException;

#pragma mark - public method
+ (instancetype)shared;

/** 动态注册服务
 *  @param protocol Protocol
 *  @param implClass 实现类
 */
- (void)registerService:(Protocol *)protocol implClass:(Class)implClass;

/** 注册调用某个协议的别名
 *  @param selector 别名
 *  @param protocol 协议
 */
- (void)registerAlias:(SEL)selector forService:(Protocol *)protocol;

/** 注册其他组件定义的协议，本组件来实现的服务
 *  @param externProtocol 其他组件定义的协议
 *  @param implClass 本组件的实现类
 *  @param identifier 本组件标识
 */
- (void)registerExternService:(Protocol *)externProtocol implClass:(Class)implClass identifier:(NSString *)identifier;

/** 注销服务
 *  @param protocol 服务
 */
- (void)unregisterService:(Protocol *)protocol;

/** 注销服务
 *  @param externProtocol 服务
 *  @param identifier 组件标识
 */
- (void)unregisterExternService:(Protocol *)externProtocol identifier:(NSString *)identifier;

/** 创建服务对象
 *  @param protocol 协议
 *  @return 实现协议的注册类对象
 */
- (id)createService:(Protocol *)protocol;

/** 创建其他组件创建的本组件协议的服务对象
 *  @param protocol 协议
 *  @param externIdentifier 组件标识
 *  @return 实现协议的注册类对象
 */
- (id)createService:(Protocol *)protocol externIdentifier:(NSString *)externIdentifier;

/** 创建类服务
 *  @param protocol 协议
 *  @return 实现协议的注册类
 */
- (Class)createClassService:(Protocol *)protocol;

/** 通过别名Selector创建类服务
 *  @param selector 别名Selector
 *  @return 对应的注册类
 */
- (Class)createClassServiceWithAlias:(SEL)selector;

/** 创建类服务
 *  @param protocol 协议
 *  @param externIdentifier 组件标识
 *  @return 实现协议的类
 */
- (Class)createClassService:(Protocol *)protocol externIdentifier:(NSString *)externIdentifier;

/** 创建协议的所有类服务
 *  @param protocol 协议
 *  @return 服务类数组
 */
- (NSArray<Class> *)createClassServicesForRegisterProtocol:(Protocol *)protocol;

/** 创建协议的所有服务
 *  @param protocol 协议
 *  @return 服务数组
 */
- (NSArray *)createServicesForRegisterProtocol:(Protocol *)protocol;


@end
