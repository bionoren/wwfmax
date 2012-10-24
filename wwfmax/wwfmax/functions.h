//
//  functions.h
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#ifndef FUNCTIONS_WWFMAX
#define FUNCTIONS_WWFMAX

#import "WordStructure.h"

#pragma mark - Threading

//threadsafe
static int nextWord(int numWords) {
    static int index = 0;
    OSAtomicIncrement64((int64_t*)&index);
    if(index <= numWords) {
        return index;
    } else {
        return -1;
    }
}

#pragma mark - Debugging

static void printSubwords(char* word, int length, Subword *subwords, int numSubwords) {
    printf("Subwords for %.*s:", length, word);
    for(int i = 0; i < numSubwords; i++) {
        Subword s = subwords[i];
        printf(" %.*s,", s.end - s.start, &word[s.start]);
    }
    printf("\n");
}

#pragma mark - Scoring

static unsigned int valuel(char letter) {
    switch(letter) {
        case 'a':
        case 'e':
        case 'i':
        case 'o':
        case 'r':
        case 's':
        case 't':
            return 1;
        case 'd':
        case 'l':
        case 'n':
        case 'u':
            return 2;
        case 'g':
        case 'h':
        case 'y':
            return 3;
        case 'b':
        case 'c':
        case 'f':
        case 'm':
        case 'p':
        case 'w':
            return 4;
        case 'k':
        case 'v':
            return 5;
        case 'x':
            return 8;
        case 'j':
        case 'q':
        case 'z':
            return 10;
        default:
            return 0;
    }
}

static unsigned int scoreSquareHash(char letter, unsigned int hash) {
    int ret = valuel(letter);
    switch(hash) {
        case 6: 	    //0,6
        case 8: 	    //0,8
        case 51:	    //3,3
        case 59:	    //3,11
        case 85:	    //5,5
        case 89:	    //5,9
        case 96:	    //6,0
        case 110:	//6,14
            return ret*3;
        case 18:	    //1,2
        case 28:	    //1,12
        case 33:	    //2,1
        case 36:	    //2,4
        case 42:	    //2,10
        case 45:	    //2,13
        case 66:	    //4,2
        case 70:	    //4,6
        case 72:	    //4,8
        case 76:    //4,12
        case 100:	//6,4
        case 106:	//6,10
            return ret*2;
        default:
            return ret;
    }
}

static unsigned int scoreSquare(char letter, unsigned int x, unsigned int y) {
    return scoreSquareHash(letter, HASH(x, y));
}

static unsigned int wordMultiplierHash(unsigned int hash) {
    switch(hash) {
        case 3:     //0,3
        case 11:    //0,11
        case 48:    //3,0
        case 62:    //3,14
            return 3;
        case 21:    //1,5
        case 25:	    //1,9
        case 55:	    //1,7
        case 81:	    //5,1
        case 93:	    //5,13
        case 115:	//7,3
        case 123:	//7,11
            return 2;
        default:
            return 1;
    }
}

static unsigned int wordMultiplier(unsigned int x, unsigned int y) {
    return wordMultiplierHash(HASH(x, y));
}

#pragma mark - Validation

static BOOL validate(char *word, int length, char *words, int numWords, int *wordLengths) {
    // inclusive indices
    //   0 <= imin when using truncate toward zero divide
    //     imid = (imin+imax)/2;
    //   imin unrestricted when using truncate toward minus infinity divide
    //     imid = (imin+imax)>>1; or
    //     imid = (int)floor((imin+imax)/2.0);
    //int binary_search(int A[], int key, int imin, int imax)
    
    int imin = 0, imax = numWords;
    
    // continually narrow search until just one element remains
    while(imin < imax) {
        int imid = (imin + imax) / 2;
        
        // code must guarantee the interval is reduced at each iteration
        assert(imid < imax);
        // note: 0 <= imin < imax implies imid will always be less than imax

        if(strncmp(&words[imid * BOARD_LENGTH], word, length) < 0) {
            imin = imid + 1;
        } else {
            imax = imid;
        }
    }
    // At exit of while:
    //   if A[] is empty, then imax < imin
    //   otherwise imax == imin
    
    // deferred test for equality
    if(imax == imin && wordLengths[imin] == length && strncmp(&words[imin * BOARD_LENGTH], word, length) == 0) {
        return YES;
    } else {
        return NO;
    }
}

static void subwordsAtLocation(NSMutableSet **ret, char *word, int length, char *words, int numWords, int *wordLengths) {
    if(length <= NUM_LETTERS_TURN) {
        return [*ret addObject:[WordStructure wordAsLetters:word length:length]];
    }
    
    //max in my testing is 25
    Subword subwords[25];
    int numSubwords = 0;
    for(int i = 0; i < length - 1; i++) { //wwf doesn't acknowledge single letter words
        const int tmpLength = MIN(i + NUM_LETTERS_TURN, length - 1);
        for(int j = i + 2; j < tmpLength; j++) {
            char *subword = &word[i];
            if(validate(subword, j - i, words, numWords, wordLengths)) {
                Subword sub = {.start = i, .end = j};
                subwords[numSubwords++] = sub;
                assert(numSubwords <= 25);
            }
        }
    }
    if(numSubwords == 0) {
        [*ret removeAllObjects];
    }
    
    const unsigned int count = (int)exp2(numSubwords);
    for(unsigned int powerset = 1; powerset < count; powerset++) {
        //forward declarations to make goto happy
        WordStructure *wordStruct;
        NSArray *words;
        
        Subword comboSubwords[BOARD_LENGTH];
        int comboSubwordsLength = 0;
        int lastEnd = 0;
        for(unsigned int i = 1, index = 0; index < numSubwords; i <<= 1, index++) {
            if(i & powerset) {
                Subword s = subwords[index];
                if(s.start <= lastEnd) {
                    goto OVERLAP;
                } else {
                    lastEnd = s.end;
                }
                comboSubwords[comboSubwordsLength++] = s;
            }
            /*if(comboSubwordsLength >= BOARD_LENGTH) {
                printSubwords(word, length, subwords, numSubwords);
                assert(NO);
            }*/
        }
        wordStruct = [[WordStructure alloc] initWithWord:word length:length];
        words = [wordStruct validateSubwords:comboSubwords length:comboSubwordsLength];
        if(words) {
            [*ret addObjectsFromArray:words];
        }
        OVERLAP:
        ;
    }
}

#endif