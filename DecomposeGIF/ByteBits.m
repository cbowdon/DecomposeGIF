//
//  ByteBits.m
//  AnalyzeGIF
//
//  Created by Chris on 11-9-30.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "ByteBits.h"

@implementation ByteBits

+(NSData*)byteToBits:(int)byte {
	int b = byte;	
	if (b > 255 || b < 0) {
		NSException *e = [NSException exceptionWithName:@"NotAByte" reason:@"Not between 0 and 255" userInfo:nil];
		@throw e;
	}
	char rawBits[8];
	int j = 0;
	for (int i = 128; i >= 1; i /= 2) {
		if (b-i < 0) {
			rawBits[j] = 0;
		} else if (b-i > 0) {
			rawBits[j] = 1;
			b -= i;
		} else {			
			rawBits[j] = 1;
			b -= i;
		}
		j++;
	}
	NSData *bits = [NSData dataWithBytes:rawBits length:8];
	return bits;
}

+(unsigned char)bitsToByte:(unsigned char*)bits length:(int)len {
	if (len != 8) {
		NSException *e = [NSException exceptionWithName:@"NotEightBits" reason:@"Not 8 bits!" userInfo:nil];
		@throw e;
	}
	int value = 0;
	int j = 0;
	for (int i = 1; i <= 128; i *= 2) {
		if (bits[j] != 0) {
			value += i;
		}
		j++;
	}
	return (unsigned char)value;
}

// Just a reminder
+(NSString*)endian {
	return @"Big: array[0] == 128";
}

@end
