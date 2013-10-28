//
//  RefAlbumCandidate.h
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 10. 28..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RefAlbumCandidate : NSObject
{
    NSString* name;
    NSString* artist;
    NSString* urlStr;
}

@property NSString* name;
@property NSString* artist;
@property NSString* urlStr;

- (id)initWithName:(NSString*)aName artist:(NSString*)aArtist urlStr:(NSString*)aUrlStr;
@end
