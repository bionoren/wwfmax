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
#import "DictionaryManager.h"

#pragma mark - Debugging

void printSubwords(char* word, int length, Subword *subwords, int numSubwords) {
    printf("Subwords for %.*s:", length, word);
    for(int i = 0; i < numSubwords; i++) {
        Subword s = subwords[i];
        printf(" %.*s,", s.end - s.start, &word[s.start]);
    }
    printf("\n");
}

#pragma mark - Scoring

int valuel(char letter) {
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

int scoreSquarePrescoredHash(char letter, int hash) {
    switch(hash) {
        case 6: 	//0,6
        case 8: 	//0,8
        case 51:	//3,3
        case 59:	//3,11
        case 85:	//5,5
        case 89:	//5,9
        case 96:	//6,0
        case 110:	//6,14
            return valuel(letter)*2;
        case 18:	//1,2
        case 28:	//1,12
        case 33:	//2,1
        case 36:	//2,4
        case 42:	//2,10
        case 45:	//2,13
        case 66:	//4,2
        case 70:	//4,6
        case 72:	//4,8
        case 76:    //4,12
        case 100:	//6,4
        case 106:	//6,10
            return valuel(letter);
        default:
            return 0;
    }
}

int scoreSquarePrescored(char letter, int x, int y) {
    return scoreSquarePrescoredHash(letter, HASH(x, y));
}

int scoreSquareHash(char letter, int hash) {
    int ret = valuel(letter);
    switch(hash) {
        case 6:     //0,6
        case 8: 	//0,8
        case 51:	//3,3
        case 59:	//3,11
        case 85:	//5,5
        case 89:	//5,9
        case 96:	//6,0
        case 110:	//6,14
            return ret*3;
        case 18:	//1,2
        case 28:	//1,12
        case 33:	//2,1
        case 36:	//2,4
        case 42:	//2,10
        case 45:	//2,13
        case 66:	//4,2
        case 70:	//4,6
        case 72:	//4,8
        case 76:    //4,12
        case 100:	//6,4
        case 106:	//6,10
            return ret*2;
        default:
            return ret;
    }
}

int scoreSquare(char letter, int x, int y) {
    return scoreSquareHash(letter, HASH(x, y));
}

int wordMultiplierHash(int hash) {
    switch(hash) {
        case 3:     //0,3
        case 11:    //0,11
        case 48:    //3,0
        case 62:    //3,14
            return 3;
        case 21:    //1,5
        case 25:	//1,9
        case 55:	//1,7
        case 81:	//5,1
        case 93:	//5,13
        case 115:	//7,3
        case 123:	//7,11
            return 2;
        default:
            return 1;
    }
}

int wordMultiplier(int x, int y) {
    return wordMultiplierHash(HASH(x, y));
}

int prescoreWord(const char *word, const int length) {
    int ret = 0;
    for(int i = 0; i < length; i++) {
        ret += valuel(word[i]);
    }
    return ret;
}

int scoreLettersWithPrescore(const int prescore, const int length, char *chars, int *offsets, const int x, const int y) {
    int val = prescore;
    int mult = 1;
    
    //score the letters and note the word multipliers
    for(int i = 0; i < length; ++i) {
        assert(chars[i] <= 'z' && chars[i] >= 'A');
        int hash = HASH(offsets[i] + x, y);
        val += scoreSquarePrescoredHash(chars[i], hash);
        mult *= wordMultiplierHash(hash);
    }
    
    return val * mult;
}

#pragma mark - Validation

BOOL validate(const char *word, const int length, const WordInfo *info) {
    // inclusive indices
    //   0 <= imin when using truncate toward zero divide
    //     imid = (imin+imax)/2;
    //   imin unrestricted when using truncate toward minus infinity divide
    //     imid = (imin+imax)>>1; or
    //     imid = (int)floor((imin+imax)/2.0);
    //int binary_search(int A[], int key, int imin, int imax)
    
    int imin = 0, imax = info->numWords - 1;
    
    // continually narrow search until just one element remains
    while(imin < imax) {
        int imid = (imin + imax) / 2;
        
        // code must guarantee the interval is reduced at each iteration
        assert(imid < imax);
        // note: 0 <= imin < imax implies imid will always be less than imax
        
        if(strncmp(&(info->words[imid * BOARD_LENGTH]), word, length) < 0) {
            imin = imid + 1;
        } else {
            imax = imid;
        }
    }
    // At exit of while:
    //   if A[] is empty, then imax < imin
    //   otherwise imax == imin
    
    // deferred test for equality
    if(imax == imin && info->lengths[imin] == length && strncmp(&(info->words[imin * BOARD_LENGTH]), word, length) == 0) {
        return YES;
    } else {
        return NO;
    }
}

void subwordsAtLocation(NSMutableSet **ret, char *word, const int length) {
    if(length <= NUM_LETTERS_TURN) {
        return [*ret addObject:[WordStructure wordAsLetters:word length:length]];
    }
    
    //max in my testing is 25
    Subword subwords[25];
    int numSubwords = 0;
    for(int i = 0; i < length - 1; ++i) { //wwf doesn't acknowledge single letter words
        const int tmpLength = MIN(i + NUM_LETTERS_TURN, length - 1);
        for(int j = i + 2; j < tmpLength; ++j) {
            const char *subword = &word[i];
            if(isValidWord(subword, j - i)) {
                Subword sub = {.start = i, .end = j};
                subwords[numSubwords++] = sub;
                assert(numSubwords <= 25);
            }
        }
    }
    
    const int count = (int)exp2(numSubwords);
    for(int powerset = 1; powerset < count; powerset++) {
        //forward declarations to make goto happy
        WordStructure *wordStruct;
        
        Subword comboSubwords[BOARD_LENGTH];
        int comboSubwordsLength = 0;
        int lastEnd = 0;
        for(int i = 1, index = 0; index < numSubwords; i <<= 1, ++index) {
            if(i & powerset) {
                Subword s = subwords[index];
                if(s.start <= lastEnd) {
                    goto OVERLAP;
                } else {
                    lastEnd = s.end;
                }
                comboSubwords[comboSubwordsLength++] = s;
            }
        }
        wordStruct = [[WordStructure alloc] initWithWord:word length:length];
        if([wordStruct validateSubwords:comboSubwords length:comboSubwordsLength]) {
            [*ret addObject:wordStruct];
        }
    OVERLAP:
        ;
    }
}

BOOL playable(char *word, const int length, const WordInfo *info) {
    if(length <= NUM_LETTERS_TURN) {
        return YES;
    }
    
    //max in my testing is 25
    Subword subwords[25];
    int numSubwords = 0;
    for(int i = 0; i < length - 1; ++i) { //wwf doesn't acknowledge single letter words
        const int tmpLength = MIN(i + NUM_LETTERS_TURN, length - 1);
        for(int j = i + 2; j < tmpLength; ++j) {
            const char *subword = &word[i];
            if(validate(subword, j - i, info)) {
                Subword sub = {.start = i, .end = j};
                subwords[numSubwords++] = sub;
                assert(numSubwords <= 25);
                if(length - (j - i) <= NUM_LETTERS_TURN) {
                    return YES;
                }
            }
        }
    }
    if(numSubwords == 0) {
        return NO;
    }
    
    const int count = (int)exp2(numSubwords);
    for(int powerset = 1; powerset < count; powerset++) {
        //forward declarations to make goto happy
        WordStructure *wordStruct;
        
        Subword comboSubwords[BOARD_LENGTH];
        int comboSubwordsLength = 0;
        int lastEnd = 0;
        for(int i = 1, index = 0; index < numSubwords; i <<= 1, ++index) {
            if(i & powerset) {
                Subword s = subwords[index];
                if(s.start <= lastEnd) {
                    goto OVERLAP;
                } else {
                    lastEnd = s.end;
                }
                comboSubwords[comboSubwordsLength++] = s;
            }
        }
        wordStruct = [[WordStructure alloc] initWithWord:word length:length];
        if([wordStruct validateSubwords:comboSubwords length:comboSubwordsLength]) {
            return YES;
        }
    OVERLAP:
        ;
    }
    return NO;
}

#endif