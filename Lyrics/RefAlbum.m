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


- (id)initWithTitle:(NSString *)aTitle numOfMusic:(NSUInteger)num
{
    self = [super init];
    
    [self setName:[aTitle copy]];
    
    [self setRefTracks:[[NSMutableArray alloc] initWithCapacity:num]];
    
    return self;
}

- (NSString*)description
{
    NSString *desc = [NSString stringWithFormat:@"Title: %@ (#tracks: %ld)\nArtist: %@, Year: %ld", self.name, [self.refTracks count], self.artist, self.year];
    return desc;
}

@end
