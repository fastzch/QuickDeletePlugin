//
//  QuickDeletePlugin.h
//  QuickDeletePlugin
//
//  Created by Robin on 3/11/16.
//  Copyright © 2016 Robin Studio. All rights reserved.
//

#import <AppKit/AppKit.h>

@class QuickDeletePlugin;

static QuickDeletePlugin *sharedPlugin;

@interface QuickDeletePlugin : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end