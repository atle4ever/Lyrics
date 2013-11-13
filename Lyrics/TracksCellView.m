//
//  TracksCellView.m
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 11. 12..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "TracksCellView.h"

@implementation TracksCellView

@synthesize name;
@synthesize artist;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

@end
