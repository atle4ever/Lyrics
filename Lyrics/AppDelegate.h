//
//  AppDelegate.h
//  Lyrics
//
//  Created by Kim Seongjun on 13. 7. 27..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Album.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
    Album *album;
    NSMutableArray *tracks;
    NSMutableArray *selected;
}

@property Album* album;
@property NSMutableArray* tracks;
@property (copy) IBOutlet NSMutableArray* selected;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *tableView;
@end
