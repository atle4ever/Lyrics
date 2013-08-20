//
//  NSLabel.m
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 8. 20..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "UILabel.h"

@implementation UILabel

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setBezeled:NO];
        [self setDrawsBackground:NO];
        [self setEditable:NO];
        [self setSelectable:NO];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
}

@end
