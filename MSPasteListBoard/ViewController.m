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

#import "NSImage+Storage.h"

@interface ViewController () <NSTableViewDelegate, NSTableViewDataSource> {
    
    NSInteger _lastSelectedRow;
}

@property (nonatomic, strong) NSArray *items;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) NSPasteboard *pasteboard;

@property (nonatomic, strong) NSWindowController *previewWC;
@property (nonatomic, strong) NSWindowController *alertWC;

@property (weak) IBOutlet NSView   *toolBarView;
@property (weak) IBOutlet NSButton *itemCopyButton;
@property (weak) IBOutlet NSButton *itemSaveButton;
@property (weak) IBOutlet NSButton *clearAllButton;

@property (weak) IBOutlet NSView        *searchBarView;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSButton      *clearSearchContentButton;

@property (weak) IBOutlet NSTextField *infoLabel;

@property (weak) IBOutlet NSView *emptyView;

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
    
    [_toolBarView setWantsLayer:YES];
    [_toolBarView.layer setBackgroundColor:[NSColor colorWithRed:55.0f/255.0f green:55.0f/255.0f blue:55.0f/255.0f alpha:1.0f].CGColor];
    
    [_searchBarView setWantsLayer:YES];
    [_searchBarView.layer setBackgroundColor:[NSColor colorWithRed:231.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f].CGColor];
    
//    [_tableView setWantsLayer:YES];
//    [_tableView.layer setBackgroundColor:[NSColor colorWithRed:243.0f/255.0f green:243.0f/255.0f blue:243.0f/255.0f alpha:1.0f].CGColor];
    
    [_infoLabel setWantsLayer:YES];
    [_infoLabel.layer setBackgroundColor:[NSColor colorWithRed:251.0f/255.0f green:251.0f/255.0f blue:251.0f/255.0f alpha:1.0f].CGColor];
    
    self.view.layer.masksToBounds = YES;
    
    [self addObserver:self forKeyPath:@"items" options:NSKeyValueObservingOptionNew context:nil];
    
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"items"]) {
        id items = change[NSKeyValueChangeNewKey];
        NSInteger count = [(NSArray *)items count];
        if (count > 0) {
            _emptyView.hidden = YES;
        } else {
            _emptyView.hidden = NO;
        }
    }
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
    self.items = [[items reverseObjectEnumerator] allObjects];

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
            self.items = [[items reverseObjectEnumerator] allObjects];
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
                self.items = [[items reverseObjectEnumerator] allObjects];
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
    self.items = [NSMutableArray array];
    _lastSelectedRow = -1;
    [_tableView reloadData];
    _infoLabel.stringValue = NSLocalizedString(@"Clear Finished", @"All items in pasteboard are removed");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            _infoLabel.stringValue = [NSString stringWithFormat:@"%@: %ld", NSLocalizedString(@"Items Count", @"Pasteboard items count"), _items.count];
        });
    });
}

- (void)dealloc {
    
    [self removeObserver:self forKeyPath:@"items"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_timer invalidate];
    _timer = nil;
}

#pragma mark - button callback

- (IBAction)clearAllButtonClicked:(NSButton *)sender {
    
    MSAlertViewController *vc = (MSAlertViewController *)self.alertWC.contentViewController;
    [self presentViewControllerAsSheet:vc];
    [vc.view.window makeKeyAndOrderFront:nil];
}

- (IBAction)saveButtonClicked:(NSButton *)sender {
    
    if (_tableView.selectedRow == -1) {
        return;
    }
    id item = _items[_tableView.selectedRow];
    if ([item isKindOfClass:NSImage.class]) {
        NSString *desktopPath = [NSString stringWithFormat:@"/Users/%@/Desktop/SimpleClip_Image_%ld.png", NSUserName(), _tableView.selectedRow];
        BOOL result = [item saveToFilePath:desktopPath];
        if (result) {
            _infoLabel.stringValue = NSLocalizedString(@"Save Success", @"Save image result successful");
        } else {
            _infoLabel.stringValue = NSLocalizedString(@"Save Fail", @"Save image result failed");
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                _infoLabel.stringValue = [NSString stringWithFormat:@"%@: %ld", NSLocalizedString(@"Items Count", @"Pasteboard items count"), _items.count];
            });
        });
    }
}

- (IBAction)itemCopyButtonClicked:(NSButton *)sender {
    
    id item = _items[_tableView.selectedRow];
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

- (IBAction)itemPreviewButtonClicked:(NSButton *)sender {
    
    id item = _items[_tableView.selectedRow];
    MSPreviewViewController *vc = (MSPreviewViewController *)self.previewWC.contentViewController;
    if ([item isKindOfClass:NSString.class]) {
        vc.textLabel.stringValue = item;
        vc.pictureView.image = nil;
    } else if ([item isKindOfClass:NSImage.class]) {
        vc.textLabel.stringValue = @"";
        vc.pictureView.image = item;
    }
    [self.previewWC.window makeKeyAndOrderFront:nil];
}

- (IBAction)textDeleteButtonPressed:(NSButton *)sender {
    
    _searchField.stringValue = @"";
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
    return 80.0f;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _items.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    id item = _items[row];
    if ([item isKindOfClass:NSImage.class]) {
        MSPasteContentImageCellView *cellView = [tableView makeViewWithIdentifier:@"ContentImageCellView" owner:self];
        cellView.imgView.image = _items[row];
        cellView.itemTypeImageView.image = [NSImage imageNamed:@"img_item_icon"];
        return cellView;
    } else if ([item isKindOfClass:NSString.class]) {
        MSPasteContentTextCellView *cellView = [tableView makeViewWithIdentifier:@"ContentTextCellView" owner:self];
        cellView.textLabel.stringValue = _items[row];
        cellView.itemTypeImageView.image = [NSImage imageNamed:@"text_item_icon"];
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

#pragma mark - utils




@end
