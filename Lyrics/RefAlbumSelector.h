//
//  RefAlbumSelector.h
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 10. 28..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RefAlbumSelector : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
    NSMutableArray* refAlbumCandidates;
    NSInteger selected;
}

@property NSMutableArray* refAlbumCandidates;
@property NSInteger selected;

@end
