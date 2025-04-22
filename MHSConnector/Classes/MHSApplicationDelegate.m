//
//  MHSApplicationDelegate.m
//  MHSConnector
//
//  Created by 赵柳 on 2025/4/21.
//

#import "MHSApplicationDelegate.h"
#import "MHSContext.h"
#import "MHSModuleCenter.h"

@import ObjectiveC.runtime;
@import ObjectiveC.message;

@implementation MHSApplicationDelegate

- (Protocol *)targetApplicationProtocol {
    return @protocol(UIApplicationDelegate);
}

- (Protocol *)targetUserNotificationProtocol {
    return @protocol(UNUserNotificationCenterDelegate);
}

- (Protocol *)targetWindowSceneProtocol {
    return @protocol(UIWindowSceneDelegate);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    struct objc_method_description methodDescription = protocol_getMethodDescription([self targetApplicationProtocol], aSelector, NO, YES);
    if (methodDescription.name != NULL && methodDescription.types != NULL) {
        return [NSMethodSignature signatureWithObjCTypes:methodDescription.types];
    }
    methodDescription = protocol_getMethodDescription([self targetUserNotificationProtocol], aSelector, NO, YES);
    if (methodDescription.name != NULL && methodDescription.types != NULL) {
        return [NSMethodSignature signatureWithObjCTypes:methodDescription.types];
    }
    methodDescription = protocol_getMethodDescription([self targetWindowSceneProtocol], aSelector, NO, YES);
    if (methodDescription.name != NULL && methodDescription.types != NULL) {
        return [NSMethodSignature signatureWithObjCTypes:methodDescription.types];
    }
    return [[self class] instanceMethodSignatureForSelector:@selector(doNothing)];
}

- (void)doNothing {
    
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL oriSelector = anInvocation.selector;
    
    unsigned long returnValueUnsignedLong = 0;
    BOOL returnValueBool = NO;
    id returnValueId = nil;
    const char *returnType = anInvocation.methodSignature.methodReturnType;

    NSMutableArray *allModules = [NSMutableArray array];
    [anInvocation setSelector:oriSelector];
    [allModules addObjectsFromArray:[MHSModuleCenter shared].moduleInstances];
    BOOL hasExecuted = NO;
    for (id module in allModules) {
        if ([module respondsToSelector:oriSelector]) {
            [anInvocation invokeWithTarget:module];
            if (!hasExecuted) {
                if (strcmp(returnType, @encode(unsigned long)) == 0) {
                    [anInvocation getReturnValue:&returnValueUnsignedLong];
                    hasExecuted = YES;
                } else if (strcmp(returnType, @encode(BOOL)) == 0) {
                    [anInvocation getReturnValue:&returnValueBool];
                    hasExecuted = YES;
                } else if (strcmp(returnType, @encode(id)) == 0) {
                    [anInvocation getReturnValue:&returnValueId];
                    hasExecuted = YES;
                }
            }
        }
    }
    
    // 使用优先级最高组件的返回值
    if (strcmp(returnType, @encode(unsigned long)) == 0) {
        [anInvocation setReturnValue:&returnValueUnsignedLong];
    } else if (strcmp(returnType, @encode(BOOL)) == 0) {
        [anInvocation setReturnValue:&returnValueBool];
    } else if (strcmp(returnType, @encode(id)) == 0) {
        [anInvocation setReturnValue:&returnValueId];
    }
}

@end
