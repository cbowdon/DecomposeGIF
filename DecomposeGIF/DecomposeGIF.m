//
//  DecomposeGIF.m
//  DecomposeGIF
//
//  Created by Chris on 11-10-15.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "DecomposeGIF.h"

@implementation DecomposeGIF

@synthesize filename, width, height;

-(id)initWithFile:(NSString*)filepath
{
    self = [super init];
    if (self) {
        // Initialization code here.
		self.filename = [filepath copy];
		contents = [NSData dataWithContentsOfFile:self.filename];
		self.width = [self extractShort:6];
		self.height = [self extractShort:8];
		blockPositions = [self indexBlocks];
		
    }    
    return self;
}

// helper functions

-(unsigned char)extractSingleByte:(int)byteNum {
	unsigned char ans[1];
	NSRange rangeOfOne = {byteNum, 1};
	[contents getBytes:ans range:rangeOfOne];
	return ans[0];	
}

-(unsigned short)extractShort:(int)byteNum {
	unsigned char ans[2];
	NSRange rangeOfTwo = {byteNum, 2};
	[contents getBytes:ans range:rangeOfTwo];
	return (int)ans[0]+256*(int)ans[1];
}

// index the GIF blocks

-(NSMutableDictionary*)indexBlocks {
	return [NSMutableDictionary dictionaryWithCapacity:0];
}

// predicates

-(BOOL)isGIF {	
	return NO;
}

-(BOOL)isHeader:(int)byteNum {
	if ([contents length] < byteNum+6) {
		return NO;
	}
	NSRange rangeOfSix = {byteNum, 6};
	unsigned char buffer[6];
	[contents getBytes:buffer range:rangeOfSix];
	NSString *title = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	if ([title isEqualToString:@"GIF87a"] ||
		[title isEqualToString:@"GIF89a"]) {
		return YES;
	} else {
		return NO;
	}
}

-(BOOL)isGCE:(int)byteNum {
	if ([contents length] < byteNum+7) {
		return NO;
	}
	int b0 = (int)[self extractSingleByte:byteNum];
	int b1 = (int)[self extractSingleByte:byteNum+1];
	int b2 = (int)[self extractSingleByte:byteNum+2];
	int b7 = (int)[self extractSingleByte:byteNum+7];
	if (b0 == 33 && 
		b1 == 249 && 
		b2 == 4 && 
		b7 == 0) {
		return YES;
	} else {
		return NO;
	}
}

-(BOOL)isImage:(int)byteNum {
	if ([contents length] < byteNum+9) {
		return NO;
	}
	int b0 = (int)[self extractSingleByte:byteNum];
	short imgX = [self extractShort:byteNum+5];
	short imgY = [self extractShort:byteNum+7];
	short imgX0 = [self extractShort:byteNum+1];
	short imgY0 = [self extractShort:byteNum+3];	
	if (b0 == 44 &&
		imgX <= self.width &&
		imgY <= self.height &&
		imgX0 <= self.width &&
		imgY0 <= self.height) {
		return YES;
	} else {
		return NO;
	}
}

-(BOOL)isAppn:(int)byteNum {
	if ([contents length] < byteNum+16) {
		return NO;
	}
	int b0 = (int)[self extractSingleByte:byteNum];
	int b1 = (int)[self extractSingleByte:byteNum+1];
	int b2 = (int)[self extractSingleByte:byteNum+2];
	if (b0 == 33 &&
		b1 == 255 &&
		b2 == 11) {
		return YES;
	} else {
		return NO;
	}
}

-(BOOL)isComment:(int)byteNum {
	if ([contents length] < byteNum+2) {
		return NO;
	}
	int b0 = (int)[self extractSingleByte:byteNum];
	int b1 = (int)[self extractSingleByte:byteNum+1];
	if (b0 == 33 &&
		b1 == 254) {
		return YES;
	} else {
		return NO;
	}
}

-(BOOL)isPlainText:(int)byteNum {
	if ([contents length] < byteNum+3) {
		return NO;
	}
	int b0 = (int)[self extractSingleByte:byteNum];
	int b1 = (int)[self extractSingleByte:byteNum+1];
	int b2 = (int)[self extractSingleByte:byteNum+2];
	if (b0 == 33 &&
		b1 == 1 &&
		b2 == 12) {
		return YES;
	} else {
		return NO;
	}
}

-(BOOL)isTrailer:(int)byteNum {
	if ((int)[self extractSingleByte:byteNum] == 59 &&
		byteNum == [contents length] - 1) {
		return YES; }
	else {
		return NO;
	}
}

-(BOOL)isExtension:(int)byteNum {
	if ([self isGCE:byteNum] ||
		[self isComment:byteNum] ||
		[self isAppn:byteNum] ||
		[self isPlainText:byteNum]) {
		return YES;
	} else {
		return NO;
	}
}

// sizes

-(int)subblocksSize:(int)byteNum {
	int b = byteNum;
	while (b <= [contents length]) {
		if ([self isTrailer:b] ||
			[self isImage:b] ||
			[self isExtension:b]) {
			return b;
		} else {
			b = b+1+[self extractSingleByte:b];
		}
	}
	return [contents length] - 1;
}

-(int)headerSize:(int)byteNum {

	NSData *packedFieldData = [ByteBits byteToBits:[self extractSingleByte:10]];
	unsigned char packedField[8];
	[packedFieldData getBytes:packedField];	
	
	int metadataSize = 13;
	int rgb = 3;
	int gctFlag = packedField[0];
	int gctExpt = 1 + gctFlag*(4*packedField[5]+2*packedField[6]+packedField[7]);
	int gctSize = pow(2,gctExpt);
	
	return metadataSize+rgb*gctSize;
}
-(int)gceSize:(int)byteNum {
	return 8;	
}
-(int)imageSize:(int)byteNum {

	// extract packed fields from image descriptor
	NSData *packedFieldData = [ByteBits byteToBits:[self extractSingleByte:byteNum+9]];
	unsigned char packedField[8];
	[packedFieldData getBytes:packedField];	
	// local color table size
	int lctFlag = packedField[0];
	int lctExpt = 1 + lctFlag*(4*packedField[5]+2*packedField[6]+packedField[7]);
	int lctSize = pow(2,lctExpt);
	int sbSize = [self subblocksSize:byteNum+9+lctSize+2];
	
	return sbSize-byteNum;	
}
-(int)appnSize:(int)byteNum {
	int sbSize = [self subblocksSize:byteNum+14];
	return sbSize-byteNum;	
}
-(int)commentSize:(int)byteNum {
	return 0;	
}
-(int)plainTextSize:(int)byteNum {
	return 0;	
}


@end
