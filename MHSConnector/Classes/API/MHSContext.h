//
//  MHSContext.h
//  MHSConnector
//
//  Created by 赵柳 on 2025/4/21.
//

#import <Foundation/Foundation.h>
#import "MHSServiceProtocol.h"

#import <UIKit/UIKit.h>

@interface MHSContext : NSObject <NSCopying>

@property (nonatomic, strong) UIApplication *application;

@property (nonatomic, strong) NSDictionary *launchOptions;

@property (nonatomic, strong) UIWindow *mainWindow;

@property (nonatomic, strong) UIViewController *rootViewController;

@property (nonatomic, copy) NSString *protocolSubfix;
/// 应用启动后多久触发环境搭建完成事件
/// 搭建环境时长，单位秒，默认5秒
@property (nonatomic, assign) NSTimeInterval environmentSetupInterval;


@end
