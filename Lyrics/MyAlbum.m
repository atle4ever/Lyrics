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
@synthesize artist;
@synthesize version;
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

- (NSString*) getVersionFrom:(iTunesTrack*)track
{
    NSString* comment = track.comment;
    if([comment hasPrefix:@"Ver."])
        return [comment componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]][0];
    else
        return @"";
}

- (void) addTrack:(iTunesTrack*)track
{
    assert([[track album] isEqualToString:name]);
    
    // If discNumber ins't set, set as 1 (default)
    if(track.discNumber == 0) track.discNumber = 1;
    
    [tracks addObject:track];
    
    // Set dateAdded
    dateAdded = [dateAdded laterDate:[track dateAdded]];
    
    // Set version
    NSString* trackVer = [self getVersionFrom:track];
    if([trackVer compare:version] < 0 || version == nil)
        version = trackVer;
    
    // Set artist
    if(self.artist == nil)
        self.artist = track.artist;
}

@end
