//
//  AppDelegate.m
//  Lyrics
//
//  Created by Kim Seongjun on 13. 7. 27..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "AppDelegate.h"
#import "iTunes.h"
#import "RefAlbum.h"
#import "RefTrack.h"
#import "UICheckBox.h"
#import "UILabel.h"

@implementation AppDelegate

@synthesize refAlbum;
@synthesize myTracks;
@synthesize willBeUpdated;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Get my tracks
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    NSArray *selection = [[iTunes selection] get];
    NSUInteger nSel = [selection count];
    
    myTracks = [[NSMutableArray alloc] initWithCapacity:nSel];
    for (iTunesFileTrack* track in selection)
    {
        [myTracks addObject:track];
    }
    NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"trackNumber" ascending:YES];
    NSArray *sortDescs = [NSArray arrayWithObject:sortDesc];
    [myTracks sortUsingDescriptors:sortDescs];
    assert(nSel == [myTracks count]);
    
    // Create array for selected
    willBeUpdated = [[NSMutableArray alloc] initWithCapacity:nSel];
    for(int i = 0; i < nSel; ++i)
    {
        [willBeUpdated addObject:[NSNumber numberWithInt:NSOnState]];
    }
    
    // Get ref album page's URL from user
    NSString *refAlbumUrlStr;
    NSAlert *dialog = [NSAlert alertWithMessageText:@"앨범 URL을 입력해주세요." defaultButton:@"확인" alternateButton:@"취소" otherButton:nil informativeTextWithFormat:@"현재 벅스 사이트만 지원합니다."];
    NSTextField *userTextInput = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    [dialog setAccessoryView:userTextInput];
    NSInteger clicked = [dialog runModal];
    if (clicked == NSAlertDefaultReturn)
        refAlbumUrlStr = [userTextInput stringValue];
    else
        return;
    
    // Get album page
    NSURL *refAlbumUrl = [[NSURL alloc] initWithString:refAlbumUrlStr];
    NSError *err=nil;
    NSXMLDocument *refAlbumPage = [[NSXMLDocument alloc] initWithContentsOfURL:refAlbumUrl
                                                                 options:NSXMLDocumentTidyXML
                                                                   error:&err];
    
    // Get ref album's infos
    // Track list
    NSArray *refTrackNodes = [refAlbumPage nodesForXPath:@"//*[@id=\"idTrackList\"]/li" error:&err];
    assert([myTracks count] == [refTrackNodes count]);
    
    // Title
    NSArray *nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"container\"]/h2/text()" error:&err];
    assert([nodes count] == 1);
    NSString *refAlbumTitle = [nodes[0] description];
    
    // Artist
    nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[1]/strong/a/text()" error:&err];
    if([nodes count] != 1)  // when artist isn't linked
        nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[1]/strong/text()" error:&err];
    assert([nodes count] == 1);
    NSString *refAlbumArtist = [nodes[0] description];
    
    // Date
    nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[5]/text()" error:&err];
    assert([nodes count] == 1);
    NSInteger refAlbumDate = [[[nodes[0] description] substringToIndex:4] integerValue];
    
    refAlbum = [[RefAlbum alloc] initWithTitle:refAlbumTitle numOfMusic:[nodes count]];
    [refAlbum setArtist:refAlbumArtist];
    [refAlbum setYear:refAlbumDate];
    
    // Get ref track's infos
    for (NSXMLNode* refTrackNode in refTrackNodes)
    {
        // Title
        NSString* title = [[refTrackNode nodesForXPath:@"./dl/dt/a/@title" error:&err][0] stringValue];
        RefTrack *refTrack = [[RefTrack alloc] initWithTitle:title];
        
        // Get ref track page
        NSString* hrefStr = [[refTrackNode nodesForXPath:@"./dl/dt/a/@href" error:&err][0] stringValue];
        NSString* refTrackId = [[NSNumber numberWithInteger:[[hrefStr substringWithRange:NSMakeRange(35, 9)] integerValue]] stringValue];
        NSString* refTrackUrlStr = [NSString stringWithFormat:@"http://music.bugs.co.kr/track/%@", refTrackId];
        NSURL *refTrackUrl = [[NSURL alloc] initWithString:refTrackUrlStr];
        
        NSXMLDocument *refTrackPage = [[NSXMLDocument alloc] initWithContentsOfURL:refTrackUrl
                                                                        options:NSXMLDocumentTidyXML
                                                                          error:&err];
        
        // Lyric
        NSArray *refTrackLyricNodes = [refTrackPage nodesForXPath:@"//*[@id=\"content\"]/div[2]/p" error:&err];
        if([refTrackLyricNodes count] > 0)
        {
            assert([refTrackLyricNodes count] == 1);
            NSXMLNode *n = refTrackLyricNodes[0];
            NSArray *lines = [n children];
            
            NSMutableString* lyrics = [NSMutableString string];
            for(NSXMLNode *l in lines)
            {
                NSString* str = [l description];
                if([str compare:@"<br></br>"] == 0)
                    [lyrics appendString:@"\n"];
                else
                    [lyrics appendString:str];
            }
            NSString *trimedLyrics = [lyrics stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [refTrack setLyrics:trimedLyrics];
        }
        else
            [refTrack setLyrics:@""];
        
        // Artist
        NSArray *nodes = [refTrackPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/div/dl/dd[1]/strong/a/text()" error:&err];
        if([nodes count] != 1) // when artist isn't linked
            nodes = [refTrackPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/div/dl/dd[1]/strong/text()" error:&err];
        assert([nodes count] == 1);
        [refTrack setArtist:[nodes[0] description]];
        
        // Genre
        nodes = [refTrackPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/div/dl/dd[3]/text()" error:&err];
        assert([nodes count] == 1);
        [refTrack setGenre:[nodes[0] description]];
        
        [refAlbum.refTracks addObject:refTrack];
    }
    
    [self.tableView reloadData];
}



- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [refAlbum.refTracks count];
}

- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"CustomCell" owner:self];
    
    if (result == nil) {
        result = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, 418, 82)];
        [result setIdentifier:@"CustomCell"];
        
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
    iTunesFileTrack* track = self.myTracks[row];
    RefTrack *music = self.refAlbum.refTracks[row];
    NSNumber *select = self.willBeUpdated[row];
    
    UICheckBox *check = [result viewWithTag:10];
    [check setIndex:row];
    [check setState:[select integerValue]];
    [check setTarget:self];
    [check setAction:@selector(clickCheckBox:)];
    
    UILabel *label1 = [result viewWithTag:11];
    [label1 setStringValue:[track name]];
    
    UILabel *label2 = [result viewWithTag:12];
    [label2 setStringValue:[music name]];
    
    return result;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 82;
}



- (IBAction) clickCheckBox:(id)sender
{
    UICheckBox *check = sender;
    NSNumber* flag = self.willBeUpdated[[check index]];
    if([flag integerValue] == NSOnState)
        [self.willBeUpdated replaceObjectAtIndex:[check index] withObject:[NSNumber numberWithInteger:NSOffState]];
    else
        [self.willBeUpdated replaceObjectAtIndex:[check index] withObject:[NSNumber numberWithInteger:NSOnState]];
}

- (IBAction)updateTracks:(id)sender
{
    // Update informations
    for(NSInteger i = 0; i < [self.myTracks count]; ++i)
    {
        NSNumber* flag = self.willBeUpdated[i];
        if([flag integerValue] == NSOffState)
            continue;
        
        iTunesFileTrack* myTrack = self.myTracks[i];
        RefTrack* refTrack = self.refAlbum.refTracks[i];
        
        NSLog(@"변경: %@ -> %@", [myTrack name], [refTrack name]);
        
        [myTrack setName:[refTrack name]];
        [myTrack setLyrics:[refTrack lyrics]];
        [myTrack setArtist:[refTrack artist]];
        [myTrack setGenre:[refTrack genre]];
        [myTrack setAlbumArtist:[refAlbum artist]];
        [myTrack setYear:[refAlbum year]];
        [myTrack setAlbum:[refAlbum name]];
    }
}

@end
