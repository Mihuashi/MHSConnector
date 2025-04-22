//
//  MHSConnectorItem.m
//  MHSConnector
//
//  Created by 赵柳 on 2022/6/2.
//

#import "MHSConnectorItem.h"

@implementation MHSConnectorItem

#pragma mark - public method
+ (MHSConnectorItem *)createWithAlias:(NSString * _Nonnull)alias selector:(SEL _Nonnull)selector params:(NSDictionary * _Nullable)params {
    MHSConnectorItem *item = [[MHSConnectorItem alloc] init];
    item.selector = selector;
    item.alias = alias;
    item.params = params;
    
    return item;
}


@end
