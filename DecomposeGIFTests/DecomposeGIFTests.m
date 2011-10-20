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
	
	honey = [[DecomposeGIF alloc] initWithFile:@"/Users/chris/Pictures/honeycakecoffee.gif"];
	    
    // Set-up code here.	
}

- (void)tearDown
{
    // Tear-down code here.

    [super tearDown];
}

- (void)testPredicates {
	
	STAssertTrue([honey isGIF],@"Gif?");
	
	STAssertTrue([honey isHeader:0],@"Header at 0");
	
	STAssertFalse([honey isGCE:780],@"No GCE at 780");
	STAssertFalse([honey isGCE:114694],@"Exceeded EOF");
	STAssertFalse([honey isImage:780],@"No image descriptor at 780");
	STAssertFalse([honey isAppn:780],@"No application extension at 780");
	STAssertFalse([honey isComment:780],@"No comment at 780");
	STAssertFalse([honey isPlainText:780],@"No plain text at 780");	
	STAssertFalse([honey isTrailer:780],@"No trailer at 780");
	
	STAssertTrue([honey isGCE:800],@"GCE at 800");
	STAssertTrue([honey isImage:808],@"Image descriptor at 800");
	STAssertTrue([honey isAppn:781], @"Application extension at 781");
	STAssertTrue([honey isTrailer:114695], @"Trailer at 114695");
	
	STAssertTrue([honey isAnimated], @"Animated?");
}

-(void)testSizes {
	
	STAssertEquals(781, [honey headerSize:0], @"Header size is 781");
	STAssertEquals(19, [honey appnSize:781], @"Application size is 19");
	STAssertEquals(8, [honey gceSize:800], @"GCE size is 8");
	STAssertEquals(29899, [honey imageSize:808], @"Image 0 size is 29899");
	STAssertEquals(26999, [honey imageSize:30715], @"Image 1 size is 26999");
	STAssertEquals(23745, [honey imageSize:57722], @"Image 2 size is 23745");
	STAssertEquals(33220, [honey imageSize:81475], @"Image 3 size is 33220");
}

@end
