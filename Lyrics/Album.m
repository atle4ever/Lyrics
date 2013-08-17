//
//  Album.m
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 8. 4..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "Album.h"

@implementation Album

@synthesize title;
@synthesize musics;
@synthesize artist;
@synthesize year;


- (id)initWithTitle:(NSString *)aTitle numOfMusic:(NSUInteger)num
{
    self = [super init];
    
    [self setTitle:[aTitle copy]];
    
    [self setMusics:[[NSMutableArray alloc] initWithCapacity:num]];
    
    return self;
}

- (NSString*)description
{
    NSString *desc = [NSString stringWithFormat:@"Title: %@, numOfMusics: %ld", self.title, [self.musics count]];
    return desc;
}

@end
