//
//  AppDelegate.m
//  Lyrics
//
//  Created by Kim Seongjun on 13. 7. 27..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "AppDelegate.h"
#import "Album.h"
#import "Music.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Get album page
    NSURL *url = [[NSURL alloc] initWithString:@"http://music.bugs.co.kr/album/324696"];
    NSError *err=nil;
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:url
                                                                 options:NSXMLDocumentTidyXML
                                                                   error:&err];
    
    // Get list of song
    NSArray *nodes = [xmlDoc nodesForXPath:@"//*[@id=\"idTrackList\"]/li" error:&err];
    
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
        
        [album.musics addObject:music];
    }
    
    // TEST
    NSLog(@"Album - %@", [album description]);
    for (Music* m in [album musics])
    {
        NSLog(@"Music - %@",[m description]);
    }
}

@end
