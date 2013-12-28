//
//  WordStructure.m
//  wwfmax
//
//  Created by Bion Oren on 10/5/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import "WordStructure.h"
#import "functions.h"

bool populateIndexes(bool *indexes, bool *locations, int startIndex, int length, int numToPopulate);

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

+(NSArray*)validateWord:(char[BOARD_LENGTH + 1])word length:(int)length subwords:(Subword*)subwords length:(int)numSubwords iterator:(DictionaryIterator*)itr {
    //make sure consecutive subwords are also words
    if(numSubwords > 1) {
        Subword subword = subwords[0];
        for(int i = 1; i < numSubwords; ++i) {
            Subword s = subwords[i];
            if(subword.end == s.start) {
                return nil;
            }
            subword = s;
        }
    }

    //find the free letters
    int numLetters = 0;
    Letter letters[NUM_LETTERS_TURN];
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
            if(numLetters < NUM_LETTERS_TURN) {
                char c = word[i];
                assert(c <= 'z');
                Letter l = (typeof(Letter))HASH(i, c);
                letters[numLetters] = l;
            }
            numLetters++;
        }
    }

    if(numLetters > NUM_LETTERS_TURN) { //generate vertical word permutations
        //initialize
        NSMutableArray *ret = [[NSMutableArray alloc] init];
        int numExtraLetters = numLetters - NUM_LETTERS_TURN;
        numLetters = 0;
        int numAvailableLetters = 0;
        int verticalLocations = 0; //bit set if the character is eligable to be used for a vertical word
        Subword subword;
        int subwordIndex = 0;
        if(numSubwords > 0) {
            subword = subwords[subwordIndex++];
        } else {
            subword.start=BOARD_LENGTH+2;
            subword.end=BOARD_LENGTH+2;
        }
        for(int i = 0; i < length; ++i) {
            if(i + 1 == subword.start) { //can't use letter next to start
                assert(numLetters < NUM_LETTERS_TURN);
                letters[numLetters++] = (typeof(Letter))HASH(i, word[i]);
                continue;
            }
            if(i == subword.end) { //can't use letter next to end
                if(subwordIndex < numSubwords) {
                    subword = subwords[subwordIndex++];
                }
                assert(numLetters < NUM_LETTERS_TURN);
                letters[numLetters++] = (typeof(Letter))HASH(i, word[i]);
                continue;
            }
            if(i == subword.start) { //can't use letters in subwords
                i = subword.end - 1;
                continue;
            }
            verticalLocations |= 1 << i;
            numAvailableLetters++;
        }
        //if we don't have enough eligable vertical letters, fail
        if(numAvailableLetters < numExtraLetters) {
            return nil;
        }

        //permute
        //1000XXXX0
        //0100XXXX0
        //0010XXXX0
        //0001XXXX0
        //0000XXXX1

        //1010XXXX0
        //1001XXXX0
        //1000XXXX1
        //0101XXXX0
        //0100XXXX1
        //0010XXXX1
        //0001XXXX1

        //1010XXXX1
        //1001XXXX1
        //0101XXXX1

        //start by laying bits down. Then shift right most bit as far right as you can. Next, shift the second right most bit right one and replace the the high bit as far left as you can
        //(but still right of the second highest bit). Etc.
        /*bool indexes = [BOARD_LENGTH];
        if(!populateIndexes(indexes, verticalLocations, 0, length, numExtraLetters)) {
            return nil;
        }
        for(int i = 0; i < numExtraLetters; i++) {
            while(true) {
                WordStructure *wordStruct = [[WordStructure alloc] initWithWord:word length:length subwords:subwords numSubwords:numSubwords];
                wordStruct->_hasVerticalWords = true;
                wordStruct->_numLetters = NUM_LETTERS_TURN;
                memcpy(wordStruct->_letters, letters, numLetters * sizeof(Letter));
                for(int j = 0; j < length; j++) {
                    if(indexes[j]) {
                        assert(wordStruct->_numLetters < NUM_LETTERS_TURN);
                        wordStruct->_letters[wordStruct->_numLetters++] = (typeof(Letter))HASH(j, word[j]);
                    }
                }
            }
        }*/
        if(numExtraLetters == 1) {
            for(int i = 0; i < length; ++i) {
                if(verticalLocations & (1 << i)) {
                    WordStructure *wordStruct = [[WordStructure alloc] initWithWord:word length:length subwords:subwords numSubwords:numSubwords];
                    wordStruct->_hasVerticalWords = true;
                    wordStruct->_numLetters = numLetters;
                    memcpy(wordStruct->_letters, letters, numLetters * sizeof(Letter));
                    wordStruct->_verticalLetters[i] = true;

                    for(int j = 0; j < length; j++) {
                        if(j != i && (verticalLocations & (1 << j))) {
                            assert(wordStruct->_numLetters < NUM_LETTERS_TURN);
                            wordStruct->_letters[wordStruct->_numLetters++] = (typeof(Letter))HASH(j, word[j]);
                        }
                    }
                    assert(wordStruct->_numLetters == NUM_LETTERS_TURN);
                    [ret addObject:wordStruct];
                }
            }
        } else {
            int max = (int)exp2(length - 1); //set the high bit
            max |= max >> 1; //set the next highest bit
            for(int i = 1; i < max; ++i) {
                if((i & verticalLocations) == i) {
                    int consecutiveCheck = i & (i << 1);
                    //6    & 12   -> 4
                    //0110 & 1100 -> 0100
                    //6    + 2    -> 8
                    //0110 + 0010 -> 1000

                    //12    & 24    -> 8
                    //01100 & 11000 -> 01000
                    //12    + 4     -> 16
                    //01100 + 00100 -> 10000
                    if(consecutiveCheck || __builtin_popcount(i) != numExtraLetters) {
                        if(consecutiveCheck) {
                            do {
                                assert(__builtin_popcount(consecutiveCheck) == 1);
                                i += consecutiveCheck >> 1;
                                consecutiveCheck = i & (i << 1);
                            } while(consecutiveCheck);
                            --i;
                        }
                        continue;
                    }
                    WordStructure *wordStruct = [[WordStructure alloc] initWithWord:word length:length subwords:subwords numSubwords:numSubwords];
                    wordStruct->_hasVerticalWords = true;
                    wordStruct->_numLetters = numLetters;
                    memcpy(wordStruct->_letters, letters, numLetters * sizeof(Letter));
                    for(int j = 0; j < length; j++) {
                        int temp = 1 << j;
                        if(i & temp) {
                            wordStruct->_verticalLetters[j] = true;
                        } else if(verticalLocations & temp) {
                            assert(wordStruct->_numLetters < NUM_LETTERS_TURN);
                            wordStruct->_letters[wordStruct->_numLetters++] = (typeof(Letter))HASH(j, word[j]);
                        }
                    }
                    assert(wordStruct->_numLetters == NUM_LETTERS_TURN);
                    [ret addObject:wordStruct];
                }
            }
        }
        return ret;
    } else { //playing more letters is always better, so since we can play them we should
        WordStructure *wordStruct = [[WordStructure alloc] initWithWord:word length:length subwords:subwords numSubwords:numSubwords];
        memcpy(wordStruct->_letters, letters, numLetters * sizeof(Letter));
        wordStruct->_numLetters = numLetters;
        return [NSArray arrayWithObject:wordStruct];
    }
}

@end

bool populateIndexes(bool *indexes, bool *locations, int startIndex, int length, int numToPopulate) {
    for(int i = startIndex; i < length; ++i) {
        indexes[i] = false;
    }
    bool clear = true;
    for(int i = startIndex; i < length; ++i) {
        if(clear && locations[i]) {
            indexes[i] = true;
            clear = false;
            if(--numToPopulate == 0) {
                return true;
            }
        } else {
            clear = true;
        }
    }
    return false;
}