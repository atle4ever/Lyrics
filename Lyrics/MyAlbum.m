//
//  MyAlbum.m
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 11. 10..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "MyAlbum.h"

@implementation MyAlbum

@synthesize name;
@synthesize dateAdded;
@synthesize tracks;

- (id)init
{
    self = [super init];
    if (self) {
        tracks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addTrack:(iTunesTrack*)track
{
    assert([[track album] isEqualToString:name]);
    
    [tracks addObject:track];
    
    dateAdded = [dateAdded laterDate:[track dateAdded]];
}

- (void) setDiscNumber
{
    for (iTunesFileTrack* track in tracks) {
        if(track.discNumber == 0) track.discNumber = 1;
    }
}



@end
