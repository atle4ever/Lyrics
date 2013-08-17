//
//  Music.m
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 8. 4..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "Music.h"

@implementation Music

@synthesize title;
@synthesize lyric;
@synthesize artist;
@synthesize genre;

- (id) initWithTitle:(NSString *)aTitle
{
    self = [super init];
    
    [self setTitle:[aTitle copy]];
    
    return self;
}

- (NSString*)description
{
    NSString *descLyric;
    if(lyric != nil)
    {
        if([lyric length] > 40)
        {
            descLyric = [NSString stringWithFormat:@"%@ ...",[lyric substringToIndex:20]];
        }
        else
        {
            descLyric = lyric;
        }
    }
    else
    {
        descLyric = @"no lyrics";
    }
    
    NSString *desc = [NSString stringWithFormat:@"Title: %@, Lyrics: %@", self.title, descLyric];
    return desc;
}

@end
