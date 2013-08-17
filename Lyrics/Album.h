//
//  Album.h
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 8. 4..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Album : NSObject
{
    NSString* title;
    NSMutableArray* musics;
    NSString* artist;
    NSInteger year;
}

@property NSString* title;
@property NSMutableArray* musics;
@property NSString* artist;
@property NSInteger year;

- (id)initWithTitle:(NSString*)aTitle numOfMusic:(NSUInteger)num;

@end
