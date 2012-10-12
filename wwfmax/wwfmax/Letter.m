//
//  Letter.m
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import "Letter.h"

static Letter *letters[225] = {nil};

@implementation Letter

+(Letter*)letterWithCharacter:(char)c x:(int)x y:(int)y {
    int index = x + y*15;
    if(!letters[index]) {
        Letter *tmp = [[Letter alloc] init];
        tmp.x = x;
        tmp.y = y;
        letters[index] = tmp;
    }
    Letter *ret = letters[index];
    ret.letter = c;
    return ret;
}

-(id)initWithCharacter:(char)c {
    if(self = [super init]) {
        self.letter = c;
    }
    return self;
}

-(NSString*)description {
    return [NSString stringWithFormat:@"%c (%d, %d)", self.letter, self.x, self.y];
}

-(id)copyWithZone:(NSZone *)zone {
    Letter *ret = [[Letter alloc] init];
    ret.letter = self.letter;
    ret.x = self.x;
    ret.y = self.y;
    return ret;
}

@end