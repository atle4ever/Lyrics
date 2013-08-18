//
//  AppDelegate.m
//  Lyrics
//
//  Created by Kim Seongjun on 13. 7. 27..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "AppDelegate.h"
#import "iTunes.h"
#import "Album.h"
#import "Music.h"
#import "CustomCheckBox.h"

@implementation AppDelegate

@synthesize album;
@synthesize tracks;
@synthesize selected;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Get selected tracks
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    NSArray *sel = [[iTunes selection] get];
    NSUInteger nSel = [sel count];
    
    tracks = [[NSMutableArray alloc] initWithCapacity:nSel];
    for (iTunesFileTrack* f in sel)
    {
        [tracks addObject:f];
    }
    NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"trackNumber" ascending:YES];
    NSArray *sortDescs = [NSArray arrayWithObject:sortDesc];
    [tracks sortUsingDescriptors:sortDescs];
    assert(nSel == [tracks count]);
    
    // Create array for selected
    selected = [[NSMutableArray alloc] initWithCapacity:nSel];
    for(int i = 0; i < nSel; ++i)
    {
        [selected addObject:[NSNumber numberWithInt:NSOnState]];
    }
    
    // Get URL of album page from user
    NSString *urlStr;
    NSAlert *dialog = [NSAlert alertWithMessageText:@"앨범 URL을 입력해주세요." defaultButton:@"확인" alternateButton:@"취소" otherButton:nil informativeTextWithFormat:@"현재 벅스 사이트만 지원합니다."];
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    [dialog setAccessoryView:input];
    NSInteger button = [dialog runModal];
    if (button == NSAlertDefaultReturn)
    {
        urlStr = [input stringValue];
    }
    else
    {
        return;
    }
    
    // Get album page
    NSURL *url = [[NSURL alloc] initWithString:urlStr];
    NSError *err=nil;
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:url
                                                                 options:NSXMLDocumentTidyXML
                                                                   error:&err];
    
    // Get list of song
    NSArray *nodes = [xmlDoc nodesForXPath:@"//*[@id=\"idTrackList\"]/li" error:&err];
    assert([tracks count] == [nodes count]);
    
    album = [[Album alloc] initWithTitle:@"test" numOfMusic:[nodes count]];
    
    for (NSXMLNode* n in nodes)
    {
        // Title
        NSString* title = [[n nodesForXPath:@"./dl/dt/a/@title" error:&err][0] stringValue];
        Music *music = [[Music alloc] initWithTitle:title];
        
        
        // Lyric
        NSString* hrefStr = [[n nodesForXPath:@"./dl/dt/a/@href" error:&err][0] stringValue];
        NSString* musicId = [[NSNumber numberWithInteger:[[hrefStr substringWithRange:NSMakeRange(35, 9)] integerValue]] stringValue];
        NSString* musicUrlStr = [NSString stringWithFormat:@"http://music.bugs.co.kr/track/%@", musicId];
        NSURL *musicUrl = [[NSURL alloc] initWithString:musicUrlStr];
        
        NSXMLDocument *musicPage = [[NSXMLDocument alloc] initWithContentsOfURL:musicUrl
                                                                        options:NSXMLDocumentTidyXML
                                                                          error:&err];
        
        NSArray *nodes = [musicPage nodesForXPath:@"//*[@id=\"content\"]/div[2]/p" error:&err];
        if([nodes count] > 0)
        {
            assert([nodes count] == 1);
            NSXMLNode *n = nodes[0];
            NSArray *lines = [n children];
            
            NSMutableString* lyric = [NSMutableString string];
            for(NSXMLNode *l in lines)
            {
                NSString* str = [l description];
                if([str compare:@"<br></br>"] == 0)
                {
                    [lyric appendString:@"\n"];
                }
                else
                {
                    [lyric appendString:str];
                }
            }
            [music setLyric:lyric];
        }
        else
        {
            [music setLyric:@""];
        }
        
        // Artist
        nodes = [musicPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/div/dl/dd[1]/strong/a/text()" error:&err];
        if([nodes count] != 1) // when artist isn't linked
            nodes = [musicPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/div/dl/dd[1]/strong/text()" error:&err];
        assert([nodes count] == 1);
        [music setArtist:[nodes[0] description]];
        
        // Genre
        nodes = [musicPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/div/dl/dd[3]/text()" error:&err];
        assert([nodes count] == 1);
        [music setGenre:[nodes[0] description]];
        
        [album.musics addObject:music];
    }
    
    // Get album artist
    nodes = [xmlDoc nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[1]/strong/a/text()" error:&err];
    if([nodes count] != 1)  // when artist isn't linked
        nodes = [xmlDoc nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[1]/strong/text()" error:&err];
    assert([nodes count] == 1);
    [album setArtist:[nodes[0] description]];
    
    // Get issue date
    nodes = [xmlDoc nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[5]/text()" error:&err];
    assert([nodes count] == 1);
    [album setYear:[[[nodes[0] description] substringToIndex:4] integerValue]];
    
    [self.tableView reloadData];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [album.musics count];
}



- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
   return @"test";
}

- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"CustomCell" owner:self];
    
    if (result == nil) {
        result = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, 418, 82)];
        [result setBackgroundStyle:NSBackgroundStyleRaised];
        
        CustomCheckBox* check = [[CustomCheckBox alloc] initWithFrame:NSMakeRect(18, 32, 22, 18)];
        [check setButtonType:NSSwitchButton];
        [check setTag:10];
        [result addSubview:check];
        
        NSTextField *label1 = [[NSTextField alloc] initWithFrame:NSMakeRect(44, 45, 356, 17)];
        [label1 setBezeled:NO];
        [label1 setDrawsBackground:NO];
        [label1 setEditable:NO];
        [label1 setSelectable:NO];
        [label1 setTag:11];
        [result addSubview:label1];
        
        NSTextField *label2 = [[NSTextField alloc] initWithFrame:NSMakeRect(44, 22, 356, 17)];
        [label2 setBezeled:NO];
        [label2 setDrawsBackground:NO];
        [label2 setEditable:NO];
        [label2 setSelectable:NO];
        [label2 setTag:12];
        [result addSubview:label2];
    }
    iTunesFileTrack* track = self.tracks[row];
    Music *music = self.album.musics[row];
    NSNumber *select = self.selected[row];
    
    CustomCheckBox *check = [result viewWithTag:10];
    [check setIndex:row];
    [check setState:[select integerValue]];
    [check setTarget:self];
    [check setAction:@selector(performClick:)];
    
    NSTextField *label1 = [result viewWithTag:11];
    [label1 setStringValue:[track name]];
    
    NSTextField *label2 = [result viewWithTag:12];
    [label2 setStringValue:[music title]];
    
    return result;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 82;
}

- (IBAction) performClick:(id)sender
{
    CustomCheckBox *check = sender;
    NSNumber* s = self.selected[[check index]];
    if([s integerValue] == NSOnState)
        [self.selected replaceObjectAtIndex:[check index] withObject:[NSNumber numberWithInteger:NSOffState]];
    else
        [self.selected replaceObjectAtIndex:[check index] withObject:[NSNumber numberWithInteger:NSOnState]];
}

- (IBAction)updateTracks:(id)sender
{
    // Update informations
    for(NSInteger i = 0; i < [self.tracks count]; ++i)
    {
        NSNumber* s = self.selected[i];
        if([s integerValue] == NSOffState)
            continue;
        
        iTunesFileTrack* track = self.tracks[i];
        Music* music = self.album.musics[i];
        
        NSLog(@"변경: %@ -> %@", [track name], [music title]);
        
        [track setName:[music title]];
        [track setLyrics:[music lyric]];
        [track setArtist:[music artist]];
        [track setGenre:[music genre]];
        [track setAlbumArtist:[album artist]];
        [track setYear:[album year]];
    }
}

@end
