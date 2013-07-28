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
            return valuel(letter)*2;
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
            return ret*3;
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
        case HASH(3, 0):
        case HASH(11, 0):
        case HASH(0, 3):
        case HASH(14, 3):
        case HASH(0, 11):
        case HASH(14, 11):
        case HASH(3, 14):
        case HASH(11, 14):
            return 3;
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
            return 2;
        default:
            return 1;
    }
}

int wordMultiplier(int x, int y) {
    return wordMultiplierHash(HASH(x, y));
}

int prescoreWord(const char *restrict word, const int length) {
    int ret = 0;
    for(int i = 0; i < length; i++) {
        ret += valuel(word[i]);
    }
    return ret;
}

int scoreLettersWithPrescore(const int prescore, const int length, char *restrict chars, int *restrict offsets, const int baseHash) {
    int val = prescore;
    int mult = 1;

    //score the letters and note the word multipliers
    assert(length >= 2 && length <= NUM_LETTERS_TURN);
    switch(length) {
        case 7:
            assert(chars[6] <= 'z' && chars[6] >= 'A');
            val += scoreSquarePrescoredHash(chars[6], baseHash + offsets[6]);
            mult *= wordMultiplierHash(baseHash + offsets[6]);
        case 6:
            assert(chars[5] <= 'z' && chars[5] >= 'A');
            val += scoreSquarePrescoredHash(chars[5], baseHash + offsets[5]);
            mult *= wordMultiplierHash(baseHash + offsets[5]);
        case 5:
            assert(chars[4] <= 'z' && chars[4] >= 'A');
            val += scoreSquarePrescoredHash(chars[4], baseHash + offsets[4]);
            mult *= wordMultiplierHash(baseHash + offsets[4]);
        case 4:
            assert(chars[3] <= 'z' && chars[3] >= 'A');
            val += scoreSquarePrescoredHash(chars[3], baseHash + offsets[3]);
            mult *= wordMultiplierHash(baseHash + offsets[3]);
        case 3:
            assert(chars[2] <= 'z' && chars[2] >= 'A');
            val += scoreSquarePrescoredHash(chars[2], baseHash + offsets[2]);
            mult *= wordMultiplierHash(baseHash + offsets[2]);
        case 2:
            break;  
    }
    assert(chars[1] <= 'z' && chars[1] >= 'A');
    val += scoreSquarePrescoredHash(chars[1], baseHash + offsets[1]);
    mult *= wordMultiplierHash(baseHash + offsets[1]);
    assert(chars[0] <= 'z' && chars[0] >= 'A');
    val += scoreSquarePrescoredHash(chars[0], baseHash + offsets[0]);
    mult *= wordMultiplierHash(baseHash + offsets[0]);

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

BOOL validate(const char *restrict word, const int length, const WordInfo *info) {
    // inclusive indices
    //   0 <= imin when using truncate toward zero divide
    //     imid = (imin+imax)/2;
    //   imin unrestricted when using truncate toward minus infinity divide
    //     imid = (imin+imax)>>1; or
    //     imid = (int)floor((imin+imax)/2.0);
    
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
    
    // deferred test for equality
    if(imax == imin && info->lengths[imin] == length && strncmp(&(info->words[imin * BOARD_LENGTH]), word, length) == 0) {
        return YES;
    } else {
        return NO;
    }
}

void subwordsAtLocation(DictionaryIterator *itr, NSMutableSet **ret, char *restrict word, const int length) {
    if(length <= NUM_LETTERS_TURN) {
        return [*ret addObject:[WordStructure wordAsLetters:word length:length]];
    }
    
    //max in my testing is 25
#define NUM_SUBWORDS 32
    assert(NUM_SUBWORDS <= sizeof(int) * CHAR_BIT);
    Subword subwords[NUM_SUBWORDS];
    int numSubwords = 0;
    for(int i = 0; i < length - 1; ++i) { //wwf doesn't acknowledge single letter words
        const int tmpLength = MIN(i + NUM_LETTERS_TURN, length - 1);
        for(int j = i + 2; j < tmpLength; ++j) {
            const char *subword = &word[i];
            if(isValidWord(itr->mgr, subword, j - i)) {
                assert(numSubwords < NUM_SUBWORDS);
                Subword sub = {.start = i, .end = j};
                subwords[numSubwords++] = sub;
            }
        }
    }
    
    const int count = (int)exp2(numSubwords);
    for(int powerset = 0; powerset < count; powerset++) {
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
        [*ret addObjectsFromArray:[WordStructure validateWord:word length:length subwords:comboSubwords length:comboSubwordsLength iterator:itr wordInfo:NULL]];
    OVERLAP:;
    }
#undef NUM_SUBWORDS
}

BOOL playable(char *word, const int length, const WordInfo *info) {
    return YES;
}