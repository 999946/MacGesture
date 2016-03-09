//
//  CanvasView.h
//  MouseGesture
//
//  Created by keakon on 11-11-14.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CanvasView : NSView {
	NSColor *color;

    NSPoint lastLocation;


	NSUInteger radius;

	NSMutableArray *points; // NSPoint array
    NSMutableArray *debugPoints; // NSPoint array
    NSMutableArray *_directions;

}

- (void)clear;
- (void)resizeTo:(NSRect)frame;
- (void)setEnable:(BOOL)shouldEnable;
- (void)writeDirection:(NSMutableArray *)directions;
- (void)writePoint:(NSPoint *)point;

@end
