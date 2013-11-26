//
//  TracksCellView.h
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 11. 12..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TracksCellView : NSTableCellView

@property(assign) IBOutlet NSTextField* no;
@property(assign) IBOutlet NSTextField* orgName;
@property(assign) IBOutlet NSTextField* orgArtist;
@property(assign) IBOutlet NSTextField* orgLyric;
@property(assign) IBOutlet NSTextField* refName;
@property(assign) IBOutlet NSTextField* refArtist;
@property(assign) IBOutlet NSTextField* refLyric;

@end
