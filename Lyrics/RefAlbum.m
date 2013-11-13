//
//  Album.m
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 8. 4..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "RefAlbum.h"

@implementation RefAlbum

@synthesize name;
@synthesize refTracks;
@synthesize artist;
@synthesize year;
@synthesize urlStr;

- (id)initWithName:(NSString*)aName artist:(NSString*)aArtist year:(NSInteger)aYear urlStr:(NSString*)aUrlStr
{
    self = [super init];
    
    [self setName:[aName copy]];
    [self setRefTracks:[[NSMutableArray alloc] init]];
    [self setArtist:[aArtist copy]];
    [self setYear:aYear];
    [self setUrlStr:[aUrlStr copy]];
    
    return self;
}

- (NSString*)description
{
    NSString *desc = [NSString stringWithFormat:@"Title: %@ (#tracks: %ld)\nArtist: %@, Year: %ld", self.name, [self.refTracks count], self.artist, self.year];
    return desc;
}

@end
