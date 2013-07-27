//
//  AppDelegate.m
//  Lyrics
//
//  Created by Kim Seongjun on 13. 7. 27..
//  Copyright (c) 2013년 Kim Seongjun. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    NSURL *url = [[NSURL alloc] initWithString:@"http://music.bugs.co.kr/album/324696"];
    NSError *err=nil;
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:url
                                                                 options:NSXMLDocumentTidyXML
                                                                 error:&err];
    
    NSArray *nodes = [xmlDoc nodesForXPath:@"//*[@id=\"idTrackList\"]/li" error:&err];
    
    for (NSXMLNode* n in nodes)
    {
        NSXMLNode* d = [n nodesForXPath:@"./dl/dt/a/@title" error:&err][0];
        NSLog(d.stringValue);
    }
        
}

@end
