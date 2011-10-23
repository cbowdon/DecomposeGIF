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
	newton = [[DecomposeGIF alloc] initWithFile:@"/Users/chris/Pictures/Newtons_cradle_animation_book_2.gif"];
	    
}

- (void)tearDown
{
    // Tear-down code here.
	
	// delete pngs
	
    [super tearDown];
}

-(void)testHelpers {
	
	// findNextImage should return either accurate byte index, or zero
	STAssertEquals([honey findNextImage:0 numImages:1], 808, @"First image is at byte index 808");	
	STAssertEquals([honey findNextImage:0 numImages:2], 30715, @"Second image is at byte index 30715");	
	STAssertEquals([honey findNextImage:0 numImages:4], 81475, @"Fourth image is at byte index 81475");
	STAssertEquals([honey findNextImage:0 numImages:5], 0, @"Less than 5 images in honey");
	
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

-(void)testIndexer {
	
	STAssertEquals([honey.blockPositions objectForKey:[NSNumber numberWithInt:0]], @"Header", @"Byte 0 is header");
	STAssertEquals([honey.blockPositions objectForKey:[NSNumber numberWithInt:781]], @"Application Extension", @"Byte 781 is appn");
	STAssertEquals([honey.blockPositions objectForKey:[NSNumber numberWithInt:800]], @"Graphic Control Extension", @"Byte 800 is GCE");
	STAssertEquals([honey.blockPositions objectForKey:[NSNumber numberWithInt:808]], @"Image Descriptor", @"Byte 808 is img");
	STAssertEquals([honey.blockPositions objectForKey:[NSNumber numberWithInt:30707]], @"Graphic Control Extension", @"Byte 30707 is GCE");
	STAssertEquals([honey.blockPositions objectForKey:[NSNumber numberWithInt:30715]], @"Image Descriptor", @"Byte 30715 is img");
	STAssertEquals([honey.blockPositions objectForKey:[NSNumber numberWithInt:57714]], @"Graphic Control Extension", @"Byte 57714 is GCE");
	STAssertEquals([honey.blockPositions objectForKey:[NSNumber numberWithInt:57722]], @"Image Descriptor", @"Byte 57722 is img");
	STAssertEquals([honey.blockPositions objectForKey:[NSNumber numberWithInt:81467]], @"Graphic Control Extension", @"Byte 81467 is GCE");
	STAssertEquals([honey.blockPositions objectForKey:[NSNumber numberWithInt:81475]], @"Image Descriptor", @"Byte 81475 is img");	
	STAssertEquals([honey.blockPositions objectForKey:[NSNumber numberWithInt:114695]], @"Trailer", @"Byte 114695 is trailer");
}

-(void)testMakePNGs {
	
	// Should check that all the right PNG files were made
	NSString *testDir = @"/Users/chris/Desktop/";
	NSFileManager *fileMan = [NSFileManager defaultManager];
	
	STAssertTrue([honey makePNGs:testDir withName:@"test"], @"Did it work?");
	
	NSPredicate *pngFilter = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", @".png"];
	NSArray *output = [[fileMan contentsOfDirectoryAtPath:testDir error:nil] filteredArrayUsingPredicate:pngFilter];
	
	STAssertEquals([output count], (uint)4, @"Should be four images in honey");	
	
	uint i;
	for (i = 0; i < [output count]; i++) {
		NSString *fileName = [NSString stringWithFormat:@"test-%i.png", i];
		STAssertTrue([[output objectAtIndex:i] isEqualToString:fileName], @"Right filename/number");
		[fileMan removeItemAtPath:[testDir stringByAppendingString:[output objectAtIndex:i]] error:nil];
	}
	
	// test transparency
	//[newton makePNGs:testDir withName:@"newton"];
	
}

@end
