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
        Letter l = (typeof(Letter))HASH(i, c);
        assert(l >= 16);
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

-(BOOL)validateSubwords:(Subword*)subwords length:(int)numSubwords iterator:(DictionaryIterator*)itr wordInfo:(const WordInfo*)info {
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
                Letter l = (typeof(Letter))HASH(i, c);
                assert(l >= 16);
                _letters[_numLetters++] = l;
            } else {
                return NO;
            }
        }
    }
    
    if(numSubwords) {
        Subword lastSubword = subwords[0];
        for(int i = 1; i < numSubwords; i++) {
            Subword s = subwords[i];
            if(lastSubword.end == s.start) {
                if(itr && !isValidWord(itr->mgr, &(self->_word[lastSubword.start]), s.end - lastSubword.start)) {
                    return NO;
                } else if(validate(&(self->_word[lastSubword.start]), s.end - lastSubword.start, info)) {
                    return NO;
                }
            }
        }
        memcpy(_subwords, subwords, numSubwords * sizeof(Subword));
    }
    
    _numSubwords = numSubwords;
    
    return YES;
}

@end