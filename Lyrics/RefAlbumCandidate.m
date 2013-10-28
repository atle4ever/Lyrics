//
//  RefAlbumCandidate.m
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 10. 28..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "RefAlbumCandidate.h"

@implementation RefAlbumCandidate

@synthesize name;
@synthesize artist;
@synthesize urlStr;

- (id)initWithName:(NSString*)aName artist:(NSString*)aArtist urlStr:(NSString*)aUrlStr
{
    self = [super init];
    
    [self setName:[aName copy]];
    [self setArtist:[aArtist copy]];
    [self setUrlStr:[aUrlStr copy]];
    
    return self;
}

    
@end
