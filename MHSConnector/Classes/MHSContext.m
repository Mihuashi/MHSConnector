//
//  MHSContext.m
//  MHSConnector
//
//  Created by 赵柳 on 2022/4/13.
//

#import "MHSContext.h"

@implementation MHSContext

- (instancetype)init {
    self = [super init];
    if (self) {
        _protocolSubfix = @"Protocol";
        _environmentSetupInterval = 5.0f;
    }
    
    return self;
}

#pragma mark - NSCopying
- (instancetype)copyWithZone:(NSZone *)zone {
    MHSContext *context = [[self.class allocWithZone:zone] init];
    context.application = self.application;
    context.launchOptions = self.launchOptions;
    context.mainWindow = self.mainWindow;
    context.rootViewController = self.rootViewController;
    context.environmentSetupInterval = self.environmentSetupInterval;
    
    return context;
}


@end
