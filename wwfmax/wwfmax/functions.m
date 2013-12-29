//
//  functions.m
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//
#import "functions.h"

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
    /*switch(letter) {
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
    }*/
    static const char lookupTable[123] = {0,0,0,0,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,0,0,0,0,
                                        0,0,0,0,0,0,1,4,4,2,
                                        1,4,3,3,1,10,5,2,4,2,
                                        1,4,10,1,1,1,2,5,4,8,
                                        3,10};
    return lookupTable[letter];
}

int scoreSquarePrescoredHash(char letter, int hash) {
    /*static char lookupTable[255] = {0};
    lookupTable[HASH(6, 0)] = 2;
    lookupTable[HASH(8, 0)] = 2;
    lookupTable[HASH(3, 3)] = 2;
    lookupTable[HASH(11, 3)] = 2;
    lookupTable[HASH(5, 5)] = 2;
    lookupTable[HASH(9, 5)] = 2;
    lookupTable[HASH(0, 6)] = 2;
    lookupTable[HASH(14, 6)] = 2;
    lookupTable[HASH(0, 8)] = 2;
    lookupTable[HASH(14, 8)] = 2;
    lookupTable[HASH(5, 9)] = 2;
    lookupTable[HASH(9, 9)] = 2;
    lookupTable[HASH(3, 11)] = 2;
    lookupTable[HASH(11, 11)] = 2;
    lookupTable[HASH(6, 14)] = 2;
    lookupTable[HASH(8, 14)] = 2;
    lookupTable[HASH(2, 1)] = 1;
    lookupTable[HASH(12, 1)] = 1;
    lookupTable[HASH(1, 2)] = 1;
    lookupTable[HASH(4, 2)] = 1;
    lookupTable[HASH(10, 2)] = 1;
    lookupTable[HASH(13, 2)] = 1;
    lookupTable[HASH(2, 4)] = 1;
    lookupTable[HASH(6, 4)] = 1;
    lookupTable[HASH(8, 4)] = 1;
    lookupTable[HASH(12, 4)] = 1;
    lookupTable[HASH(4, 6)] = 1;
    lookupTable[HASH(10, 6)] = 1;
    lookupTable[HASH(4, 8)] = 1;
    lookupTable[HASH(10, 8)] = 1;
    lookupTable[HASH(2, 10)] = 1;
    lookupTable[HASH(6, 10)] = 1;
    lookupTable[HASH(8, 10)] = 1;
    lookupTable[HASH(12, 10)] = 1;
    lookupTable[HASH(1, 12)] = 1;
    lookupTable[HASH(4, 12)] = 1;
    lookupTable[HASH(10, 12)] = 1;
    lookupTable[HASH(13, 12)] = 1;
    lookupTable[HASH(2, 13)] = 1;
    lookupTable[HASH(12, 13)] = 1;*/
    static const char lookupTable[255] = {0,0,0,0,0,0,2,0,2,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,1,0,0,0,0,0,1,0,0,1,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,1,0,0,0,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,2,0,0,0,1,0,0,0,0,0,1,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,1,0,0,0,0,0,1,0,0,0,2,0,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,0,0,1,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,1,0,0,1,0,0,0,0,0,1,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,2,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

    return valuel(letter) * lookupTable[hash];
}

int scoreSquarePrescored(char letter, int x, int y) {
    return scoreSquarePrescoredHash(letter, HASH(x, y));
}

int scoreSquareHash(char letter, int hash) {
    /*static char lookupTable[255];
     for(int i = 0; i < 255; i++) {
     lookupTable[i] = 1;
     }
    lookupTable[HASH(6, 0)] = 3;
    lookupTable[HASH(8, 0)] = 3;
    lookupTable[HASH(3, 3)] = 3;
    lookupTable[HASH(11, 3)] = 3;
    lookupTable[HASH(5, 5)] = 3;
    lookupTable[HASH(9, 5)] = 3;
    lookupTable[HASH(0, 6)] = 3;
    lookupTable[HASH(14, 6)] = 3;
    lookupTable[HASH(0, 8)] = 3;
    lookupTable[HASH(14, 8)] = 3;
    lookupTable[HASH(5, 9)] = 3;
    lookupTable[HASH(9, 9)] = 3;
    lookupTable[HASH(3, 11)] = 3;
    lookupTable[HASH(11, 11)] = 3;
    lookupTable[HASH(6, 14)] = 3;
    lookupTable[HASH(8, 14)] = 3;
    lookupTable[HASH(2, 1)] = 2;
    lookupTable[HASH(12, 1)] = 2;
    lookupTable[HASH(1, 2)] = 2;
    lookupTable[HASH(4, 2)] = 2;
    lookupTable[HASH(10, 2)] = 2;
    lookupTable[HASH(13, 2)] = 2;
    lookupTable[HASH(2, 4)] = 2;
    lookupTable[HASH(6, 4)] = 2;
    lookupTable[HASH(8, 4)] = 2;
    lookupTable[HASH(12, 4)] = 2;
    lookupTable[HASH(4, 6)] = 2;
    lookupTable[HASH(10, 6)] = 2;
    lookupTable[HASH(4, 8)] = 2;
    lookupTable[HASH(10, 8)] = 2;
    lookupTable[HASH(2, 10)] = 2;
    lookupTable[HASH(6, 10)] = 2;
    lookupTable[HASH(8, 10)] = 2;
    lookupTable[HASH(12, 10)] = 2;
    lookupTable[HASH(1, 12)] = 2;
    lookupTable[HASH(4, 12)] = 2;
    lookupTable[HASH(10, 12)] = 2;
    lookupTable[HASH(13, 12)] = 2;
    lookupTable[HASH(2, 13)] = 2;
    lookupTable[HASH(12, 13)] = 2;*/
    static const char lookupTable[255] = {1,1,1,1,1,1,3,1,3,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,1,2,1,1,2,1,1,1,1,1,3,1,1,1,1,1,1,1,3,1,1,1,1,1,1,2,1,1,1,2,1,2,1,1,1,2,1,1,1,1,1,1,1,1,3,1,1,1,3,1,1,1,1,1,1,3,1,1,1,2,1,1,1,1,1,2,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,1,1,2,1,1,1,1,1,2,1,1,1,3,1,1,1,1,1,1,3,1,1,1,3,1,1,1,1,1,1,1,1,2,1,1,1,2,1,2,1,1,1,2,1,1,1,1,1,1,3,1,1,1,1,1,1,1,3,1,1,1,1,1,2,1,1,2,1,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,3,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};


    return valuel(letter) * lookupTable[hash];
}

int scoreSquare(char letter, int x, int y) {
    return scoreSquareHash(letter, HASH(x, y));
}

int wordMultiplierHash(int hash) {
    /*static char lookupTable[255];
     for(int i = 0; i < 255; i++) {
     lookupTable[i] = 1;
     }
    lookupTable[HASH(3, 0)] = 3;
    lookupTable[HASH(11, 0)] = 3;
    lookupTable[HASH(0, 3)] = 3;
    lookupTable[HASH(14, 3)] = 3;
    lookupTable[HASH(0, 11)] = 3;
    lookupTable[HASH(14, 11)] = 3;
    lookupTable[HASH(3, 14)] = 3;
    lookupTable[HASH(11, 14)] = 3;
    lookupTable[HASH(5, 1)] = 2;
    lookupTable[HASH(9, 1)] = 2;
    lookupTable[HASH(7, 3)] = 2;
    lookupTable[HASH(1, 5)] = 2;
    lookupTable[HASH(13, 5)] = 2;
    lookupTable[HASH(3, 7)] = 2;
    lookupTable[HASH(11, 7)] = 2;
    lookupTable[HASH(1, 9)] = 2;
    lookupTable[HASH(13, 9)] = 2;
    lookupTable[HASH(7, 11)] = 2;
    lookupTable[HASH(5, 13)] = 2;
    lookupTable[HASH(9, 13)] = 2;*/
    static const char lookupTable[255] = {1,1,1,3,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,2,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,2,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,2,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,2,1,1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};

    return lookupTable[hash];
}

int wordMultiplier(int x, int y) {
    return wordMultiplierHash(HASH(x, y));
}

int prescoreWord(const char word[BOARD_LENGTH + 1], const int length) {
    assert(length <= BOARD_LENGTH);
    int ret = 0;
    for(int i = 0; i < length; i++) {
        ret += valuel(word[i]);
    }
    return ret;
}

int scoreLettersWithPrescore(const int prescore, const int length, char chars[NUM_LETTERS_TURN], int offsets[NUM_LETTERS_TURN], const int baseHash) {
    int val = prescore;
    int mult = 1;

    //score the letters and note the word multipliers
    for(int i = 0; i < length; ++i) {
        assert(chars[i] <= 'z' && chars[i] >= 'A');
        val += scoreSquarePrescoredHash(chars[i], baseHash + offsets[i]);
        mult *= wordMultiplierHash(baseHash + offsets[i]);
    }

    return val * mult;
}

bool isBonusSquareHash(int hash) {
    switch(hash) {
        case HASH(6, 0):
        case HASH(8, 0):
        case HASH(3, 3):
        case HASH(11, 3):
        case HASH(5, 5):
        case HASH(9, 5):
        case HASH(0, 6):
        case HASH(14, 6):
        case HASH(0, 8):
        case HASH(14, 8):
        case HASH(5, 9):
        case HASH(9, 9):
        case HASH(3, 11):
        case HASH(11, 11):
        case HASH(6, 14):
        case HASH(8, 14):
        case HASH(2, 1):
        case HASH(12, 1):
        case HASH(1, 2):
        case HASH(4, 2):
        case HASH(10, 2):
        case HASH(13, 2):
        case HASH(2, 4):
        case HASH(6, 4):
        case HASH(8, 4):
        case HASH(12, 4):
        case HASH(4, 6):
        case HASH(10, 6):
        case HASH(4, 8):
        case HASH(10, 8):
        case HASH(2, 10):
        case HASH(6, 10):
        case HASH(8, 10):
        case HASH(12, 10):
        case HASH(1, 12):
        case HASH(4, 12):
        case HASH(10, 12):
        case HASH(13, 12):
        case HASH(2, 13):
        case HASH(12, 13):
        case HASH(3, 0):
        case HASH(11, 0):
        case HASH(0, 3):
        case HASH(14, 3):
        case HASH(0, 11):
        case HASH(14, 11):
        case HASH(3, 14):
        case HASH(11, 14):
        case HASH(5, 1):
        case HASH(9, 1):
        case HASH(7, 3):
        case HASH(1, 5):
        case HASH(13, 5):
        case HASH(3, 7):
        case HASH(11, 7):
        case HASH(1, 9):
        case HASH(13, 9):
        case HASH(7, 11):
        case HASH(5, 13):
        case HASH(9, 13):
            return true;
        default:
            return false;
    }
}

bool isBonusSquare(int x, int y) {
    return isBonusSquareHash(HASH(x, y));
}

bool isLetterBonusSquareHash(int hash) {
    switch(hash) {
        case HASH(6, 0):
        case HASH(8, 0):
        case HASH(3, 3):
        case HASH(11, 3):
        case HASH(5, 5):
        case HASH(9, 5):
        case HASH(0, 6):
        case HASH(14, 6):
        case HASH(0, 8):
        case HASH(14, 8):
        case HASH(5, 9):
        case HASH(9, 9):
        case HASH(3, 11):
        case HASH(11, 11):
        case HASH(6, 14):
        case HASH(8, 14):
        case HASH(2, 1):
        case HASH(12, 1):
        case HASH(1, 2):
        case HASH(4, 2):
        case HASH(10, 2):
        case HASH(13, 2):
        case HASH(2, 4):
        case HASH(6, 4):
        case HASH(8, 4):
        case HASH(12, 4):
        case HASH(4, 6):
        case HASH(10, 6):
        case HASH(4, 8):
        case HASH(10, 8):
        case HASH(2, 10):
        case HASH(6, 10):
        case HASH(8, 10):
        case HASH(12, 10):
        case HASH(1, 12):
        case HASH(4, 12):
        case HASH(10, 12):
        case HASH(13, 12):
        case HASH(2, 13):
        case HASH(12, 13):
            return true;
        default:
            return false;
    }
}

bool isLetterBonusSquare(int x, int y) {
    return isLetterBonusSquareHash(HASH(x, y));
}

#pragma mark - Validation

void subwordsAtLocation(DictionaryIterator *itr, NSMutableSet **ret, char word[BOARD_LENGTH + 1], const int length) {
    if(length <= NUM_LETTERS_TURN) {
        return [*ret addObject:[WordStructure wordAsLetters:word length:length]];
    }
    
    //max in my testing is 25
#define NUM_SUBWORDS 32
    assert(NUM_SUBWORDS <= sizeof(int) * CHAR_BIT);
    Subword subwords[NUM_SUBWORDS];
    int numSubwords = 0;
    for(int i = 0; i < length - 1; ++i) { //wwf doesn't acknowledge single letter words
        const char *subword = &word[i];
        for(int j = i + 2; j < length; ++j) {
            if(!isValidPrefix(itr->mgr, subword, j - i)) {
                break;
            }
            if(isPrefixWord(itr->mgr, subword, j - i)) {
                assert(numSubwords < NUM_SUBWORDS);
                Subword sub = {.start = i, .end = j};
                subwords[numSubwords++] = sub;
            }
        }
    }
    
    const int count = (int)exp2(numSubwords);
    for(int powerset = 0; powerset < count; ++powerset) {
        Subword comboSubwords[BOARD_LENGTH / 2];
        int comboSubwordsLength = 0;
        int lastEnd = 0;
        for(int i = 1, index = 0; index < numSubwords; i <<= 1, ++index) {
            if(i & powerset) {
                Subword s = subwords[index];
                if(s.start < lastEnd) {
                    goto OVERLAP;
                } else {
                    lastEnd = s.end;
                }
                comboSubwords[comboSubwordsLength++] = s;
            }
        }
        [*ret addObjectsFromArray:[WordStructure validateWord:word length:length subwords:comboSubwords length:comboSubwordsLength iterator:itr]];
    OVERLAP:;
    }
#undef NUM_SUBWORDS
}

BOOL playable(char *word, const int length, const WordInfo *info) {
    return YES;
}