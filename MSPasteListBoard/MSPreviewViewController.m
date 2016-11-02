//
//  MSPreviewViewController.m
//  MSPasteListBoard
//
//  Created by mesird on 30/10/2016.
//  Copyright © 2016 mesird. All rights reserved.
//

#import "MSPreviewViewController.h"

@interface MSPreviewViewController ()

@property (assign) NSPoint initialLocation;

@end

@implementation MSPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)mouseDown:(NSEvent *)event {
    
    self.initialLocation = [event locationInWindow];
}

- (void)mouseDragged:(NSEvent *)event {
    
    NSRect screenVisibleFrame = [[NSScreen mainScreen] visibleFrame];
    NSRect windowFrame = [self.view.window frame];
    NSPoint newOrigin = windowFrame.origin;
    
    // Get the mouse location in window coordinates.
    NSPoint currentLocation = [event locationInWindow];
    // Update the origin with the difference between the new mouse location and the old mouse location.
    newOrigin.x += (currentLocation.x - _initialLocation.x);
    newOrigin.y += (currentLocation.y - _initialLocation.y);
    
    // Don't let window get dragged up under the menu bar
    if ((newOrigin.y + windowFrame.size.height) > (screenVisibleFrame.origin.y + screenVisibleFrame.size.height)) {
        newOrigin.y = screenVisibleFrame.origin.y + (screenVisibleFrame.size.height - windowFrame.size.height);
    }
    
    // Move the window to the new location
    [self.view.window setFrameOrigin:newOrigin];
}

@end
