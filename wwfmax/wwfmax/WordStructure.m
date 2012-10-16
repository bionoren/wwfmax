//
//  WordStructure.m
//  wwfmax
//
//  Created by Bion Oren on 10/5/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import "WordStructure.h"
#import "functions.h"

@interface WordStructure ()

@end

@implementation WordStructure

+(WordStructure*)wordAsLetters:(char*)word length:(int)length {
    WordStructure *ret = [[WordStructure alloc] initWithWord:word length:length];
    ret->_numLetters = length;
    for(unsigned int i = 0; i < ret->_length; i++) {
        char c = ret->_word[i];
        assert(c <= 'z');
        Letter l = HASH(i, c);
        ret->_letters[i] = l;
    }
    
    return ret;
}

-(id)init {
    if(self = [super init]) {
        _numLetters = 0;
        _numSubwords = 0;
    }
    return self;
}

-(id)initWithWord:(char*)word length:(int)length; {
    if(self = [self init]) {
        _word = word;
        _length = length;
    }
    return self;
}

-(NSArray*)validateSubwords:(Subword*)subwords length:(int)numSubwords {
    //validate and organize self.parts into an ordered breakdown of the word
    Subword next = subwords[0];
    int letters = NUM_LETTERS_TURN;
    for(unsigned int i = 0, subwordIndex = 0; i < _length; i++) {
        if(i > next.end && ++subwordIndex < numSubwords) {
            next = subwords[subwordIndex];
        }
        if(i == next.start) {
            i = next.end - 1;
        } else {
            if(letters-- > 0) {
                char c = _word[i];
                assert(c <= 'z');
                Letter l = HASH(i, c);
                _letters[_numLetters++] = l;
            } else {
                return nil;
            }
        }
    }
#ifdef DEBUG
    for(int i = 0; i < numSubwords; i++) {
        Subword s = subwords[i];
        assert(s.start < s.end);
    }
#endif
    memcpy(_subwords, subwords, numSubwords * sizeof(Subword));
    _numSubwords = numSubwords;
    
    //If there are any available letters, break subwords into letters, if possible, in all possible combinations
    //note that there is an advantage to not breaking up a subword if there aren't enough letters available for the full breakup
    NSMutableArray *ret = [NSMutableArray arrayWithObject:self];
    int numFreeLetters = NUM_LETTERS_TURN - _numLetters;
    if(numFreeLetters > 0) {
        for(int i = 0; i < _numSubwords; i++) {
            Subword s = _subwords[i];
            if(s.end - s.start < numFreeLetters) {
                [ret addObjectsFromArray:[self breakUpSubwordsAtIndex:i freeLetters:numFreeLetters]];
            }
        }
    }
    return ret;
}

-(NSArray*)breakUpSubwordsAtIndex:(int)index freeLetters:(int)letters {
    NSMutableArray *ret = [NSMutableArray array];
    Subword part = _subwords[index];
    int partLen = part.end - part.start;
    letters -= partLen;
    NSAssert(letters >= 0, @"WTF? letters = %d", letters);
    for(int i = index + 1; i < _numSubwords; i++) {
        _subwords[i - 1] = _subwords[i];
    }
    _numSubwords--;
    
    WordStructure *tmp = [[WordStructure alloc] initWithWord:_word length:_length];
    for(unsigned int i = 0; i < partLen; i++) {
        unsigned int loc = part.start + i;
        char c = _word[loc];
        assert(c <= 'z');
        Letter l = HASH(loc, c);
        tmp->_letters[tmp->_numLetters++] = l;
    }
    [ret addObject:tmp];
    for(int i = 0; i < _numSubwords; i++) {
        part = _subwords[i];
        partLen = part.end - part.start;
        if(partLen < letters) {
            [ret addObjectsFromArray:[self breakUpSubwordsAtIndex:i freeLetters:letters]];
        }
    }
    
    return ret;
}

@end