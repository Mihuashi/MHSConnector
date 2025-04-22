//
//  MHSConnectorItem.h
//  MHSConnector
//
//  Created by 赵柳 on 2025/4/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHSConnectorItem : NSObject

/// alias
@property (nonatomic, copy, nonnull) NSString *alias;
/// selector
@property (nonatomic, assign, nonnull) SEL selector;
/// params
@property (nonatomic, strong, nullable) NSDictionary *params;

#pragma mark - public method
+ (MHSConnectorItem *)createWithAlias:(NSString * _Nonnull)alias selector:(SEL _Nonnull)selector params:(NSDictionary * _Nullable)params;


@end

NS_ASSUME_NONNULL_END
