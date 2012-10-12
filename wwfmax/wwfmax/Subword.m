//
//  Subword.m
//  wwfmax
//
//  Created by Bion Oren on 10/5/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import "Subword.h"

@implementation Subword

+(Subword*)subwordWithWord:(NSString*)word start:(int)start end:(int)end {
    Subword *ret = [[Subword alloc] init];
    ret.word = word;
    ret.start = start;
    ret.end = end;
    return ret;
}

-(NSString*)description {
    return [NSString stringWithFormat:@"%@ (%d, %d)", self.word, self.start, self.end];
}

@end