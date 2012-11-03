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

+(WordStructure*)wordAsLetters:(char*)word length:(const int)length {
    WordStructure *ret = [[WordStructure alloc] initWithWord:word length:length];
    ret->_numLetters = length;
    for(int i = 0; i < ret->_length; i++) {
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

-(id)initWithWord:(char*)word length:(const int)length; {
    if(self = [self init]) {
        _word = word;
        _length = length;
    }
    return self;
}

-(BOOL)validateSubwords:(Subword*)subwords length:(int)numSubwords {
    //validate and organize self.parts into an ordered breakdown of the word
    Subword next = subwords[0];
    int letters = NUM_LETTERS_TURN;
    for(int i = 0, subwordIndex = 0; i < _length; i++) {
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
                return NO;
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
    
    return YES;
}

@end