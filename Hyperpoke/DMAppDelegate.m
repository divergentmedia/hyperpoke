//
//  DMAppDelegate.m
//  Hyperpoke
//
//  Created by Colin Mcfadden on 12/9/13.
//  Copyright (c) 2013 Divergent Media. All rights reserved.
//

#import "DMAppDelegate.h"

#define LOAD_CLIPS 1
#define SETFORMAT 2
#define REMOTE_ENABLE 3
#define START_PLAY 4

@implementation DMAppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    if([[NSUserDefaults standardUserDefaults] valueForKey:@"ipAddress"]) {
        [self setupConnection];
    }
    
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"ipAddress"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
   
    NSArray *availableFormats = @[@"NTSC", @"PAL",@"1080p23976",@"1080p24",@"1080p25",@"1080p2997",@"1080p30",@"1080i50",@"1080i5994",@"1080i60",@"720p50",@"720p5994",@"720p60",@"4Kp23976",@"4Kp24",@"4Kp25",@"4Kp2997",@"4Kp30"];
    
    
    [[self.format menu] removeAllItems];
    for(NSString* targetFormat in availableFormats) {
        NSMenuItem* newItem = [[NSMenuItem alloc] initWithTitle:targetFormat action:nil keyEquivalent:@""];
        [[self.format menu] addItem:newItem];
    }
    
    NSNumber* selectedIndex = [[NSUserDefaults standardUserDefaults] valueForKey:@"selectedFormat"];
    [self.format selectItemAtIndex:[selectedIndex integerValue]];

}

- (void)dealloc {
    [self.socket disconnect];
}

- (void)setupConnection {
    NSError *err = nil;
    [self.socket disconnect];
    if (![self.socket connectToHost:[[NSUserDefaults standardUserDefaults] valueForKey:@"ipAddress"] onPort:9993 error:&err]) // Asynchronous!
    {
        // If there was an error, it's likely something like "already connected" or "no delegate set"
        NSLog(@"I goofed: %@", err);
    }
            NSData *responseTerminatorData = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    [self.socket readDataToData:responseTerminatorData withTimeout:-1.0 tag:0];
    [self.socket writeData:[@"remote: enable: true\r\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:REMOTE_ENABLE];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"ipAddress"]) {
        [self setupConnection];
    }
}

- (void)loadClips {

    [self.socket writeData:[@"clips get\r\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:LOAD_CLIPS];

}

- (void)socket:(GCDAsyncSocket*)sock didWriteDataWithTag:(long)tag {
    if(tag == REMOTE_ENABLE) {
        [self.socket readDataToData:[GCDAsyncSocket CRData] withTimeout:-1.0 tag:REMOTE_ENABLE];
    }
    
    if(tag == SETFORMAT) {
        [self.socket readDataToData:[GCDAsyncSocket CRData] withTimeout:-1.0 tag:SETFORMAT];
        
    }
    if(tag == LOAD_CLIPS) {
        NSData *responseTerminatorData = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
        [self.socket readDataToData:responseTerminatorData withTimeout:-1.0 tag:LOAD_CLIPS];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if(tag == REMOTE_ENABLE) {
        [self setResolution:nil];
    }
    if(tag == SETFORMAT) {
        sleep(2);
        [self loadClips];
    }
    if(tag == LOAD_CLIPS) {
        NSMutableArray* tempClipArray = [NSMutableArray array];
        NSArray* clips = [msg componentsSeparatedByString:@"\r\n"];

        for(NSString* clipItem in clips) {
            if([clipItem rangeOfString:@": "].location != NSNotFound) {
                NSArray* splitString = [clipItem componentsSeparatedByString:@" "];
                if([splitString count] != 4) {
                    continue;
                }
                NSString* clipTitle = [splitString objectAtIndex: 1];
                [tempClipArray addObject:clipTitle];
            }
        }
        self.clipList = tempClipArray;
        [self.clipListView reloadData];
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    }
    
}

- (IBAction)stop:(id)sender {
    [self.socket writeData:[@"stop\r\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    
}

- (IBAction)play:(id)sender {

    NSInteger clipId = [self.clipListView selectedRow] +1;
    NSString* command = [NSString stringWithFormat:@"goto: clip id: %d\r\n", (int)clipId];
    
    [self.socket writeData:[command dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    
    [self.socket writeData:[[NSString stringWithFormat:@"play: loop: %@ single clip: %@\r\n", self.loop?@"true":@"false", self.playAll?@"false":@"true"] dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:START_PLAY];


}


- (IBAction)setResolution:(id)sender {
    NSString* slotValue = [[self.slot selectedItem] title];
    NSString* formatValue = [[self.format selectedItem] title];
    NSString* command = [NSString stringWithFormat:@"slot select: slot id: %@ video format: %@\r\n", slotValue, formatValue ];

    [self.socket writeData:[command dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:SETFORMAT];

}

- (IBAction)showPreferences:(id)sender {
    self.preferencesWindow = [[NSWindowController alloc] initWithWindowNibName:@"Preferences"];
    [self.preferencesWindow showWindow:self];

}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.clipList count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {

    NSString *valueToDisplay = [[NSString alloc] init];
    
    valueToDisplay = [self.clipList objectAtIndex:row];
    
    return valueToDisplay;
}


@end
