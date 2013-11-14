//
//  MyAlbumCellView.h
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 11. 11..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MyAlbumCellView : NSTableCellView

@property(assign) IBOutlet NSTextField* name;
@property(assign) IBOutlet NSTextField* version;
@property(assign) IBOutlet NSTextField* dateAdded;

@end
