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

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Get selected tracks
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    NSArray *sel = [[iTunes selection] get];
    NSUInteger nSel = [sel count];
    
    NSMutableArray* tracks = [[NSMutableArray alloc] initWithCapacity:nSel];
    for (iTunesFileTrack* f in sel)
    {
        [tracks addObject:f];
    }
    NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"trackNumber" ascending:YES];
    NSArray *sortDescs = [NSArray arrayWithObject:sortDesc];
    [tracks sortUsingDescriptors:sortDescs];
    assert(nSel == [tracks count]);
    
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
    
    Album *album = [[Album alloc] initWithTitle:@"test" numOfMusic:[nodes count]];
    
    for (NSXMLNode* n in nodes)
    {
        // Title
        NSString* title = [[n nodesForXPath:@"./dl/dt/a/@title" error:&err][0] stringValue];
        Music *music = [[Music alloc] initWithTitle:title];
        
        
        // Lyric
        NSString* hrefStr = [[n nodesForXPath:@"./dl/dt/a/@href" error:&err][0] stringValue];
        NSString* musicId = [hrefStr substringWithRange:NSMakeRange(35, 7)];
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
        assert([nodes count] == 1);
        [music setArtist:[nodes[0] description]];
        
        // Genre
        nodes = [musicPage nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/div/dl/dd[3]/text()" error:&err];
        assert([nodes count] == 1);
        [music setGenre:[nodes[0] description]];
        
        [album.musics addObject:music];
    }
    
    // Get album artist
    nodes = [xmlDoc nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[1]/strong/text()" error:&err];
    assert([nodes count] == 1);
    [album setArtist:[nodes[0] description]];
    
    // Get issue date
    nodes = [xmlDoc nodesForXPath:@"//*[@id=\"content\"]/div[1]/div[2]/div[2]/dl/dd[5]/text()" error:&err];
    assert([nodes count] == 1);
    [album setYear:[[[nodes[0] description] substringToIndex:4] integerValue]];
    
    
    // Update informations
    for(NSInteger i = 0; i < [tracks count]; ++i)
    {
        iTunesFileTrack* track = tracks[i];
        Music* music = album.musics[i];
        
        NSString *msg = [NSString stringWithFormat:@"%@ -> %@", [track name], [music title]];
        NSAlert *dialog = [NSAlert alertWithMessageText:@"다음 곡 정보로 변경하겠습니까?" defaultButton:@"확인" alternateButton:@"취소" otherButton:nil informativeTextWithFormat:msg];
        NSInteger button = [dialog runModal];
        if (button == NSAlertDefaultReturn)
        {
            NSLog(@"변경 %@ -> %@", [track name], [music title]);
            
            [track setName:[music title]];
            [track setLyrics:[music lyric]];
            [track setArtist:[music artist]];
            [track setGenre:[music genre]];
            [track setAlbumArtist:[album artist]];
            [track setYear:[album year]];
        }
    }
}

@end
