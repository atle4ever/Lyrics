//
//  MyAlbum.h
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 11. 10..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"

@interface MyAlbum : NSObject
{
    NSString* name;
    NSDate* dateAdded;
    NSMutableArray* tracks;
}

@property NSString* name;
@property NSDate* dateAdded;
@property NSMutableArray* tracks;

- (void) addTrack:(iTunesTrack*)track;
- (void) setDiscNumber;

@end
