//
//  AppDelegate.h
//  Lyrics
//
//  Created by Kim Seongjun on 13. 7. 27..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyAlbum.h"
#import "RefAlbum.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
    NSMutableArray *myAlbums;
    MyAlbum* selectedMyAlbum;
    
    NSMutableArray *refAlbums;
    RefAlbum *selectedRefAlbum;
}

@property NSMutableArray* myAlbums;
@property MyAlbum* selectedMyAlbum;
@property NSMutableArray* refAlbums;
@property RefAlbum* selectedRefAlbum;

// UI
@property (assign) IBOutlet NSTableView* myAlbumTableView;
@property (assign) IBOutlet NSTableView* tracksTableView;
@property (assign) IBOutlet NSTableView* refAlbumCandidatesTableView;

@end
