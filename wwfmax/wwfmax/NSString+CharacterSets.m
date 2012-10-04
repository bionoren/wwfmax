//
//  NSString+CharacterSets.m
//  wwfmax
//
//  Created by Bion Oren on 10/3/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import "NSString+CharacterSets.h"
#import "Letter.h"
#import "functions.h"

@implementation NSString (CharacterSets)

-(NSSet*)characterSetsAtX:(int)x y:(int)y {
    NSMutableSet *ret = [NSMutableSet set];
    
    if(self.length <= NUM_LETTERS_TURN) {
        NSMutableArray *chars = [NSMutableArray arrayWithCapacity:self.length];
        int extraIndex1 = -1;
        int extraIndex2 = -1;
        for(int i = 0; i < self.length; i++) {
            char c = [self characterAtIndex:i];
            Letter *l = [Letter letterWithCharacter:c x:x + i y:y];
            if(c < LETTER_OFFSET) {
                l.letter = c - 65 + LETTER_OFFSET;
                if(extraIndex1 < 0) {
                    extraIndex1 = i;
                } else {
                    extraIndex2 = i;
                }
            }
            [chars addObject:l];
        }
        
        if(extraIndex1 >= 0) {
            Letter *extra1 = [[chars objectAtIndex:extraIndex1] copy];
            Letter *extra2 = nil;
            if(extraIndex2 >= 0) {
                extra2 = [[chars objectAtIndex:extraIndex2] copy];
            }
            
            for(int i = 0; i < chars.count; i++) {
                Letter *l1orig = [chars objectAtIndex:i];
                if(l1orig.letter == extra1.letter) {
                    Letter *l1 = [l1orig copy];
                    l1.letter = l1.letter - LETTER_OFFSET + 65;
                    [chars replaceObjectAtIndex:i withObject:l1];
                    if(extra2) {
                        for(int j = 0; j < chars.count; j++) {
                            Letter *l2orig = [chars objectAtIndex:j];
                            if(l2orig.letter == extra2.letter) {
                                Letter *l2 = [l2orig copy];
                                l2.letter = l2.letter - LETTER_OFFSET + 65;
                                [chars replaceObjectAtIndex:j withObject:l2];
                                [ret addObject:[NSSet setWithArray:chars]];
                                [chars replaceObjectAtIndex:j withObject:l2orig];
                            }
                        }
                    } else {
                        [ret addObject:[NSSet setWithArray:chars]];
                    }
                    [chars replaceObjectAtIndex:i withObject:l1orig];
                }
            }
        } else {
            [ret addObject:[NSSet setWithArray:chars]];
        }
        /*if(extraIndex2 >= 0) {
            NSLog(@"return %@", ret);
            abort();
        }*/
    } else {
        NSAssert(NO, @"Not yet implemented");
    }
    
    return ret;
}

@end