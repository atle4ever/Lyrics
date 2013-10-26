//
//  Music.m
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 8. 4..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "RefTrack.h"

@implementation RefTrack

@synthesize name;
@synthesize lyrics;
@synthesize artist;
@synthesize genre;
@synthesize discNumber;
@synthesize trackNumber;

- (id) initWithName:(NSString *)aName
{
    self = [super init];
    [self setName:[aName copy]];
    
    return self;
}

- (NSString*)description
{
    NSString *desc = [NSString stringWithFormat:@"Name: %@[%ld-%ld]\nArtist: %@, Genre: %@\nLyrics\n%@", self.name, (long)self.discNumber, (long)self.trackNumber, self.artist, self.genre, self.lyrics];
    return desc;
}

@end
