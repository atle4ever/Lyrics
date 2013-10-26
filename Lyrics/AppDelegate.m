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

- (void)displayErrorMsgOfItunesSelection:(NSString*) msg
{
    NSAlert *dialog = [NSAlert alertWithMessageText:msg defaultButton:@"다시 시도" alternateButton:@"종료" otherButton:nil informativeTextWithFormat:@""];
    if([dialog runModal] != NSAlertDefaultReturn)
        [[NSApplication sharedApplication] terminate:nil];
}

- (void)getMyTracksFromItunes
{
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    while(true)
    {
        myTracks = [[iTunes selection] get];
        if([myTracks count] == 0)
        {
            [self displayErrorMsgOfItunesSelection:@"아이튠즈에서 업데이트할 곡을 선택해주세요."];
            continue;
        }
        
        // 디스크 넘버 확인
        for (iTunesFileTrack *track in myTracks)
            if([track discNumber] == 0)
                [track setDiscNumber:1];
        
        // 모든 곡이 동일한 앨범에 속해 있는지 확인
        bool isSomeError = true;
        NSString *albumTitle = [[myTracks objectAtIndex:0] album];
        for (iTunesFileTrack *track in myTracks)
        {
            if([[track album] compare:albumTitle] != 0)
            {
                isSomeError = false;
                [self displayErrorMsgOfItunesSelection:@"같은 앨범의 곡을 선택해주세요."];
                break;
            }
        }
        if(isSomeError == false) continue;
        
        // Sort tracks by track no.
        NSSortDescriptor *discSortDesc = [[NSSortDescriptor alloc] initWithKey:@"discNumber" ascending:YES];
        NSSortDescriptor *trackSortDesc = [[NSSortDescriptor alloc] initWithKey:@"trackNumber" ascending:YES];
        [myTracks sortUsingDescriptors:@[discSortDesc, trackSortDesc]];
        
        // 트랙 넘버가 중복되지 않는지 확인
        NSInteger prevDiscNum = -1;
        NSInteger prevTrackNum = -1;
        for (iTunesFileTrack *track in myTracks)
        {
            if([track discNumber] == prevDiscNum && [track trackNumber] == prevTrackNum)
            {
                
                isSomeError = false;
                NSString *errMsg = [NSString stringWithFormat:@"'%@'의 트랙 번호가 이전 곡과 동일합니다.", [track name]];
                [self displayErrorMsgOfItunesSelection:errMsg];
                break;
            }
            prevDiscNum = [track discNumber];
            prevTrackNum = [track trackNumber];
        }
        if(isSomeError == false) continue;
        
        break;
    }
}

- (void)getRefTrackFromWeb:(RefTrack*)refTrack withUrl:(NSString*)refTrackUrlStr toRefAlbum:(RefAlbum*)newRefAlbum
{
    NSError* err = nil;
    
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
    if([nodes count] == 0)
        [refTrack setGenre:@""];
    else
        [refTrack setGenre:[nodes[0] description]];
    
    [newRefAlbum.refTracks addObject:refTrack];
}

- (void)getTrackNumberFrom:(NSString*)trackNumberStr discNumber:(NSInteger*)discNumber trackNumber:(NSInteger*)trackNumber
{
    unichar ch0 = [trackNumberStr characterAtIndex:0];
    unichar ch1 = [trackNumberStr characterAtIndex:1];
    unichar ch2 = [trackNumberStr characterAtIndex:2];
    
    if((ch0 >= '0' && ch0 <= '9') && (ch1 >= '0' && ch1 <= '9') && (ch2 == '.'))
    {
        // 1 disc. ex> 01. XXX
        *discNumber = 1;
        *trackNumber = [trackNumberStr intValue];
    }
    else
    {
        // multiple disc. ex> 1 - 01. XXX
        *discNumber = [trackNumberStr intValue];
        *trackNumber = [[trackNumberStr substringFromIndex:4] intValue];
    }
}

- (RefAlbum*)getRefAlbumFromWeb:(NSString*)refAlbumUrlStr
{
    NSURL *refAlbumUrl = [[NSURL alloc] initWithString:refAlbumUrlStr];
    NSError *err=nil;
    NSXMLDocument *refAlbumPage = [[NSXMLDocument alloc] initWithContentsOfURL:refAlbumUrl
                                                                 options:NSXMLDocumentTidyXML
                                                                   error:&err];
    
    // Get ref album's infos
    // Track list
    NSArray *refTrackNodes = [refAlbumPage nodesForXPath:@"//*[@id=\"idTrackList\"]/li" error:&err];
    
    // Title
    NSArray *nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"container\"]/h2/text()" error:&err];
    assert([nodes count] == 1);
    NSString *refAlbumName = [nodes[0] description];
    
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
    
    RefAlbum* newRefAlbum = [[RefAlbum alloc] initWithName:refAlbumName numOfMusic:[nodes count]];
    [newRefAlbum setArtist:refAlbumArtist];
    [newRefAlbum setYear:refAlbumDate];
    
    // Get ref track's infos
    for (NSXMLNode* refTrackNode in refTrackNodes)
    {
        // trackNumber
        NSString* trackNumberStr = [[refTrackNode nodesForXPath:@"./dl/dt/a/text()" error:&err][0] stringValue];
        NSInteger trackNumber, discNumber;
        [self getTrackNumberFrom:trackNumberStr discNumber:&discNumber trackNumber:&trackNumber];
        BOOL isFound = false;
        for (iTunesFileTrack *track in myTracks)
        {
            if([track discNumber] == discNumber && [track trackNumber] == trackNumber)
            {
                isFound = true;
                break;
            }
        }
        if(isFound == false) continue;
        
        // Title
        NSString* name = [[refTrackNode nodesForXPath:@"./dl/dt/a/@title" error:&err][0] stringValue];
        RefTrack *refTrack = [[RefTrack alloc] initWithName:name];
        
        // Get ref track page
        NSString* hrefStr = [[refTrackNode nodesForXPath:@"./dl/dt/a/@href" error:&err][0] stringValue];
        NSString* refTrackId = [[NSNumber numberWithInteger:[[hrefStr substringWithRange:NSMakeRange(35, 9)] integerValue]] stringValue];
        NSString* refTrackUrlStr = [NSString stringWithFormat:@"http://music.bugs.co.kr/track/%@", refTrackId];
        [self getRefTrackFromWeb:refTrack withUrl:refTrackUrlStr toRefAlbum:newRefAlbum];
    }
    
    return newRefAlbum;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self getMyTracksFromItunes];
    
    NSInteger nSel = [self.myTracks count];
    
    // Create array for selected
    willBeUpdated = [[NSMutableArray alloc] initWithCapacity:nSel];
    for(int i = 0; i < nSel; ++i)
        [willBeUpdated addObject:[NSNumber numberWithInt:NSOnState]];
    
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
    [self setRefAlbum:[self getRefAlbumFromWeb:refAlbumUrlStr]];
    
    assert([self.myTracks count] == [self.refAlbum.refTracks count]);
    
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
    
    NSAlert *dialog = [NSAlert alertWithMessageText:@"업데이트가 완료되었습니다." defaultButton:@"확인" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [dialog runModal];
}

@end
