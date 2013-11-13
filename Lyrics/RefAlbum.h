//
//  Album.h
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 8. 4..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RefAlbum : NSObject
{
    NSString* name;
    NSMutableArray* refTracks;
    NSString* artist;
    NSInteger year;
    NSString* urlStr;
}

@property NSString* name;
@property NSMutableArray* refTracks;
@property NSString* artist;
@property NSInteger year;
@property NSString* urlStr;

- (id)initWithName:(NSString*)aName artist:(NSString*)aArtist year:(NSInteger)aYear urlStr:(NSString*)aUrlStr;

@end
