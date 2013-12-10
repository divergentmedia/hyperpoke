//
//  DMAppDelegate.h
//  Hyperpoke
//
//  Created by Colin Mcfadden on 12/9/13.
//  Copyright (c) 2013 Divergent Media. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "GCDAsyncSocket.h"

@interface DMAppDelegate : NSObject <NSApplicationDelegate,  NSTableViewDataSource>

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic) GCDAsyncSocket* socket;
@property (nonatomic) IBOutlet NSPopUpButton* format;
@property (nonatomic) IBOutlet NSPopUpButton* slot;
@property (nonatomic) NSWindowController* preferencesWindow;
@property (nonatomic) NSArray* availableFormats;
@property (nonatomic) NSArray* clipList;
@property (weak) IBOutlet NSTableView* clipListView;
@property (nonatomic) BOOL loop;
@property (nonatomic) BOOL playAll;

- (IBAction)setResolution:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)play:(id)sender;
- (IBAction)stop:(id)sender;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;


@end
