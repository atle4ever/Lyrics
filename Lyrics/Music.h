//
//  Music.h
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 8. 4..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Music : NSObject
{
    NSString* title;
    NSString* lyric;
    NSString* artist;
    NSString* genre;
}

@property NSString* title;
@property NSString* lyric;
@property NSString* artist;
@property NSString* genre;

- (id)initWithTitle:(NSString*)aTitle;


@end