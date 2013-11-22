//
//  AppDelegate.m
//  Lyrics
//
//  Created by Kim Seongjun on 13. 7. 27..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "AppDelegate.h"
#import "iTunes.h"

// Data structure
#import "MyAlbum.h"
#import "RefAlbum.h"
#import "RefTrack.h"

// UI
#import "TracksCellView.h"
#import "MyAlbumCellView.h"
#import "RefAlbumCandidatesCellView.h"

// Util
#import "NSString+HTML.h"

@implementation AppDelegate

@synthesize myAlbums;
@synthesize selectedMyAlbum;
@synthesize refAlbums;
@synthesize selectedRefAlbum;

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
    
    refAlbums = [[NSMutableArray alloc] initWithCapacity:[albumNodes count]];
    for (NSXMLNode* albumNode in albumNodes)
    {
        NSString* albumName = [[[albumNode nodesForXPath:@"./dl/dt/a/text()" error:&err][0] stringValue] kv_decodeHTMLCharacterEntities];
        NSString* albumArtist = [[[albumNode nodesForXPath:@"./dl/dd/a/@title" error:&err][0] stringValue] kv_decodeHTMLCharacterEntities];
        NSString* albumUrlStr = [[[albumNode nodesForXPath:@"./dl/dt/a/@href" error:&err][0] stringValue] kv_decodeHTMLCharacterEntities];
        NSString* albumYearStr = [[[albumNode nodesForXPath:@"./dl/dt/a/@href" error:&err][0] stringValue] kv_decodeHTMLCharacterEntities];
        NSInteger albumYear = [[albumYearStr substringToIndex:4] integerValue];
        [refAlbums addObject:[[RefAlbum alloc] initWithName:albumName artist:albumArtist year:albumYear urlStr:albumUrlStr]];
    }
    
    [self.refAlbumCandidatesTableView reloadData];
    
    /* TODO: 직접 사용자에게 input을 받을 수 있도록
    
    // Get ref album page's URL from user
    NSAlert *dialog = [NSAlert alertWithMessageText:@"앨범 URL을 입력해주세요." defaultButton:@"확인" alternateButton:@"취소" otherButton:nil informativeTextWithFormat:@"현재 벅스 사이트만 지원합니다."];
    NSTextField *userTextInput = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    [dialog setAccessoryView:userTextInput];
    NSInteger clicked = [dialog runModal];
    if (clicked == NSAlertDefaultReturn)
        return [userTextInput stringValue];
    else
        return nil;
     */
}

- (void)getRefTrackFromWeb:(RefTrack*)refTrack toRefAlbum:(RefAlbum*)newRefAlbum fromRefTrackUrl:(NSString*)refTrackUrlStr
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

- (void)reloadTracksTable
{
    NSString* refAlbumUrlStr = selectedRefAlbum.urlStr;
    NSURL *refAlbumUrl = [NSURL URLWithString:refAlbumUrlStr];
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
    selectedRefAlbum.name = refAlbumName;
    
    // Artist
    nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[1]/strong/a/text()" error:&err];
    if([nodes count] != 1)  // when artist isn't linked
        nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[1]/strong/text()" error:&err];
    assert([nodes count] == 1);
    NSString *refAlbumArtist = [[nodes[0] description] kv_decodeHTMLCharacterEntities];
    selectedRefAlbum.artist = refAlbumArtist;
    
    // Date
    nodes = [refAlbumPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[5]/text()" error:&err];
    assert([nodes count] == 1);
    NSInteger refAlbumDate = [[[nodes[0] description] substringToIndex:4] integerValue];
    selectedRefAlbum.year = refAlbumDate;
    
    // Get ref track's infos
    for (NSXMLNode* refTrackNode in refTrackNodes)
    {
        // trackNumber
        NSString* trackNumberStr = [[refTrackNode nodesForXPath:@"./dl/dt/a/text()" error:&err][0] stringValue];
        NSInteger trackNumber, discNumber;
        [self getTrackNumberFrom:trackNumberStr discNumber:&discNumber trackNumber:&trackNumber];
        BOOL isFound = false;
        for (iTunesFileTrack *track in selectedMyAlbum.tracks)
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
        NSString* refTrackUrlStr = [NSString stringWithFormat:@"http://music.bugs.co.kr/track/%@", refTrackId];
        [self getRefTrackFromWeb:refTrack toRefAlbum:selectedRefAlbum fromRefTrackUrl:refTrackUrlStr];
    }
    
    [self.tracksTableView reloadData];
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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self reloadMyAlbumTable];
}

// Table Data Source methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == self.refAlbumCandidatesTableView)
        return refAlbums.count;
    else if(aTableView == self.tracksTableView)
        return selectedMyAlbum.tracks.count;
    else
        assert(false);
}

- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *identifier = [tableColumn identifier];
    
    if(tableView == self.refAlbumCandidatesTableView)
    {
        assert([identifier isEqualToString:@"AlbumCell"]);
        
        RefAlbum* refAlbum_ = self.refAlbums[row];
        
        RefAlbumCandidatesCellView* cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        cellView.name.stringValue = refAlbum_.name;
        cellView.artist.stringValue = refAlbum_.artist;
        
        return cellView;
    }
    else if(tableView == self.tracksTableView)
    {
        assert([identifier isEqualToString:@"TrackCell"]);
        
        iTunesFileTrack* track = self.selectedMyAlbum.tracks[row];
        
        TracksCellView* cellView = [tableView makeViewWithIdentifier:identifier owner:self];
        cellView.name.stringValue = track.name;
        cellView.artist.stringValue = track.artist;
        
        return cellView;
    }
    else
        assert(false);
}

// Table Delegate methods
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSTableView* tableView = [aNotification object];
    NSInteger idx = [tableView selectedRow];
    
    if(tableView == self.refAlbumCandidatesTableView)
    {
        self.selectedRefAlbum = refAlbums[idx];
        NSLog(@"Candidate '%@' is selected", self.selectedRefAlbum.name);
        
        [self reloadTracksTable];
    }
    else if(tableView == self.tracksTableView)
    {
    }
    else
        assert(false);
}

// Outline Data Source methods
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if(item == nil)
        return myAlbums.count;
    
    MyAlbum* myAlbum = item;
    assert([myAlbum isKindOfClass:[MyAlbum class]]);
    
    return myAlbum.tracks.count;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if(item == nil) YES;
    
    MyAlbum* myAlbum = item;
    if([myAlbum isKindOfClass:[MyAlbum class]])
        return YES;
    else // iTunesFileTrack
        return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if(item == nil)
        return self.myAlbums[index];
    
    MyAlbum* myAlbum = item;
    assert([myAlbum isKindOfClass:[MyAlbum class]]);
    return myAlbum.tracks[index];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSString *identifier = [tableColumn identifier];
    
    if(item == nil) return nil;
    
    MyAlbum* myAlbum = item;
    if([myAlbum isKindOfClass:[MyAlbum class]])
    {
        assert([identifier isEqualToString:@"MainCell"]);
        
        MyAlbumCellView* cellView = [outlineView makeViewWithIdentifier:identifier owner:self];
        cellView.name.stringValue = myAlbum.name;
        cellView.version.stringValue = myAlbum.version;
        cellView.dateAdded.stringValue = [myAlbum.dateAdded descriptionWithCalendarFormat:@"%Y-%m-%d 추가" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
        
        return cellView;
    }
    
    // Row for 'iTunesFileTrack'
    iTunesFileTrack* track = item;
    assert([track isKindOfClass:[SBObject class]]);
    
    MyAlbumCellView* cellView = [outlineView makeViewWithIdentifier:identifier owner:self];
    cellView.name.stringValue = track.name;
    cellView.version.stringValue = @"";
    cellView.dateAdded.stringValue = track.artist;
    
    return cellView;
}

// Outline Delegate methods
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if (outlineView == self.myAlbumTableView)
    {
        MyAlbum* album = item;
        if([album isKindOfClass:[SBObject class]])
            return false; // disable selection on iTunesFileTrack
        
        assert([album isKindOfClass:[MyAlbum class]]);
        
        // Sort tracks by track no.
        NSSortDescriptor *discSortDesc = [[NSSortDescriptor alloc] initWithKey:@"discNumber" ascending:YES];
        NSSortDescriptor *trackSortDesc = [[NSSortDescriptor alloc] initWithKey:@"trackNumber" ascending:YES];
        [album.tracks sortUsingDescriptors:@[discSortDesc, trackSortDesc]];
        
        // 트랙 넘버가 중복되지 않는지 확인
        NSInteger prevDiscNum = -1;
        NSInteger prevTrackNum = -1;
        bool isSomeError = false;
        for (iTunesFileTrack *track in album.tracks)
        {
            if([track discNumber] == prevDiscNum && [track trackNumber] == prevTrackNum)
            {
                
                isSomeError = true;
                NSString *errMsg = [NSString stringWithFormat:@"'%@'의 트랙 번호가 이전 곡과 동일합니다.", [track name]];
                [self displayErrorMsgOfItunesSelection:errMsg];
                break;
            }
            prevDiscNum = [track discNumber];
            prevTrackNum = [track trackNumber];
        }
        
        return isSomeError == false;
    }
    else
    {
        assert(false);
        return true;
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSOutlineView* outlineView = [notification object];
    NSInteger idx = [outlineView selectedRow];
    
    if (outlineView == self.myAlbumTableView)
    {
        MyAlbum* myAlbum = self.myAlbums[idx];
        NSLog(@"Album '%@' is selected", myAlbum.name);
        
        self.selectedMyAlbum = myAlbum;
        
        [self reloadRefAlbumCandidatesTable:selectedMyAlbum.name];
    }
    else
        assert(false);
}


// IB action
- (IBAction)updateTracks:(id)sender
{
    // Update informations
    for(NSInteger i = 0; i < self.selectedMyAlbum.tracks.count; ++i)
    {
        iTunesFileTrack* myTrack = self.selectedMyAlbum.tracks[i];
        RefTrack* refTrack = self.selectedRefAlbum.refTracks[i];
        
        NSLog(@"변경: %@ -> %@", [myTrack name], [refTrack name]);
        
        [myTrack setName:[refTrack name]];
        [myTrack setLyrics:[refTrack lyrics]];
        [myTrack setArtist:[refTrack artist]];
        [myTrack setGenre:[refTrack genre]];
        [myTrack setAlbumArtist:self.selectedRefAlbum.artist];
        [myTrack setYear:self.selectedRefAlbum.year];
        [myTrack setAlbum:self.selectedRefAlbum.name];
        
        NSString* comment = [NSString stringWithFormat:@"%@\n%@", @"Ver.0.0.3", refTrack.urlStr];
        [myTrack setComment:comment];
    }
    
    NSAlert *dialog = [NSAlert alertWithMessageText:@"업데이트가 완료되었습니다." defaultButton:@"확인" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
    [dialog runModal];
    
    self.refAlbums = nil;
    self.selectedMyAlbum = nil;
    self.selectedRefAlbum = nil;
    [self reloadMyAlbumTable];
    [self.refAlbumCandidatesTableView reloadData];
    [self.tracksTableView reloadData];
}

// Version info
// 0.0.1 이름, 아티스트, 앨범 아티스트, 연도, 장르, 앨범 제목, 가사
// 0.0.2 decoding html character ex. &amp;
// 0.0.3 fix for ref track's url

@end
