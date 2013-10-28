//
//  RefAlbumSelector.m
//  Lyrics
//
//  Created by Kim Seongjun on 2013. 10. 28..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "RefAlbumSelector.h"
#import "UILabel.h"
#import "UICheckBox.h"
#import "RefAlbumCandidate.h"

@interface RefAlbumSelector ()

@end

@implementation RefAlbumSelector

@synthesize refAlbumCandidates;
@synthesize selected;


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [refAlbumCandidates count];
}

- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"CustomCell2" owner:self];
    
    if (result == nil) {
        result = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, 418, 82)];
        [result setIdentifier:@"CustomCell2"];
        
        UICheckBox* check = [[UICheckBox alloc] initWithFrame:NSMakeRect(18, 32, 22, 18)];
        [check setTag:10];
        [result addSubview:check];
        
        UILabel *label1 = [[UILabel alloc] initWithFrame:NSMakeRect(44, 45, 356, 17)];
        [label1 setTag:11];
        [result addSubview:label1];
        
        UILabel *label2 = [[UILabel alloc] initWithFrame:NSMakeRect(44, 22, 356, 17)];
        [label2 setTag:12];
        [result addSubview:label2];
    }
    RefAlbumCandidate* album = refAlbumCandidates[row];
    
    UICheckBox *check = [result viewWithTag:10];
    [check setIndex:row];
    [check setState:NSOffState];
    [check setTarget:self];
    [check setAction:@selector(clickCheckBox:)];
    
    UILabel *label1 = [result viewWithTag:11];
    [label1 setStringValue:[album name]];
    
    UILabel *label2 = [result viewWithTag:12];
    [label2 setStringValue:[album artist]];
    
    return result;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 82;
}

- (IBAction) clickCheckBox:(id)sender
{
    UICheckBox *check = sender;
    self.selected = [check index];
    
    [NSApp stopModalWithCode:NSOKButton];
    [NSApp endSheet:self.window];
}

- (IBAction) clickManualButton:(id)sender
{
    self.selected = -1;
    [NSApp stopModalWithCode:NSCancelButton];
    [NSApp endSheet:self.window];
}
@end
