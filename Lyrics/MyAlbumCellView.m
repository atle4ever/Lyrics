//
//  MyAlbumCellView.m
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 11. 11..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "MyAlbumCellView.h"

@implementation MyAlbumCellView

@synthesize name;
@synthesize version;
@synthesize dateAdded;

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
