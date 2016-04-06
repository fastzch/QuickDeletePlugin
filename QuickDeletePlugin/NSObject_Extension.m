//
//  NSObject_Extension.m
//  QuickDeletePlugin
//
//  Created by Robin on 3/11/16.
//  Copyright © 2016 Robin Studio. All rights reserved.
//


#import "NSObject_Extension.h"
#import "QuickDeletePlugin.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[QuickDeletePlugin alloc] initWithBundle:plugin];
        });
    }
}
@end
