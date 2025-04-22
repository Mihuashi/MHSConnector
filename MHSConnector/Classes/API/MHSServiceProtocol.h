//
//  MHSServiceProtocol.h
//  MHSConnector
//
//  Created by 赵柳 on 2025/4/21.
//

#import <Foundation/Foundation.h>

/// 组件协议基协议，主要负责这个提供的服务是否单例的
@protocol MHSServiceProtocol <NSObject>

@optional
/// 是否是单例
+ (BOOL)singleton;

+ (id)sharedInstance;


@end
