//
//  MSAlertViewController.m
//  MSPasteListBoard
//
//  Created by mesird on 30/10/2016.
//  Copyright © 2016 mesird. All rights reserved.
//

#import "MSAlertViewController.h"

@interface MSAlertViewController ()

@end

@implementation MSAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)clearButtonClicked:(id)sender {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ClearAllItems" object:nil];
    [self.view.window close];
}

- (IBAction)cancelButtonClicked:(id)sender {
    
    [self.view.window close];
}

@end
