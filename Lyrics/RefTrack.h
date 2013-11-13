//
//  Music.h
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 8. 4..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RefTrack : NSObject
{
    NSString* name;
    NSString* lyrics;
    NSString* artist;
    NSString* genre;
    NSInteger discNumber;
    NSInteger trackNumber;
    NSString* urlStr;
}

@property NSString* name;
@property NSString* lyrics;
@property NSString* artist;
@property NSString* genre;
@property NSInteger discNumber;
@property NSInteger trackNumber;
@property NSString* urlStr;

- (id)initWithName:(NSString*)aName;


@end
