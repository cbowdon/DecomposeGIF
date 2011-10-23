//
//  DecomposeGIF.h
//  DecomposeGIF
//
//  Created by Chris on 11-10-15.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ByteBits.h"

@interface DecomposeGIF : NSObject {
	
	NSString *filename;
	// full contents of file: loaded in header
	NSData *contents;
	NSMutableDictionary *blockPositions;
	NSArray *sortedKeys;
	
}

// Properties are for external access
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSMutableDictionary *blockPositions;
@property (nonatomic, strong) NSArray *sortedKeys;
@property int width;
@property int height;

-(id)initWithFile:(NSString*)filepath;

// steps through contents, filling out blockPositions
-(NSMutableDictionary*)indexBlocks;

// helper functions
-(unsigned char)extractSingleByte:(int)byteNum;
-(unsigned short)extractShort:(int)byteNum;
-(int)subblocksSize:(int)byteNum;
-(int)findNextImage:(int)byteNum numImages:(int)n;
-(BOOL)writeDataToPNG:(NSData*)data toFile:(NSString*)name;

// predicates for recognising block types
-(BOOL)isGIF;
-(BOOL)isHeader:(int)byteNum;
-(BOOL)isGCE:(int)byteNum;
-(BOOL)isImage:(int)byteNum;
-(BOOL)isAppn:(int)byteNum;
-(BOOL)isComment:(int)byteNum;
-(BOOL)isPlainText:(int)byteNum;
-(BOOL)isTrailer:(int)byteNum;
-(BOOL)isExtension:(int)byteNum;
-(BOOL)isAnimated;

// methods for calculating block sizes
-(int)headerSize:(int)byteNum;
-(int)gceSize:(int)byteNum;
-(int)imageSize:(int)byteNum;
-(int)appnSize:(int)byteNum;
-(int)commentSize:(int)byteNum;
-(int)plainTextSize:(int)byteNum;

// output as png images
-(BOOL)makePNGs:(NSString*)inDir;

@end
