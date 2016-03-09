#import "AppDelegate.h"
#import "AppPrefsWindowController.h"
#import "CanvasWindowController.h"
#import "RulesList.h"
#import "utils.h"
#import "NSBundle+LoginItem.h"
#import "BlackWhiteFilter.h"
#import "math.h"

@implementation AppDelegate


static CanvasWindowController *windowController;
static CGEventRef mouseDownEvent, mouseDraggedEvent;
static NSMutableArray *directions;
static NSMutableDictionary *mark;
static NSPoint lastLocation;
static CFMachPortRef mouseEventTap;
static bool isEnable;
static AppPrefsWindowController *_preferencesWindowController;

+ (AppDelegate *)appDelegate
{
    return (AppDelegate *)[[NSApplication sharedApplication] delegate];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {

    windowController = [[CanvasWindowController alloc] init];

    CGEventMask eventMask = CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventRightMouseDragged) | CGEventMaskBit(kCGEventRightMouseUp);
    mouseEventTap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, mouseEventCallback, NULL);
    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, mouseEventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CFRelease(mouseEventTap);
    CFRelease(runLoopSource);

    directions = [[NSMutableArray alloc] init];
    mark = [[NSMutableDictionary alloc] init];
    isEnable = true;

    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRunBefore"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"openPrefOnStartup"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showGesturePreview"];

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRunBefore"];
    }

    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRun_2.0.4_Before"]){
        [[NSBundle mainBundle] addToLoginItems];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRun_2.0.4_Before"];
    }

    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRun_2.0.5_Before"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showGestureNote"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRun_2.0.5_Before"];
    }

    [BWFilter compatibleProcedureWithPreviousVersionBlockRules];


    if([[NSUserDefaults standardUserDefaults] boolForKey:@"openPrefOnStartup"]){
        [self openPreferences:self];
    }
}

- (BOOL)toggleEnable {
    windowController.enable = isEnable = !isEnable;

    CGEventTapEnable(mouseEventTap, isEnable);
    return isEnable;
}

- (void)awakeFromNib {
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    NSImage *menuIcon = [NSImage imageNamed:@"Menu Icon"];
    //NSImage *highlightIcon = [NSImage imageNamed:@"Menu Icon"]; // Yes, we're using the exact same image asset.
    //[highlightIcon setTemplate:YES]; // Allows the correct highlighting of the icon when the menu is clicked.
    [menuIcon setTemplate:YES];
    [[self statusItem] setImage:menuIcon];
//    [[self statusItem] setAlternateImage:highlightIcon];
    [[self statusItem] setMenu:[self menu]];
    [[self statusItem] setHighlightMode:YES];


}

- (IBAction)openPreferences:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [_preferencesWindowController close];
    //instantiate preferences window controller
    if (_preferencesWindowController) {
        _preferencesWindowController = nil;
    }
    //init from nib but the real initialization happens in the
    //PreferencesWindowController setupToolbar method
    _preferencesWindowController = [[AppPrefsWindowController alloc] initWithWindowNibName:@"Preferences"];

    [_preferencesWindowController showWindow:self];
}

static bool appendDirection(NSString* direction, NSPoint location) {
    unichar lastDirectionChar;
    if(mark.count > 0) {
        NSString *key = [NSString stringWithFormat:@"%@,%ld",direction, mark.count-1];
        NSMutableDictionary *directionData = [mark objectForKey:key];
        if(directionData != nil){
            lastDirectionChar = [[directionData objectForKey:@"direction"] characterAtIndex:0];
        }else{
            lastDirectionChar = ' ';
        }
        // lastDirectionChar = [directions characterAtIndex:directions.length - 1];
        NSLog(@"---------------lastDirectionChar >> %c", lastDirectionChar);
    }else{
        lastDirectionChar = ' ';
    }
    NSLog(@" ====================================== ");
    NSLog(@"最后一个方向 lastDirectionChar >> %c", lastDirectionChar);
    NSLog(@"正发生的方向 direction >> %c", [direction characterAtIndex:0]);
    if (lastDirectionChar != [direction characterAtIndex:0]) {
        // 如果方向发生改变
        // 1. 添加上一个点到新点的路线
        NSMutableArray *path = [[NSMutableArray alloc]init];
        [path addObject: [NSValue valueWithPoint: lastLocation]];
        [path addObject: [NSValue valueWithPoint: location]];
        // 2. 添加一个新的方向
        NSMutableDictionary *directionData = [[NSMutableDictionary alloc] init];
        NSString *key = [NSString stringWithFormat:@"%@,%ld",direction, mark.count];
        [directionData setObject:direction forKey:@"direction"];
        [directionData setObject:path forKey:@"path"];
        NSLog(@"添加一个新的方向 %@ > key=%@", direction, key);
        // 3. 记录最后的点坐标
        lastLocation = location;
        // 4. 判断是否是产生了新的有效方向
        double deltaX = fabs(location.x - lastLocation.x);
        double deltaY = fabs(location.y - lastLocation.y);
        if((deltaY + deltaX) / 2 > 50){
            [directionData setValue:[NSNumber numberWithBool:YES] forKey:@"append"];
            [directions addObject:direction];
            [windowController writeDirection:directions];
        }else{
            NSLog(@"~~~~~~~ 线还太短了, 才%f。", (deltaY + deltaX) / 2);
        }
        [mark setObject:directionData forKey:key];
        
        return true;
    }else{
        // 如果方向与上次的一样， 修改该方向最后一个坐标
        // 1. 取出最后的方向数据
        NSString *key = [NSString stringWithFormat:@"%@,%ld",direction, mark.count-1];
        NSMutableDictionary *directionData = [mark objectForKey:key];
        NSMutableArray *path = [directionData objectForKey:@"path"];
        bool append = [[directionData objectForKey:@"append"]boolValue];
        // 判断是否符合长度了， 如果符合则可不需要任何操作等待下一个方向
        if (!append) {
            // 2. 更新线（由于不需要用到， 忽略）
            // 3. 判断线是否符合长度了
            NSPoint first = [[path firstObject] pointValue];
            double deltaX = fabs(location.x - first.x);
            double deltaY = fabs(location.y - first.y);
            if((deltaY + deltaX) / 2 > 50){
                [directionData setValue:[NSNumber numberWithBool:YES] forKey:@"append"];
                [directions addObject:direction];
                [windowController writeDirection:directions];
            }else{
                NSLog(@"2>>> ~~~~~~~ 线还太短了, 才%f。", (deltaY + deltaX) / 2);
            }
            [mark setObject:directionData forKey:key];
        }
    }
    NSLog(@" ====================================== ");
//    [windowController writeDirection:directions];
    return true;
}

static void updateDirections(NSEvent* event) {
    // not thread safe
    NSPoint newLocation = event.locationInWindow;
    
    double deltaX = newLocation.x - lastLocation.x;
    double deltaY = newLocation.y - lastLocation.y;
//    double absX = fabs(deltaX);
//    double absY = fabs(deltaY);
//    if (absX + absY < 20) {
//        return; // ignore short distance
//    }
//    [windowController writePoint: &newLocation];
//    NSLog(@"deltaX = %f , deltaY = %f)", deltaX, deltaY);
//    NSLog(@"newLocation  (%f , %f)", newLocation.x, newLocation.y);
//    NSLog(@"lastLocation (%f , %f)", lastLocation.x, lastLocation.y);
//    lastLocation = event.locationInWindow;
    // direction enum:
    //  7   8   9
    //  4       6
    //  1   2   3
    int angle = (int)180/M_PI*atan2(deltaY,deltaX);
    int space = 15;
    bool isAppend = false;
    if(angle > 0){
        if(angle > 90 - space && angle < 90 + space){
            NSLog(@" 向上 > %f", 180/M_PI*atan2(deltaY,deltaX));
            isAppend = appendDirection(@"8", event.locationInWindow);
        }else if(angle < space){
            NSLog(@" 向右 > %f", 180/M_PI*atan2(deltaY,deltaX));
            isAppend = appendDirection(@"6", event.locationInWindow);
        }else if(angle >= space && angle < 90 - space){
            NSLog(@" 右上斜 > %f", 180/M_PI*atan2(deltaY,deltaX));
            isAppend = appendDirection(@"9", event.locationInWindow);
        }else if(angle > 180 - space){
            NSLog(@" 向左 > %f", 180/M_PI*atan2(deltaY,deltaX));
            isAppend = appendDirection(@"4", event.locationInWindow);
        }else if(angle >= 90 + space && angle <= 180 - space){
            NSLog(@" 左上斜 > %f", 180/M_PI*atan2(deltaY,deltaX));
            isAppend = appendDirection(@"7", event.locationInWindow);
        }
    } else if(angle < 0){
        angle = abs(angle);
        if(angle > 90 - space && angle < 90 + space){
            NSLog(@" 向下 > %f", 180/M_PI*atan2(deltaY,deltaX));
            isAppend = appendDirection(@"2", event.locationInWindow);
        }else if(angle < space){
            NSLog(@" 向右 > %f", 180/M_PI*atan2(deltaY,deltaX));
            isAppend = appendDirection(@"6", event.locationInWindow);
        }else if(angle >= space && angle < 90 - space){
            NSLog(@" 右下斜 > %f", 180/M_PI*atan2(deltaY,deltaX));
            isAppend = appendDirection(@"3", event.locationInWindow);
        }else if(angle > 180 - space){
            NSLog(@" 向左 > %f", 180/M_PI*atan2(deltaY,deltaX));
            isAppend = appendDirection(@"4", event.locationInWindow);
        }else if(angle >= 90 + space && angle <= 180 - space){
            NSLog(@" 左下斜 > %f", 180/M_PI*atan2(deltaY,deltaX));
            isAppend = appendDirection(@"1", event.locationInWindow);
        }
    }
}

static bool handleGesture() {
    return [[RulesList sharedRulesList] handleGesture:directions];
}

void resetDirection(){
    [mark removeAllObjects];
    [directions removeAllObjects];
}

static CGEventRef mouseEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    // not thread safe, but it's always called in main thread
    // check blocker apps
//    if(wildLike(frontBundleName(), [[NSUserDefaults standardUserDefaults] stringForKey:@"blockFilter"])){
    if(![BWFilter willHookRightClickForApp:frontBundleName()]){
//        CGEventPost(kCGSessionEventTap, mouseDownEvent);
//        if (mouseDraggedEvent) {
//            CGEventPost(kCGSessionEventTap, mouseDraggedEvent);
//        }
        CGEventPost(kCGSessionEventTap, event);
        return NULL;
    }

    NSEvent *mouseEvent;
    switch (type) {
        case kCGEventRightMouseDown:
            if (mouseDownEvent) { // mouseDownEvent may not release when kCGEventTapDisabledByTimeout
                resetDirection();
                CGPoint location = CGEventGetLocation(mouseDownEvent);
                CGEventPost(kCGSessionEventTap, mouseDownEvent);
                CFRelease(mouseDownEvent);
                if (mouseDraggedEvent) {
                    location = CGEventGetLocation(mouseDraggedEvent);
                    CGEventPost(kCGSessionEventTap, mouseDraggedEvent);
                    CFRelease(mouseDraggedEvent);
                }
                CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, location, kCGMouseButtonRight);
                CGEventPost(kCGSessionEventTap, event);
                CFRelease(event);
                mouseDownEvent = mouseDraggedEvent = NULL;
            }

            mouseEvent = [NSEvent eventWithCGEvent:event];
            [windowController reinitWindow];
            [windowController handleMouseEvent:mouseEvent];
            mouseDownEvent = event;
            CFRetain(mouseDownEvent);
            lastLocation = mouseEvent.locationInWindow;
            // lzw
            // [windowController writePoint: &lastLocation];
            break;
        case kCGEventRightMouseDragged:
            if (mouseDownEvent) {
                mouseEvent = [NSEvent eventWithCGEvent:event];
                [windowController handleMouseEvent:mouseEvent];
                if (mouseDraggedEvent) {
                    CFRelease(mouseDraggedEvent);
                }
                mouseDraggedEvent = event;
                CFRetain(mouseDraggedEvent);
                updateDirections(mouseEvent);
            }
            break;
        case kCGEventRightMouseUp: {
            if (mouseDownEvent) {
                mouseEvent = [NSEvent eventWithCGEvent:event];
                [windowController handleMouseEvent:mouseEvent];
                updateDirections(mouseEvent);
                if (!handleGesture()) {

                    CGEventPost(kCGSessionEventTap, mouseDownEvent);
                    if (mouseDraggedEvent) {
                        CGEventPost(kCGSessionEventTap, mouseDraggedEvent);
                    }
                    CGEventPost(kCGSessionEventTap, event);
                }
                CFRelease(mouseDownEvent);
            }
            if (mouseDraggedEvent) {
                CFRelease(mouseDraggedEvent);
            }
            mouseDownEvent = mouseDraggedEvent = NULL;
            lastLocation = NSMakePoint(0, 0);
            resetDirection();
            break;
        }
        case kCGEventTapDisabledByTimeout:
            CGEventTapEnable(mouseEventTap, isEnable); // re-enable
            windowController.enable = isEnable;
            break;
        default:
            return event;
    }

    return NULL;
}

@end