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

+(WordStructure*)wordAsLetters:(char[BOARD_LENGTH + 1])word length:(const int)length {
    WordStructure *ret = [[WordStructure alloc] initWithWord:word length:length subwords:NULL numSubwords:0];
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

-(id)initWithWord:(char[BOARD_LENGTH + 1])word length:(const int)length subwords:(Subword*)subwords numSubwords:(int)numSubwords  {
    if(self = [super init]) {
        _word = word;
        _length = length;
        _numSubwords = numSubwords;
        memcpy(_subwords, subwords, numSubwords * sizeof(Subword));
    }
    return self;
}

+(NSArray*)validateWord:(char[BOARD_LENGTH + 1])word length:(int)length subwords:(Subword*)subwords length:(int)numSubwords iterator:(DictionaryIterator*)itr wordInfo:(const WordInfo*)info {
    //make sure consecutive subwords are also words
    if(numSubwords > 1) {
        Subword startSubword = subwords[0];
        Subword lastSubword = subwords[0];
        for(int i = 1; i < numSubwords; ++i) {
            Subword s = subwords[i];
            if(lastSubword.end == s.start) {
                if(itr && !isValidWord(itr->mgr, &(word[startSubword.start]), s.end - startSubword.start)) {
                    return nil;
                } else if(info && !validate(&(word[startSubword.start]), s.end - startSubword.start, info)) {
                    return nil;
                }
            } else {
                startSubword = s;
            }
            lastSubword = s;
        }
    }

    //find the free letters
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    int numLetters = 0;
    Letter letters[BOARD_LENGTH];
    Subword next = {BOARD_LENGTH};
    if(numSubwords > 0) {
        next = subwords[0];
    }
    for(int i = 0, subwordIndex = 0; i < length; ++i) {
        if(i >= next.end && ++subwordIndex < numSubwords) {
            next = subwords[subwordIndex];
        }
        if(i == next.start) {
            i = next.end - 1;
        } else {
            char c = word[i];
            assert(c <= 'z');
            Letter l = (typeof(Letter))HASH(i, c);
            letters[numLetters++] = l;
        }
    }

    if(numLetters > NUM_LETTERS_TURN) { //generate vertical word permutations
        //initialize
        int numExtraLetters = numLetters - NUM_LETTERS_TURN;
        bool indexes[BOARD_LENGTH] = {false}; //true if the character is being used for a vertical word
        bool freeLetters[BOARD_LENGTH] = {false}; //true if the letter is available as a "free letter" (not part of a subword)
        int index = 0;
        int lastIndex = X_FROM_HASH(letters[index]);
        indexes[lastIndex] = true;
        freeLetters[lastIndex] = true;
        for(int i = 1; i < numExtraLetters; ++i) {
            if(X_FROM_HASH(letters[++index]) - lastIndex == 1) {
                index++;
            }
            lastIndex = X_FROM_HASH(letters[index]);
            indexes[lastIndex] = true;
            freeLetters[lastIndex] = true;
        }

        //permute
        PERMUTE_START:; //essentially a custom while(true) loop
        {
            //add a struct for this permutation
            WordStructure *wordStruct = [[WordStructure alloc] initWithWord:word length:length subwords:subwords numSubwords:numSubwords];
            wordStruct->_hasVerticalWords = true;
#ifdef DEBUG
            int debug_numVerticalWords = 0;
            for(int i = 0; i < BOARD_LENGTH; i++) {
                assert(!indexes[i] || ((i + 1 >= BOARD_LENGTH || !indexes[i + 1]) && (i - 1 < 0 || !indexes[i + 1])));
                if(indexes[i]) {
                    debug_numVerticalWords++;
                }
            }
            assert(debug_numVerticalWords == numExtraLetters);
            assert(numLetters - debug_numVerticalWords == NUM_LETTERS_TURN);
#endif
            for(int i = 0; i < numLetters; ++i) { //add the free letters to the struct
                if(indexes[i]) {
                    wordStruct->_verticalLetters[i] = true;
                    continue;
                }
                wordStruct->_letters[wordStruct->_numLetters++] = letters[i];
            }
            assert(wordStruct->_numLetters == NUM_LETTERS_TURN);
            [ret addObject:wordStruct];

            //advance to the next permutation
            //start at the right and work left (backwards) trying to advance a vertical word to the right. Once you've advanced one, reset the ones to the right (that you already passed), and continue.
            int indexesPassed = 0;
            for(int i = numLetters - 1; i >= 0; --i) { //need to start at the end to get indexesPassed right
                if(indexes[i]) { //we found a vertical letter...
                    if(i + 2 < numLetters && !indexes[i + 2] && freeLetters[i + 1]) { //... we can move right
                        assert(!indexes[i + 1]);
                        //move it right
                        indexes[i] = false;
                        indexes[i + 1] = true;
                        //reset the others
                        bool spacer = false;
                        for(int j = i + 2; j < numLetters; ++j) {
                            if(freeLetters[j]) {
                                indexes[j] = spacer && --indexesPassed > 0;
                            }
                            spacer = true;
                        }
                        //and continue
                        goto PERMUTE_START;
                    }
                    indexesPassed++;
                }
            }
            //if you never advanced anything, we're done
        }
    } else { //playing more letters is always better, so since we can play them we should
        WordStructure *wordStruct = [[WordStructure alloc] initWithWord:word length:length subwords:subwords numSubwords:numSubwords];
        memcpy(wordStruct->_letters, letters, numLetters * sizeof(Letter));
        wordStruct->_numLetters = numLetters;
        [ret addObject:wordStruct];
    }
    
    return ret;
}

@end