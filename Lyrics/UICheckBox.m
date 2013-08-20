//
//  CustomCheckBox.m
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 8. 18..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "UICheckBox.h"

@implementation UICheckBox

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        [self setButtonType:NSSwitchButton];
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
}

@end
