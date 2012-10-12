//
//  WordStructure.m
//  wwfmax
//
//  Created by Bion Oren on 10/5/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import "WordStructure.h"
#import "Letter.h"
#import "functions.h"

@interface WordStructure ()

@property (nonatomic, strong) NSString *word;
@property (nonatomic) int lastEnd;
@property (nonatomic, strong) NSMutableString *subword;

@end

@implementation WordStructure

+(WordStructure*)wordAsLetters:(NSString*)word x:(int)x y:(int)y {
    WordStructure *ret = [[WordStructure alloc] init];
    for(int i = 0; i < word.length; i++) {
        Letter *l = [Letter letterWithCharacter:[word characterAtIndex:i] x:x y:y];
        [ret.parts addObject:l];
    }
    
    return ret;
}

-(id)init {
    if(self = [super init]) {
        _parts = [NSMutableArray array];
    }
    return self;
}

-(id)initWithWord:(NSString*)word {
    if(self = [self init]) {
        self.word = word;
        self.lastEnd = INT_MAX;
    }
    return self;
}

-(id)initWithWord:(NSString*)word parts:(NSMutableArray*)parts {
    if(self = [super init]) {
        self.word = word;
        _parts = parts;
    }
    return self;
}

-(BOOL)addSubword:(Subword*)subword words:(NSArray**)words range:(NSRange*)range {
    if(subword.start < self.lastEnd) {
        return NO;
    }
    if(subword.start == self.lastEnd) {
        [self.subword appendString:subword.word];
        if(!validate(self.subword, words, range)) {
            return NO;
        }
    } else {
        self.subword = [NSMutableString string];
    }
    [self.parts addObject:subword];
    self.lastEnd = subword.end;
    return YES;
}

-(NSArray*)validate {
    //validate and organize self.parts into an ordered breakdown of the word
    NSAssert(self.word, @"Need a word to validate");
    NSArray *parts = [self.parts copy];
    [self.parts removeAllObjects];
    Subword *next = [parts objectAtIndex:0];
    int letters = NUM_LETTERS_TURN;
    for(int i = 0, partIndex = 0; i < self.word.length; i++) {
        if(i > next.end && ++partIndex < parts.count) {
            next = [parts objectAtIndex:partIndex];
        }
        if(i == next.start) {
            [self.parts addObject:next];
            i = next.end - 1;
        } else {
            if(letters-- > 0) {
                Letter *l = [[Letter alloc] initWithCharacter:[self.word characterAtIndex:i]];
                l.x = i;
                [self.parts addObject:l];
            } else {
                return nil;
            }
        }
    }
    
    //If there are any available letters, break subwords into letters, if possible, in all possible combinations
    //note that there is an advantage to not breaking up a subword if there aren't enough letters available for the full breakup
    NSMutableArray *ret = [NSMutableArray arrayWithObject:self];
    if(letters > 0) {
        int i = 0;
        for(id part in self.parts) {
            if([part isKindOfClass:[Subword class]] && ((Subword*)part).word.length < letters) {
                [ret addObjectsFromArray:[self breakUpSubwords:[NSMutableArray arrayWithArray:self.parts] index:i freeLetters:letters]];
            }
            i++;
        }
    }
    return ret;
}

-(NSArray*)breakUpSubwords:(NSMutableArray*)parts index:(int)index freeLetters:(int)letters {
    NSMutableArray *ret = [NSMutableArray array];
    Subword *part = [parts objectAtIndex:index];
    letters -= part.word.length;
    NSAssert(letters >= 0, @"WTF? letters = %d", letters);
    [parts removeObjectAtIndex:index];
    for(int i = 0; i < part.word.length; i++) {
        Letter *l = [[Letter alloc] initWithCharacter:[part.word characterAtIndex:i]];
        l.x = part.start + i;
        [parts insertObject:l atIndex:index + i];
    }
    [ret addObject:[[WordStructure alloc] initWithWord:self.word parts:parts]];
    int i = 0;
    for(id part in parts) {
        if([part isKindOfClass:[Subword class]] && ((Subword*)part).word.length < letters) {
            [ret addObjectsFromArray:[self breakUpSubwords:[NSMutableArray arrayWithArray: parts] index:i freeLetters:letters]];
        }
        i++;
    }
    
    return ret;
}

@end