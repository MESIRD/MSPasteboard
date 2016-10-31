//
//  ViewController.m
//  MSPasteListBoard
//
//  Created by mesird on 30/10/2016.
//  Copyright © 2016 mesird. All rights reserved.
//

#import "ViewController.h"

#import "MSPasteContentTextCellView.h"
#import "MSPasteContentImageCellView.h"

#import "MSPreviewViewController.h"

#import "MSAlertViewController.h"

@interface ViewController () <NSTableViewDelegate, NSTableViewDataSource> {
    
    NSInteger _lastSelectedRow;
}

@property (nonatomic, strong) NSArray *items;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@property (nonatomic, strong) NSPasteboard *pasteboard;

@property (weak) IBOutlet NSTextField *infoLabel;

@property (nonatomic, strong) NSWindowController *previewWC;

@property (nonatomic, strong) NSWindowController *alertWC;

@end

@implementation ViewController

// click delete to delete
// click space to show detail
// click clear to remove all

static NSString *const kUserDefaultsPastedItems = @"PastedItems";
static const NSTimeInterval kRefreshTimeInterval = 5.0f;

- (NSWindowController *)alertWC {
    
    if (!_alertWC) {
        _alertWC = [self.storyboard instantiateControllerWithIdentifier:@"AlertWindowController"];
    }
    return _alertWC;
}

- (NSWindowController *)previewWC {
    
    if (!_previewWC) {
        _previewWC = [self.storyboard instantiateControllerWithIdentifier:@"PreviewWindowController"];
        _previewWC.window.titlebarAppearsTransparent = YES;
        _previewWC.window.titleVisibility = YES;
    }
    return _previewWC;
}

- (NSUserDefaults *)userDefaults {
    
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return _userDefaults;
}

- (NSPasteboard *)pasteboard {
    
    if (!_pasteboard) {
        _pasteboard = [NSPasteboard generalPasteboard];
    }
    return _pasteboard;
}

#pragma mark - view initialization

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    _tableView.delegate   = self;
    _tableView.dataSource = self;
    
    _lastSelectedRow = -1;
    
    [self _loadData];
    [self _startRefreshTimer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_clearAllItems) name:@"ClearAllItems" object:nil];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    
    NSSize minSize = self.view.window.minSize;
    minSize.width  = 320.0f;
    minSize.height = 480.0f;
    self.view.window.minSize = minSize;
    
    NSSize maxSize = self.view.window.maxSize;
    maxSize.width  = 480.0f;
    self.view.window.maxSize = maxSize;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)_startRefreshTimer {
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimeInterval target:self selector:@selector(_checkGeneralPasteboard) userInfo:nil repeats:YES];
    [_timer fire];
}

- (void)_loadData {
    
    _items = [NSArray array];
    NSMutableArray *items = [NSMutableArray array];

    id data = [self.userDefaults objectForKey:kUserDefaultsPastedItems];
    if (!data) {
        NSArray *objectArray = [self.pasteboard readObjectsForClasses:@[NSString.class, NSImage.class] options:@{}];
        if (objectArray.count > 0) {
            [items addObject:objectArray.firstObject];
        }
    } else {
        items = [NSUnarchiver unarchiveObjectWithData:data];
    }
    _items = [[items reverseObjectEnumerator] allObjects];

    _infoLabel.stringValue = [NSString stringWithFormat:@"%@: %ld", NSLocalizedString(@"Items Count", @"Pasteboard items count"), _items.count];
    [_tableView reloadData];
}

- (void)_checkGeneralPasteboard {
    
    NSArray *objectArray = [self.pasteboard readObjectsForClasses:@[NSString.class, NSImage.class] options:@{}];
    if (!objectArray || objectArray.count == 0) {
        return;
    }
    NSObject *object = objectArray.firstObject;
    if (object) {

        id data = [self.userDefaults objectForKey:kUserDefaultsPastedItems];
        if (!data) {
            NSMutableArray *items = [NSMutableArray array];
            [items addObject:object];
            _items = [[items reverseObjectEnumerator] allObjects];
            [self.userDefaults setObject:[NSArchiver archivedDataWithRootObject:items] forKey:kUserDefaultsPastedItems];
            [_tableView reloadData];
        } else {
            NSMutableArray *items = [NSUnarchiver unarchiveObjectWithData:data];
            Class objClass = object.class;
            BOOL bContains = NO;
            for (id item in items) {
                if ([item isKindOfClass:objClass]) {
                    if ([item isKindOfClass:NSString.class]) {
                        if ([item isEqualToString:(NSString *)object]) {
                            bContains = YES;
                            break;
                        }
                    } else if ([item isKindOfClass:NSImage.class]) {
                        // compare image size
                        NSSize oldSize = [(NSImage *)item size];
                        NSSize newSize = [(NSImage *)object size];
                        if (oldSize.width == newSize.width && oldSize.height == newSize.height) {
                            bContains = YES;
                            break;
                        }
                        
                        // compare image data
                        NSData *old = [(NSImage *)item TIFFRepresentation];
                        NSData *new = [(NSImage *)object TIFFRepresentation];
                        if ([old isEqualToData:new]) {
                            bContains = YES;
                            break;
                        }
                    }
                }
            }
            if (!bContains) {
                [items addObject:object];
                _items = [[items reverseObjectEnumerator] allObjects];
                [self.userDefaults setObject:[NSArchiver archivedDataWithRootObject:items] forKey:kUserDefaultsPastedItems];
                [_tableView reloadData];
            }
        }
    }
    _infoLabel.stringValue = [NSString stringWithFormat:@"%@: %ld", NSLocalizedString(@"Items Count", @"Pasteboard items count"), _items.count];
}

- (void)_clearAllItems {
    
    [self.pasteboard clearContents];
    [self.userDefaults setObject:nil forKey:kUserDefaultsPastedItems];
    _items = [NSMutableArray array];
    [_tableView reloadData];
    _infoLabel.stringValue = NSLocalizedString(@"Clear Finished", @"All items in pasteboard are removed");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            _infoLabel.stringValue = [NSString stringWithFormat:@"%@: %ld", NSLocalizedString(@"Items Count", @"Pasteboard items count"), _items.count];
        });
    });
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_timer invalidate];
    _timer = nil;
}

#pragma mark - button callback

- (IBAction)clearButtonClicked:(NSButton *)sender {
    
    MSAlertViewController *vc = (MSAlertViewController *)self.alertWC.contentViewController;
    [vc.view.window makeKeyAndOrderFront:nil];
}

#pragma mark - keyboard event

- (void)keyDown:(NSEvent *)event {
    
    if (_tableView.selectedRow == -1) {
        return;
    }
    id item = _items[_tableView.selectedRow];
    if (event.keyCode == 49) {
        // press 'space'
        MSPreviewViewController *vc = (MSPreviewViewController *)self.previewWC.contentViewController;
        if ([item isKindOfClass:NSString.class]) {
            vc.textLabel.stringValue = item;
            vc.pictureView.image = nil;
        } else if ([item isKindOfClass:NSImage.class]) {
            vc.textLabel.stringValue = @"";
            vc.pictureView.image = item;
        }
        [self.previewWC.window makeKeyAndOrderFront:nil];
    } else if (event.keyCode == 51) {
        // press 'delete'
        
    } else if (event.keyCode == 36) {
        // press 'enter'
        
        [self.pasteboard clearContents];
        if ([item isKindOfClass:NSString.class]) {
            [self.pasteboard setString:item forType:NSStringPboardType];
        } else if ([item isKindOfClass:NSImage.class]) {
            [self.pasteboard setData:[(NSImage *)item TIFFRepresentation] forType:NSTIFFPboardType];
        }
        
        _infoLabel.stringValue = NSLocalizedString(@"Copy Successfully", @"When a item is copied");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                _infoLabel.stringValue = [NSString stringWithFormat:@"%@: %ld", NSLocalizedString(@"Items Count", @"Pasteboard items count"), _items.count];
            });
        });
    }
}

#pragma mark - table view delegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 50.0f;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _items.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    id item = _items[row];
    if ([item isKindOfClass:NSImage.class]) {
        MSPasteContentImageCellView *cellView = [tableView makeViewWithIdentifier:@"ContentImageCellView" owner:self];
        cellView.imgView.image = _items[row];
        return cellView;
    } else if ([item isKindOfClass:NSString.class]) {
        MSPasteContentTextCellView *cellView = [tableView makeViewWithIdentifier:@"ContentTextCellView" owner:self];
        cellView.textLabel.stringValue = _items[row];
        return cellView;
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    
    if (_tableView.selectedRow >= 0 && _tableView.selectedRow < _items.count) {
        // display preview
        id item = _items[_tableView.selectedRow];
        MSPreviewViewController *vc = (MSPreviewViewController *)self.previewWC.contentViewController;
        if ([item isKindOfClass:NSString.class]) {
            vc.textLabel.stringValue = item;
            vc.pictureView.image = nil;
        } else if ([item isKindOfClass:NSImage.class]) {
            vc.textLabel.stringValue = @"";
            vc.pictureView.image = item;
        }
        
        // hide check icon
        if (_lastSelectedRow != -1) {
            id item = _items[_lastSelectedRow];
            if ([item isKindOfClass:NSString.class]) {
                MSPasteContentTextCellView *textCellView = [_tableView viewAtColumn:0 row:_lastSelectedRow makeIfNecessary:NO];
                textCellView.checkIconView.hidden = YES;
            } else if ([item isKindOfClass:NSImage.class]) {
                MSPasteContentImageCellView *imgCellView = [_tableView viewAtColumn:0 row:_lastSelectedRow makeIfNecessary:NO];
                imgCellView.checkIconView.hidden = YES;
            }
        }
        
        // show check icon
        if ([item isKindOfClass:NSString.class]) {
            MSPasteContentTextCellView *textCellView = [_tableView viewAtColumn:0 row:_tableView.selectedRow makeIfNecessary:NO];
            textCellView.checkIconView.hidden = NO;
        } else if ([item isKindOfClass:NSImage.class]) {
            MSPasteContentImageCellView *imgCellView = [_tableView viewAtColumn:0 row:_tableView.selectedRow makeIfNecessary:NO];
            imgCellView.checkIconView.hidden = NO;
        }
    }
    
    _lastSelectedRow = _tableView.selectedRow;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    
    
    
    
    return YES;
}

#pragma mark - utils




@end
