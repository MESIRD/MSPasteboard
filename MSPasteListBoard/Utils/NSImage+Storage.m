//
//  NSImage+Storage.m
//  MSPasteListBoard
//
//  Created by mesird on 03/11/2016.
//  Copyright © 2016 mesird. All rights reserved.
//

#import "NSImage+Storage.h"

@implementation NSImage (Storage)

- (BOOL)saveToFilePath:(NSString *)filePath {
    
    CGImageRef cgRef = [self CGImageForProposedRect:NULL context:nil hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[self size]];
    NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:@{}];
    return [pngData writeToFile:filePath atomically:YES];
}

@end
