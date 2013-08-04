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
}

@property NSString* title;
@property NSMutableArray* musics;

- (id)initWithTitle:(NSString*)aTitle numOfMusic:(NSUInteger)num;

@end
