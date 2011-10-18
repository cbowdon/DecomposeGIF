//
//  DecomposeGIFTests.m
//  DecomposeGIFTests
//
//  Created by Chris on 11-10-15.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "DecomposeGIFTests.h"

@implementation DecomposeGIFTests 
- (void)setUp
{
    [super setUp];
	
	filename = @"/Users/chris/Pictures/honeycakecoffee.gif";
	dg = [[DecomposeGIF alloc] initWithFile:filename];
	    
    // Set-up code here.	
}

- (void)tearDown
{
    // Tear-down code here.

    [super tearDown];
}

- (void)testPredicates {
	
	STAssertTrue([dg isGIF],@"Gif?");
	
	STAssertTrue([dg isHeader:0],@"Header at 0");
	
	STAssertFalse([dg isGCE:780],@"No GCE at 780");
	STAssertFalse([dg isGCE:114694],@"Exceeded EOF");
	STAssertFalse([dg isImage:780],@"No image descriptor at 780");
	STAssertFalse([dg isAppn:780],@"No application extension at 780");
	STAssertFalse([dg isComment:780],@"No comment at 780");
	STAssertFalse([dg isPlainText:780],@"No plain text at 780");	
	STAssertFalse([dg isTrailer:780],@"No trailer at 780");
	
	STAssertTrue([dg isGCE:800],@"GCE at 800");
	STAssertTrue([dg isImage:808],@"Image descriptor at 800");
	STAssertTrue([dg isAppn:781], @"Application extension at 781");
	STAssertTrue([dg isTrailer:114695], @"Trailer at 114695");
}

-(void)testSizes {
	
	STAssertEquals(781, [dg headerSize:0], @"Header size is 781");
	STAssertEquals(19, [dg appnSize:781], @"Application size is 19");
	STAssertEquals(8, [dg gceSize:800], @"GCE size is 8");
	STAssertEquals(29899, [dg imageSize:808], @"Image size is 29899");
}

@end
