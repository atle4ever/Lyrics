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
    NSMutableArray *myAlbums;
    NSMutableArray *refAlbumCandidates;
    NSMutableArray *willBeUpdated;
    NSString* refTrackUrlStr;
}

@property RefAlbum* refAlbum;

@property NSMutableArray* myTracks;
@property NSMutableArray* myAlbums;
@property NSMutableArray* refAlbumCandidates;
@property NSString* refTrackUrlStr;
@property (copy) IBOutlet NSMutableArray* willBeUpdated;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSTableView* myAlbumTableView;
@property (assign) IBOutlet NSTableView* tracksTableView;
@property (assign) IBOutlet NSTableView* refAlbumCandidatesTableView;

- (void)displayErrorMsgOfItunesSelection:(NSString*) msg;
- (void)getMyTracksFromItunes;
- (RefAlbum*)getRefAlbumFromWeb:(NSString*)refAlbumUrlStr;
- (void)getRefTrackFromWeb:(RefTrack*)refTrack toRefAlbum:(RefAlbum*)refAlbum;
- (void)getTrackNumberFrom:(NSString*)trackNumberStr discNumber:(NSInteger*)discNumber trackNumber:(NSInteger*)trackNumber;
- (NSString*)getRefAlbumUrl;
- (void)reloadMyAlbumTable;
- (void)reloadTracksTable:(NSString*)refAlbumUrlStr;
@end
