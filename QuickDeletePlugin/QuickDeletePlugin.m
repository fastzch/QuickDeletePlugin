//
//  QuickDeletePlugin.m
//  QuickDeletePlugin
//
//  Created by Robin on 3/11/16.
//  Copyright © 2016 Robin Studio. All rights reserved.
//

#import "QuickDeletePlugin.h"

@interface QuickDeletePlugin()

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@property (assign) NSRange currentRange;
@property (assign) NSRange currentLineRange;
@property (nonatomic, retain) NSString *currentSelection;
@property (nonatomic, retain) NSTextView *codeEditor;


@end

@implementation QuickDeletePlugin

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    //removeObserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    // Create menu items, initialize UI, etc.
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Delete Line(s)" action:@selector(deleteLinesAction:) keyEquivalent:@"d"];
        //[actionMenuItem setKeyEquivalentModifierMask:NSAlphaShiftKeyMask | NSControlKeyMask];
        [actionMenuItem setTarget:self];
        [[menuItem submenu] addItem:actionMenuItem];
        
        
        // tap into notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionDidChange:) name:NSTextViewDidChangeSelectionNotification object:nil];
        
        if(!self.codeEditor){
            NSResponder *firstResponder = [[NSApp keyWindow] firstResponder];
            if([firstResponder isKindOfClass:NSClassFromString(@"DVTSourceTextView")] && [firstResponder isKindOfClass:[NSTextView class]]){
                self.codeEditor = (NSTextView *)firstResponder;
            }
        }
        
        if(self.codeEditor){
            NSNotification *notification = [NSNotification notificationWithName:NSTextViewDidChangeSelectionNotification object:self.codeEditor];
            [self selectionDidChange:notification];
        }
        
    }
}

-(void)selectionDidChange:(NSNotification *)notification
{
    if([[notification object] isKindOfClass:NSClassFromString(@"DVTSourceTextView")] && [[notification object] isKindOfClass:[NSTextView class]]){
        self.codeEditor = (NSTextView *)[notification object];
        NSArray *selectedRanges = [_codeEditor selectedRanges];
        if(selectedRanges.count >= 1){
            NSString *code = _codeEditor.textStorage.string;
            self.currentRange     = [[selectedRanges objectAtIndex:0] rangeValue];
            self.currentLineRange = [code lineRangeForRange:_currentRange];
            self.currentSelection = [code substringWithRange:_currentRange];
        }
    }
}

-(BOOL)currentCharIsReturnChar
{
    if(_codeEditor){
        NSString *code = _codeEditor.textStorage.string;
        NSInteger s = _currentRange.location;
        
        char c = [code characterAtIndex:s];
        if (c == '\n') {
            return YES;
        }else{
            NO;
        }
    }
    return NO;
}

-(BOOL)isReturnCharForLocation:(NSInteger)location
{
    if(_codeEditor){
        NSInteger s = location;
        if(s>=1){
            NSString *code = _codeEditor.textStorage.string;
            char c = [code characterAtIndex:s];
            if (c == '\n') {
                return YES;
            }else{
                NO;
            }
        }else{
            return YES;
        }
    }
    return NO;
}

-(BOOL)backCharIsReturnChar
{
    if(_codeEditor){
        NSInteger s = _currentRange.location;
        if(s>=1){
            NSString *code = _codeEditor.textStorage.string;
            char c = [code characterAtIndex:s-1];
            if (c == '\n') {
                return YES;
            }else{
                NO;
            }
        }else{
            return YES;
        }
    }
    return NO;
}

-(NSInteger)findPreviousReturnChar
{
    if(_codeEditor){
        NSString *code = _codeEditor.textStorage.string;
        NSInteger s = _currentRange.location;
        while(s>1){
            char c = [code characterAtIndex:s-1];
            if (c == '\n') {
                return s;
            }else{
                s--;
            }
        }
    }
    return 0;
}

-(NSInteger)findNextReturnChar
{
    if(_codeEditor){
        NSString *code = _codeEditor.textStorage.string;
        NSInteger s = _currentRange.location;
        while(s<code.length-1){
            char c = [code characterAtIndex:s+1];
            if (c == '\n') {
                return s+1;
            }else{
                s++;
            }
        }
        
    }
    return -1;
}

-(NSInteger)findNextReturnCharFromLocation: (NSInteger) location
{
    if(_codeEditor){
        NSString *code = _codeEditor.textStorage.string;
        NSInteger s = location;
        while(s<code.length-1){
            char c = [code characterAtIndex:s+1];
            if (c == '\n') {
                return s+1;
            }else{
                s++;
            }
        }
        
    }
    return -1;
}

- (void)deleteLinesAction:(id)sender {
    if(_codeEditor){
        NSRange deleteRange = NSMakeRange(0, 0);
        if (_currentRange.length>0) {
            //has selected something.
            
            if([self isReturnCharForLocation:_currentRange.location+_currentRange.length-1]){
                NSInteger s = [self findPreviousReturnChar];
                NSInteger e = _currentRange.location+_currentRange.length;
                deleteRange = NSMakeRange(s, e-s);
            }else{
                NSInteger s = [self findPreviousReturnChar ];
                NSInteger e = [self findNextReturnCharFromLocation:_currentRange.location+_currentRange.length-1];
                deleteRange = NSMakeRange(s, e-s+1);
            }
        }else{
            if([self currentCharIsReturnChar]){
                //current position is a \n
                if([self backCharIsReturnChar]){
                    //current position is line of start, and none char in this line.
                    deleteRange = NSMakeRange(_currentRange.location, 1);
                    NSLog(@"current position is line of start, range:%@", NSStringFromRange(deleteRange));
                }else{
                    //current position is line of end.
                    //then, delete
                    NSInteger s = [self findPreviousReturnChar ];
                    deleteRange = NSMakeRange(s, _currentRange.location - s + 1);
                    NSLog(@"current position is line of end, range:%@", NSStringFromRange(deleteRange));
                }
            }else{
                if([self backCharIsReturnChar]){
                    //current position is line of start.
                    NSInteger next = [self findNextReturnChar ];
                    NSLog(@"2 current position: %zi, next position:%zi", _currentRange.location, next);
                    deleteRange = NSMakeRange(_currentRange.location, next - _currentRange.location +1 );
                    NSLog(@"2 current position is line of start, range:%@", NSStringFromRange(deleteRange));
                }else{
                    //current posion is not line of start or end.
                    NSInteger s = [self findPreviousReturnChar ];
                    NSInteger e = [self findNextReturnChar ];
                    deleteRange = NSMakeRange(s, e-s+1);
                }
            }
        }
        
        //        NSLog(@"will be deleted range: %@", NSStringFromRange(deleteRange));
        @try {
            [_codeEditor insertText:@"" replacementRange:deleteRange];
        }
        @catch (NSException *exception) {
            [_codeEditor insertText:@"" replacementRange:deleteRange];
        }
    }
}

- (void)showMessageBox:(NSString *)text {
    NSAlert *alert = [[NSAlert alloc] init];
    
    [alert setMessageText:text];
    [alert runModal];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
