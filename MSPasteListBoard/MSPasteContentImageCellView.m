//
//  MSPasteContentImageCellView.m
//  MSPasteListBoard
//
//  Created by mesird on 30/10/2016.
//  Copyright © 2016 mesird. All rights reserved.
//

#import "MSPasteContentImageCellView.h"

@implementation MSPasteContentImageCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    [self setWantsLayer:YES];
    self.layer.backgroundColor = [NSColor whiteColor].CGColor;
}

@end
