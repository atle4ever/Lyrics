//
//  AppDelegate.h
//  Lyrics
//
//  Created by Kim Seongjun on 13. 7. 27..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RefAlbum.h"
#import "RefTrack.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
    RefAlbum *refAlbum;
    NSMutableArray *myTracks;
    NSMutableArray *willBeUpdated;
}

@property RefAlbum* refAlbum;
@property NSMutableArray* myTracks;
@property (copy) IBOutlet NSMutableArray* willBeUpdated;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *tableView;

- (void)displayErrorMsgOfItunesSelection:(NSString*) msg;
- (void)getMyTracksFromItunes;
- (RefAlbum*)getRefAlbumFromWeb:(NSString*)refAlbumUrlStr;
- (void)getRefTrackFromWeb:(RefTrack*)refTrack withUrl:(NSString*)refTrackUrlStr toRefAlbum:(RefAlbum*)refAlbum;
@end
