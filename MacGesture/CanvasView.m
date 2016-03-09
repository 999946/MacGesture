//
//  CanvasView.m
//  MouseGesture
//
//  Created by keakon on 11-11-14.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import "CanvasView.h"
#import "RulesList.h"
#import "MGOptionsDefine.h"

@implementation CanvasView

static NSImage* leftImage;
static NSImage* rightImage;
static NSImage* upImage;
static NSImage* downImage;
static NSImage* leftUpImage;
static NSImage* rightUpImage;
static NSImage* leftDownImage;
static NSImage* rightDownImage;

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];

    leftImage = [NSImage imageNamed:@"left.png"];
    rightImage = [NSImage imageNamed:@"right.png"];
    downImage = [NSImage imageNamed:@"down.png"];
    upImage = [NSImage imageNamed:@"up.png"];
    leftUpImage = [NSImage imageNamed:@"left-up.png"];
    rightUpImage = [NSImage imageNamed:@"right-up.png"];
    leftDownImage = [NSImage imageNamed:@"left-down.png"];
    rightDownImage = [NSImage imageNamed:@"right-down.png"];
    
    if (self) {
		color = [MGOptionsDefine getLineColor];
        points = [[NSMutableArray alloc] init];
        debugPoints = [[NSMutableArray alloc] init];
        _directions = [[NSMutableArray alloc] init];
		radius = 2;
	}

	return self;
}

- (void)drawDirection{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showGesturePreview"]){
        return;
    }
    NSLog(@"画到窗口上 %@", _directions);
    NSLog(@"_directions =  %@", _directions);
    // This should be called in drawRect
    CGRect screenRect = [[NSScreen mainScreen] frame];
    NSInteger y = (screenRect.size.height - leftImage.size.height) / 2;
    NSInteger beginx = (screenRect.size.width - leftImage.size.width * _directions.count) / 2;
    for(NSInteger i = 0;i < _directions.count;i++){
        NSImage *image = nil;
        switch([_directions[i] characterAtIndex:0]){
            case '4':
                image = leftImage;
                break;
            case '6':
                image = rightImage;
                break;
            case '8':
                image = upImage;
                break;
            case '2':
                image = downImage;
                break;
            case '7':
                image = leftUpImage;
                break;
            case '9':
                image = rightUpImage;
                break;
            case '1':
                image = leftDownImage;
                break;
            case '3':
                image = rightDownImage;
                break;
            default:
                break;
        }

        [image drawAtPoint:NSMakePoint(beginx+i*leftImage.size.width,y) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }

}
- (void)drawNote{
    // This should be called in drawRect
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showGestureNote"]){
        return;
    }
    NSInteger index = [[RulesList sharedRulesList] suitedRuleWithGesture:_directions];
    NSString* note = @"";
    if(index == -1)
        return;
    else
        note = [[RulesList sharedRulesList] noteAtIndex:index];
    if(![note isEqualToString:@""]){

        CGRect screenRect = [[NSScreen mainScreen] frame];

        NSFont *font = [NSFont fontWithName:@"Palatino-Roman" size:88.0];

        NSDictionary *textAttributes = @{NSFontAttributeName: font};

        CGSize size = [note sizeWithAttributes:textAttributes];
        int x = ((screenRect.size.width - size.width) / 2);
        int y = ((screenRect.size.height - size.height) / 3 *2);

        [note drawAtPoint:NSMakePoint(x, y) withAttributes:textAttributes];
    }



}

- (void)drawRect:(NSRect)dirtyRect
{
	// draw mouse line

    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"disableMousePath"]) {
        NSBezierPath *path = [NSBezierPath bezierPath];
        path.lineWidth = radius * 2;
        [color setStroke];
        if(points.count>=1){
            [path moveToPoint:[points[0] pointValue]];
        }
        for (int i = 1; i < points.count; i++) {
            [path lineToPoint:[points[i] pointValue]];
        }
        [path stroke];
    }
    NSLog(@"绘画的_directions 》》 %@", _directions);
    [[NSColor redColor] setStroke];
    // NSLog(@"debugPoints.count = %ld", debugPoints.count);
    if(debugPoints.count >= 1){
        for (int i = 0; i < debugPoints.count; i++) {
            // NSLog(@"x = %f y = %f", [debugPoints[i] pointValue].x, [debugPoints[i] pointValue].y);
            NSRect rect1 = NSMakeRect([debugPoints[i] pointValue].x, [debugPoints[i] pointValue].y, 1, 1);
            [NSBezierPath fillRect:rect1];
            [[NSString stringWithFormat:@"(%f, %f)",[debugPoints[i] pointValue].x, [debugPoints[i] pointValue].y] drawAtPoint:NSMakePoint([debugPoints[i] pointValue].x, [debugPoints[i] pointValue].y) withAttributes:NULL];
        }
    }
    
    //[textImage drawInRect:NSScreen.mainScreen.frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [self drawDirection];
    [self drawNote];

}

- (void)drawCircleAtPoint:(NSPoint)point
{
    /*
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [image lockFocus];
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(point.x - radius, point.y - radius, radius * 2, radius * 2)];
        [color set];
        [path fill];

        [image unlockFocus];
    });*/

}

- (void)drawLineFromPoint:(NSPoint)point1 toPoint:(NSPoint)point2 {

    [points addObject:[NSValue valueWithPoint:point1]];
    [points addObject:[NSValue valueWithPoint:point2]];
    self.needsDisplay = YES;
}

- (void)clear {
    [points removeAllObjects];
    [debugPoints removeAllObjects];
    [_directions removeAllObjects];
    self.needsDisplay = YES;
}

- (void)resizeTo:(NSRect)frame {
	self.frame = frame;

	self.needsDisplay = YES;
}

- (void)setEnable:(BOOL)shouldEnable {
/*
	if (!shouldEnable) {
		image = nil;
	} else if (image == nil) {
		image = [[NSImage alloc] initWithSize:NSScreen.mainScreen.frame.size];
	}
*/
}

- (void)mouseDown:(NSEvent *)event {
    lastLocation = [NSEvent mouseLocation];
    NSWindow *w = self.window;
    NSScreen *s = w.screen;
    lastLocation.x -= s.frame.origin.x;
    lastLocation.y -= s.frame.origin.y;
#ifdef DEBUG
    NSLog(@"frame:%@, window:%@, screen:%@",NSStringFromRect( self.frame),NSStringFromRect( w.frame),NSStringFromRect( s.frame));
    NSLog(@"%@",NSStringFromPoint( lastLocation));
#endif
    [points addObject:[NSValue valueWithPoint:lastLocation]];
}

- (void)mouseDragged:(NSEvent *)event
{

	@autoreleasepool {
		NSPoint newLocation = event.locationInWindow;
        NSWindow *w = self.window;
        NSScreen *s = w.screen;
        newLocation.x -= s.frame.origin.x;
        newLocation.y -= s.frame.origin.y;

//		[self drawCircleAtPoint:newLocation];
        [points addObject:[NSValue valueWithPoint:newLocation]];
        self.needsDisplay=YES;
//		[self setNeedsDisplayInRect:NSMakeRect(fmin(lastLocation.x - radius, newLocation.x - radius),
//											   fmin(lastLocation.y - radius, newLocation.y - radius),
//											   abs(newLocation.x - lastLocation.x) + radius * 2,
//											   abs(newLocation.y - lastLocation.y) + radius * 2)];
		lastLocation = newLocation;
	}

}

- (void)mouseUp:(NSEvent *)event
{
	 [self clear];
}


- (void)writeDirection:(NSMutableArray *)directions;
{
    
    _directions = directions;
    NSLog(@"directionStr 改变>> %@", directions);
    self.needsDisplay = YES;
}
- (void)writePoint:(NSPoint *)point;
{
    [debugPoints addObject:[NSValue valueWithPoint:*point]];
}

@end
