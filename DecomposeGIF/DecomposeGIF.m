//
//  DecomposeGIF.m
//  DecomposeGIF
//
//  Created by Chris on 11-10-15.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DecomposeGIF.h"

@implementation DecomposeGIF

@synthesize filename, width, height, blockPositions, sortedKeys;

-(id)initWithFile:(NSString*)filepath
{
    self = [super init];
    if (self) {
        // Initialization code here.
		self.filename = [filepath copy];
		contents = [NSData dataWithContentsOfFile:self.filename];
		self.width = [self extractShort:6];
		self.height = [self extractShort:8];
		self.blockPositions = [self indexBlocks];		
		self.sortedKeys = [[self.blockPositions allKeys] sortedArrayUsingSelector:@selector(compare:)];
		
    }    
    return self;
}

// index the GIF blocks

-(NSMutableDictionary*)indexBlocks {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	int b = 0;
	while (b < [contents length]) {
		if ([self isHeader:b]) {
			[dict setObject:@"Header" forKey:[NSNumber numberWithInt:b]];	
			b += [self headerSize:b];
		} else if ([self isImage:b]) {
			[dict setObject:@"Image Descriptor" forKey:[NSNumber numberWithInt:b]];
			b += [self imageSize:b];
		} else if ([self isGCE:b]) {
			[dict setObject:@"Graphic Control Extension" forKey:[NSNumber numberWithInt:b]];
			b += [self gceSize:b];
		} else if ([self isAppn:b]) {
			[dict setObject:@"Application Extension" forKey:[NSNumber numberWithInt:b]];
			b += [self appnSize:b];
		} else if ([self isComment:b]) {
			[dict setObject:@"Comment Extension" forKey:[NSNumber numberWithInt:b]];
			b += [self commentSize:b];
		} else if ([self isPlainText:b]) {
			[dict setObject:@"Plain Text Extension" forKey:[NSNumber numberWithInt:b]];
			b += [self plainTextSize:b];			
		} else if ([self isTrailer:b]) {
			[dict setObject:@"Trailer" forKey:[NSNumber numberWithInt:b]];	
			break;
		} else {
			[dict setObject:@"Unknown" forKey:[NSNumber numberWithInt:b]];	
			b += 1;
		}
	}	
	return dict;
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

-(int)subblocksSize:(int)byteNum {
	int b = byteNum;
	int len = [contents length];
	while (b <= len) {
		if ([self isTrailer:b] ||
			[self isImage:b] ||
			[self isExtension:b]) {
			return b;
		} else {
			b = b+1+[self extractSingleByte:b];
		}
	}
	return len - 1;
}

-(int)findNextImage:(int)byteNum numImages:(int)n {
	
	int count = 0;
	int i = 0;
	NSNumber *byteIndex;
	while (count < n) {
		if (i >= [self.sortedKeys count]) {
			return 0;
		}
		byteIndex = [self.sortedKeys objectAtIndex:i];
		NSString *blk = [self.blockPositions objectForKey:byteIndex];
		if ([blk isEqualToString:@"Image Descriptor"]) {
			count += 1;						
		}
		i += 1;
	}	
	return [byteIndex intValue];
}

// predicates

-(BOOL)isGIF {
	if ([self isHeader:0] ||
		[self findNextImage:0 numImages:1] != 0 ||
		[self isTrailer:[contents length]-1]) {
		return YES;
	} else {
		return NO;
	}
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
	short imgX0 = [self extractShort:byteNum+1];
	short imgY0 = [self extractShort:byteNum+3];	
	short imgX = [self extractShort:byteNum+5];
	short imgY = [self extractShort:byteNum+7];
	if (b0 == 44 &&
		imgX0 <= self.width &&
		imgY0 <= self.height &&
		imgX <= self.width &&
		imgY <= self.height) {
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

-(BOOL)isAnimated {
	if ([self findNextImage:0 numImages:2] > 0) {
		return YES;
	} else {
		return NO;
	}
}

// sizes

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
	int lctExpt = 1 + (4*packedField[5]+2*packedField[6]+packedField[7]);
	int lctSize = lctFlag*pow(2,lctExpt);
	int sbSize = [self subblocksSize:byteNum+9+lctSize+2];
	
	return sbSize-byteNum;	
}
-(int)appnSize:(int)byteNum {
	int sbSize = [self subblocksSize:byteNum+14];
	return sbSize-byteNum;	
}

-(int)commentSize:(int)byteNum {
	int sbSize = [self subblocksSize:byteNum+2];
	return sbSize-byteNum;	
}

-(int)plainTextSize:(int)byteNum {
	int sbSize = [self subblocksSize:byteNum+15];
	return sbSize-byteNum;		
}

// output as PNGs

-(NSMutableArray*)makePNGs {
	
	NSMutableArray *pngs = [NSMutableArray arrayWithCapacity:4];
	
	// header is header
	NSRange headerRange = {0, [self headerSize:0]};
	NSData *header = [contents subdataWithRange:headerRange];
	
	// trailer is ';'
	NSRange trailerRange = {[contents length]-1, 1};
	NSData *trailer = [contents subdataWithRange:trailerRange];
	
	bool addToArray= NO;
	int i = 0;
	NSNumber *byteIndex, *byteIndex1;
	
	while (i < [self.sortedKeys count]-1) {
		
		byteIndex = [self.sortedKeys objectAtIndex:i];
		NSString *blk = [self.blockPositions objectForKey:byteIndex];
		
		if ([blk isEqualToString:@"Graphic Control Extension"]) {
			
			// find next image
			NSNumber *nextIndex; 
			while (YES) {
				if (i+1 >= [self.sortedKeys count]) {
					NSLog(@"makePNGs: Corrupted GIF file!");
				}
				nextIndex = [self.sortedKeys objectAtIndex:i];
				if ([[self.blockPositions objectForKey:nextIndex] isEqualToString:@"Image Descriptor"]) {
					byteIndex1 = [self.sortedKeys objectAtIndex:i+1];
					addToArray = YES;
					break;
				} else {
					i += 1;
				}
			}
		}
		
		if ([blk isEqualToString:@"Image Descriptor"]) {			
			byteIndex1 = [self.sortedKeys objectAtIndex:i+1];
			addToArray = YES;
		} 		
		
		if (addToArray) {
			int i0 = [byteIndex intValue];
			int i1 = [byteIndex1 intValue];
			NSRange imgRange = {i0, i1-i0};
			NSData *img = [contents subdataWithRange:imgRange];
			NSMutableData *output = [NSMutableData dataWithData:header];
			[output appendData:img];
			[output appendData:trailer];
			
			UIImage *uiImg = [UIImage imageWithData:output];	
			NSData *pngImg = [NSData dataWithData:UIImagePNGRepresentation(uiImg)];
			[pngs addObject:pngImg];			
		}
		
		i += 1;
		addToArray = NO;
	}
	
	return pngs;
}

-(BOOL)writePNGs:(NSMutableArray*)array inFolder:(NSString *)folder withName:(NSString *)name {
	
	bool successFlag = NO;
	uint i;
	for (i = 0; i < [array count]; i++) {
		NSString *fileName = [NSString stringWithFormat:@"%@-%i", name, i];
		NSString *extension = @"png";
		NSString *fullPath = [folder stringByAppendingPathComponent:fileName];
		fullPath = [fullPath stringByAppendingPathExtension:extension];
		NSData * data = [array objectAtIndex:i];
		successFlag = [data writeToFile:fullPath atomically:YES];
		if (!successFlag) {
			NSLog(@"Image %i not written to file", i);
			break;
		}
	}	
	return successFlag;
}



@end
