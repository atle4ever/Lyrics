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
        NSXMLNode* title = [n nodesForXPath:@"./dl/dt/a/@title" error:&err][0];
        Music *music = [[Music alloc] initWithTitle:title.stringValue];
        
        // Lyric
        
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
