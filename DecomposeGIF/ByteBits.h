//
//  ByteBits.h
//  AnalyzeGIF
//
//  Created by Chris on 11-9-30.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ByteBits : NSObject 

+(NSData*)byteToBits:(int)byte;
+(unsigned char)bitsToByte:(unsigned char*)bits length:(int)len;
+(NSString*)endian;

@end
