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

- (id) initWithTitle:(NSString *)aTitle
{
    self = [super init];
    
    [self setTitle:[aTitle copy]];
    
    return self;
}

- (NSString*)description
{
    NSString *desc = [NSString stringWithFormat:@"Title: %@", self.title];
    return desc;
}

@end
