//
//  AppDelegate.m
//  Lyrics
//
//  Created by Kim Seongjun on 13. 7. 27..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "AppDelegate.h"
#import "RefAlbumSelector.h"
#import "iTunes.h"
#import "MyAlbum.h"
#import "RefAlbum.h"
#import "RefAlbumCandidatesCellView.h"
#import "TracksCellView.h"
#import "RefAlbumCandidate.h"
#import "RefTrack.h"
#import "UICheckBox.h"
#import "UILabel.h"
#import "NSString+HTML.h"
#import "MyAlbumCellView.h"

@implementation AppDelegate

@synthesize refAlbum;
@synthesize myTracks;
@synthesize myAlbums;
@synthesize refAlbumCandidates;
@synthesize willBeUpdated;
@synthesize refTrackUrlStr;

- (void)displayErrorMsgOfItunesSelection:(NSString*) msg
{
    NSAlert *dialog = [NSAlert alertWithMessageText:msg defaultButton:@"다시 시도" alternateButton:@"종료" otherButton:nil informativeTextWithFormat:@""];
    if([dialog runModal] != NSAlertDefaultReturn)
        [[NSApplication sharedApplication] terminate:nil];
}

- (void)reloadMyAlbumTable
{
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    NSArray* playlists = [[[[iTunes sources] get][0] playlists] get];
    iTunesPlaylist* musics = nil;
    for(iTunesPlaylist* pl in playlists)
    {
        if([[pl name]  isEqual: @"음악"])
        {
            musics = pl;
            break;
        }
    }
    assert(musics != nil);
    
    myAlbums = [[NSMutableArray alloc] init];
    for(iTunesFileTrack* track in [[musics tracks] get])
    {
        NSString* albumName = [track album];
        MyAlbum* album = nil;
        for(MyAlbum* candidate in myAlbums)
        {
            if([[candidate name] isEqualToString:albumName])
            {
                album = candidate;
                break;
            }
        }
        
        if(album == nil)
        {
            album = [[MyAlbum alloc] init];
            [album setName:albumName];
            [album setDateAdded:[track dateAdded]];
            [myAlbums addObject:album];
        }
        assert(album != nil);
        [album addTrack:track];
    }
    
    NSSortDescriptor *dateAddedSortDesc = [[NSSortDescriptor alloc] initWithKey:@"dateAdded" ascending:NO];
    [myAlbums sortUsingDescriptors:@[dateAddedSortDesc]];
    
    [self.myAlbumTableView reloadData];
}

- (void)reloadRefAlbumCandidatesTable:(NSString*)aAlbumName
{
    NSString* albumSearchUrlStr = [NSString stringWithFormat:@"http://search.bugs.co.kr/album?q=%@",aAlbumName];
    NSURL *albumSearchUrl = [[NSURL alloc] initWithString:[albumSearchUrlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSError *err=nil;
    NSXMLDocument *albumSearchPage = [[NSXMLDocument alloc] initWithContentsOfURL:albumSearchUrl
                                                                          options:NSXMLDocumentTidyXML
                                                                            error:&err];
    
    // Album list
    NSArray *albumNodes = [albumSearchPage nodesForXPath:@"//*[@id=\"content\"]/div/ul/li" error:&err];
    
    refAlbumCandidates = [[NSMutableArray alloc] initWithCapacity:[albumNodes count]];
    for (NSXMLNode* albumNode in albumNodes)
    {
        NSString* albumName = [[[albumNode nodesForXPath:@"./dl/dt/a/text()" error:&err][0] stringValue] kv_decodeHTMLCharacterEntities];
        NSString* albumArtist = [[[albumNode nodesForXPath:@"./dl/dd/a/@title" error:&err][0] stringValue] kv_decodeHTMLCharacterEntities];
        NSString* albumUrlStr = [[[albumNode nodesForXPath:@"./dl/dt/a/@href" error:&err][0] stringValue] kv_decodeHTMLCharacterEntities];
        [refAlbumCandidates addObject:[[RefAlbumCandidate alloc] initWithName:albumName artist:albumArtist urlStr:albumUrlStr]];
    }
    
    [self.refAlbumCandidatesTableView reloadData];
}

- (void)reloadTracksTable:(NSString*)refAlbumUrlStr
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
    NSString *refAlbumName = [[nodes[0] description] kv_decodeHTMLCharacterEntities];
    
    // Artist
    nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[1]/strong/a/text()" error:&err];
    if([nodes count] != 1)  // when artist isn't linked
        nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[1]/strong/text()" error:&err];
    assert([nodes count] == 1);
    NSString *refAlbumArtist = [[nodes[0] description] kv_decodeHTMLCharacterEntities];
    
    // Date
    nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[5]/text()" error:&err];
    assert([nodes count] == 1);
    NSInteger refAlbumDate = [[[nodes[0] description] substringToIndex:4] integerValue];
    
    refAlbum = [[RefAlbum alloc] initWithName:refAlbumName numOfMusic:[nodes count]];
    [refAlbum setArtist:refAlbumArtist];
    [refAlbum setYear:refAlbumDate];
    
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
        NSString* name = [[[refTrackNode nodesForXPath:@"./dl/dt/a/@title" error:&err][0] stringValue] kv_decodeHTMLCharacterEntities];
        RefTrack *refTrack = [[RefTrack alloc] initWithName:name];
        
        // Get ref track page
        NSString* hrefStr = [[refTrackNode nodesForXPath:@"./dl/dt/a/@href" error:&err][0] stringValue];
        NSString* refTrackId = [[NSNumber numberWithInteger:[[hrefStr substringWithRange:NSMakeRange(35, 9)] integerValue]] stringValue];
        [self setRefTrackUrlStr:[NSString stringWithFormat:@"http://music.bugs.co.kr/track/%@", refTrackId]];
        [self getRefTrackFromWeb:refTrack toRefAlbum:refAlbum];
    }
    
    [self.tracksTableView reloadData];
}

- (void)getMyTracksFromItunes
{
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    NSArray* playlists = [[[[iTunes sources] get][0] playlists] get];
    iTunesPlaylist* musics = nil;
    for(iTunesPlaylist* pl in playlists)
    {
        if([[pl name]  isEqual: @"음악"])
        {
            musics = pl;
            break;
        }
    }
    assert(musics != nil);
    
    myAlbums = [[NSMutableArray alloc] init];
    for(iTunesFileTrack* track in [[musics tracks] get])
    {
        NSString* albumName = [track album];
        MyAlbum* album = nil;
        for(MyAlbum* candidate in myAlbums)
        {
            if([[candidate name] isEqualToString:albumName])
            {
                album = candidate;
                break;
            }
        }
        
        if(album == nil)
        {
            album = [[MyAlbum alloc] init];
            [album setName:albumName];
            [album setDateAdded:[track dateAdded]];
            [myAlbums addObject:album];
        }
        assert(album != nil);
        [album addTrack:track];
    }
    
    NSSortDescriptor *dateAddedSortDesc = [[NSSortDescriptor alloc] initWithKey:@"dateAdded" ascending:NO];
    [myAlbums sortUsingDescriptors:@[dateAddedSortDesc]];
    
    [self.myAlbumTableView reloadData];
    
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

- (void)getRefTrackFromWeb:(RefTrack*)refTrack toRefAlbum:(RefAlbum*)newRefAlbum
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
                [lyrics appendString:[str kv_decodeHTMLCharacterEntities]];
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
    [refTrack setArtist:[[nodes[0] description] kv_decodeHTMLCharacterEntities]];
    
    // Genre
    nodes = [refTrackPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/div/dl/dd[3]/text()" error:&err];
    if([nodes count] == 0)
        [refTrack setGenre:@""];
    else
        [refTrack setGenre:[[nodes[0] description] kv_decodeHTMLCharacterEntities]];
    
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
    NSString *refAlbumName = [[nodes[0] description] kv_decodeHTMLCharacterEntities];
    
    // Artist
    nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[1]/strong/a/text()" error:&err];
    if([nodes count] != 1)  // when artist isn't linked
        nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[1]/strong/text()" error:&err];
    assert([nodes count] == 1);
    NSString *refAlbumArtist = [[nodes[0] description] kv_decodeHTMLCharacterEntities];
    
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
        NSString* name = [[[refTrackNode nodesForXPath:@"./dl/dt/a/@title" error:&err][0] stringValue] kv_decodeHTMLCharacterEntities];
        RefTrack *refTrack = [[RefTrack alloc] initWithName:name];
        
        // Get ref track page
        NSString* hrefStr = [[refTrackNode nodesForXPath:@"./dl/dt/a/@href" error:&err][0] stringValue];
        NSString* refTrackId = [[NSNumber numberWithInteger:[[hrefStr substringWithRange:NSMakeRange(35, 9)] integerValue]] stringValue];
        [self setRefTrackUrlStr:[NSString stringWithFormat:@"http://music.bugs.co.kr/track/%@", refTrackId]];
        [self getRefTrackFromWeb:refTrack toRefAlbum:newRefAlbum];
    }
    
    return newRefAlbum;
}

- (NSString*)getRefAlbumUrl
{
    NSString* albumSearchUrlStr = [NSString stringWithFormat:@"http://search.bugs.co.kr/album?q=%@",((iTunesFileTrack*)myTracks[0]).artist];
    NSURL *albumSearchUrl = [[NSURL alloc] initWithString:[albumSearchUrlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSError *err=nil;
    NSXMLDocument *albumSearchPage = [[NSXMLDocument alloc] initWithContentsOfURL:albumSearchUrl
                                                                 options:NSXMLDocumentTidyXML
                                                                   error:&err];
    
    // Album list
    NSArray *albumNodes = [albumSearchPage nodesForXPath:@"//*[@id=\"content\"]/div/ul/li" error:&err];
    
    NSMutableArray* refAlbumCandidates = [[NSMutableArray alloc] initWithCapacity:[albumNodes count]];
    for (NSXMLNode* albumNode in albumNodes)
    {
        NSString* albumName = [[[albumNode nodesForXPath:@"./dl/dt/a/text()" error:&err][0] stringValue] kv_decodeHTMLCharacterEntities];
        NSString* albumArtist = [[[albumNode nodesForXPath:@"./dl/dd/a/@title" error:&err][0] stringValue] kv_decodeHTMLCharacterEntities];
        NSString* albumUrlStr = [[[albumNode nodesForXPath:@"./dl/dt/a/@href" error:&err][0] stringValue] kv_decodeHTMLCharacterEntities];
        [refAlbumCandidates addObject:[[RefAlbumCandidate alloc] initWithName:albumName artist:albumArtist urlStr:albumUrlStr]];
    }
    
    RefAlbumSelector* refAlbumSelector = [[RefAlbumSelector alloc] initWithWindowNibName:@"RefAlbumSelector"];
    [refAlbumSelector setRefAlbumCandidates:refAlbumCandidates];
    [[NSApplication sharedApplication] runModalForWindow:refAlbumSelector.window];
    
    if(refAlbumSelector.selected >= 0)
    {
        RefAlbumCandidate* candidate = refAlbumCandidates[refAlbumSelector.selected];
        return candidate.urlStr;
    }
    
    // Get ref album page's URL from user
    NSAlert *dialog = [NSAlert alertWithMessageText:@"앨범 URL을 입력해주세요." defaultButton:@"확인" alternateButton:@"취소" otherButton:nil informativeTextWithFormat:@"현재 벅스 사이트만 지원합니다."];
    NSTextField *userTextInput = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    [dialog setAccessoryView:userTextInput];
    NSInteger clicked = [dialog runModal];
    if (clicked == NSAlertDefaultReturn)
        return [userTextInput stringValue];
    else
        return nil;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self reloadMyAlbumTable];
    // [self getMyTracksFromItunes];
    
    // NSString *refAlbumUrlStr;
    // while(true)
    // {
    //     refAlbumUrlStr = [self getRefAlbumUrl];
    //     [self.window display];
    //     if(refAlbumUrlStr == nil)
    //         [[NSApplication sharedApplication] terminate:nil];
        
    //     // Get album page
    //     [self setRefAlbum:[self getRefAlbumFromWeb:refAlbumUrlStr]];
        
    //     if([self.myTracks count] == [self.refAlbum.refTracks count])
    //         break;
    //     else
    //     {
    //         NSAlert *dialog = [NSAlert alertWithMessageText:@"틀린 앨범입니다. 다시 선택해주세요." defaultButton:@"확인" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    //         [dialog runModal];
    //     }
    // }
    
    // Create array for selected
    NSInteger nSel = [self.myTracks count];
    willBeUpdated = [[NSMutableArray alloc] initWithCapacity:nSel];
    for(int i = 0; i < nSel; ++i)
        [willBeUpdated addObject:[NSNumber numberWithInt:NSOnState]];
    
    [self.tableView reloadData];
}



- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == self.tableView)
        return [refAlbum.refTracks count];
    else if(aTableView == self.myAlbumTableView)
        return myAlbums.count;
    else if(aTableView == self.refAlbumCandidatesTableView)
        return refAlbumCandidates.count;
    else if(aTableView == self.tracksTableView)
        return myTracks.count;
    else
        assert(false);
}

- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *identifier = [tableColumn identifier];
    
    if (tableView == self.myAlbumTableView)
    {
        assert([identifier isEqualToString:@"MainCell"]);
        
        MyAlbum* album = self.myAlbums[row];
        
        MyAlbumCellView* cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        cellView.name.stringValue = album.name;
        cellView.dateAdded.stringValue = album.dateAdded.description;
        
        return cellView;
    }
    else if(tableView == self.refAlbumCandidatesTableView)
    {
        assert([identifier isEqualToString:@"AlbumCell"]);
        
        RefAlbum* refAlbum = self.refAlbumCandidates[row];
        
        RefAlbumCandidatesCellView* cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        cellView.name.stringValue = refAlbum.name;
        cellView.artist.stringValue = refAlbum.artist;
        
        return cellView;
    }
    else if(tableView == self.tracksTableView)
    {
        assert([identifier isEqualToString:@"TrackCell"]);
        
        iTunesFileTrack* track = self.myTracks[row];
        
        TracksCellView* cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        cellView.name.stringValue = track.name;
        cellView.artist.stringValue = track.artist;
        
        return cellView;
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSTableView* tableView = [aNotification object];
    NSInteger idx = [tableView selectedRow];
    
    if (tableView == self.myAlbumTableView)
    {
        MyAlbum* album = self.myAlbums[idx];
        NSLog(@"Album '%@' is selected", album.name);
        
        NSSortDescriptor *trackNumberSortDesc = [[NSSortDescriptor alloc] initWithKey:@"trackNumber" ascending:YES];
        [album.tracks sortUsingDescriptors:@[trackNumberSortDesc]];
        [album setDiscNumber];
        self.myTracks = album.tracks;
        
        [self reloadRefAlbumCandidatesTable:album.name];
    }
    else if(tableView == self.refAlbumCandidatesTableView)
    {
        RefAlbumCandidate* candidate = refAlbumCandidates[idx];
        NSLog(@"Candidate '%@' is selected", candidate.name);
        
        [self reloadTracksTable:candidate.urlStr];
    }
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
        
        NSString* comment = [NSString stringWithFormat:@"%@\n%@", @"Ver.0.0.2", refTrackUrlStr];
        [myTrack setComment:comment];
    }
    
    NSAlert *dialog = [NSAlert alertWithMessageText:@"업데이트가 완료되었습니다." defaultButton:@"확인" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [dialog runModal];
}

// Version info
// 0.0.1 이름, 아티스트, 앨범 아티스트, 연도, 장르, 앨범 제목, 가사
// 0.0.2 decoding html character ex. &amp;

@end
