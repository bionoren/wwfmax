//
//  functions.h
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#ifndef FUNCTIONS_WWFMAX
#define FUNCTIONS_WWFMAX

#import "Subword.h"
#import "WordStructure.h"

#define NUM_LETTERS_TURN 7
#define LETTER_OFFSET 97

#define HASH(x, y) ((y << 4) | x)
#define X_FROM_HASH(hash) (hash >> 4)
#define Y_FROM_HASH(hash) (hash & 31)

static const NSComparator alphSort = ^NSComparisonResult(id obj1, id obj2) {
    return [obj1 compare:obj2];
};

#pragma mark - Scoring

static unsigned int valuel(char letter) {
    switch(letter) {
        case 'a':
            return 1;
        case 'b':
            return 4;
        case 'c':
            return 4;
        case 'd':
            return 2;
        case 'e':
            return 1;
        case 'f':
            return 4;
        case 'g':
            return 3;
        case 'h':
            return 3;
        case 'i':
            return 1;
        case 'j':
            return 10;
        case 'k':
            return 5;
        case 'l':
            return 2;
        case 'm':
            return 4;
        case 'n':
            return 2;
        case 'o':
            return 1;
        case 'p':
            return 4;
        case 'q':
            return 10;
        case 'r':
            return 1;
        case 's':
            return 1;
        case 't':
            return 1;
        case 'u':
            return 2;
        case 'v':
            return 5;
        case 'w':
            return 4;
        case 'x':
            return 8;
        case 'y':
            return 3;
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

static BOOL validate(NSString *word, NSArray **words, NSRange *range) {
    assert([word isEqualToString:word.lowercaseString]);
    return [*words indexOfObject:word inSortedRange:*range options:NSBinarySearchingFirstEqual usingComparator:alphSort] != NSNotFound;
}

static BOOL subwordSearch(NSString *word, NSArray **words, NSRange *range, int freeLetters) {
    if(word.length <= freeLetters) {
        return YES;
    }
    
    //greedy works most of the time, so start there
    for(int i = (int)MIN(NUM_LETTERS_TURN, word.length); i > 0; --i) {
        if(validate([word substringToIndex:i], words, range)) {
            if(subwordSearch([word substringFromIndex:i], words, range, freeLetters)) {
                return YES;
            }
        }
    }
    if(freeLetters == 0) {
        return NO;
    }
    return subwordSearch([word substringFromIndex:1], words, range, freeLetters - 1);
}

static NSSet *subwordsAtLocation(NSString *word, NSArray **words, NSRange *range, int x, int y) {
    const int length = (int) word.length;
    if(length <= NUM_LETTERS_TURN) {
        return [NSSet setWithObject:[WordStructure wordAsLetters:word x:x y:y]];
    }
    
    NSMutableArray *subwords = [NSMutableArray array];
    for(int i = 0; i < length; i++) {
        const int tmpLength = MIN(i + NUM_LETTERS_TURN, length);
        for(int j = i + 1; j < tmpLength; j++) {
            if(i == 0 && j + 1 == length) {
                continue;
            }
            NSString *subword = [word substringWithRange:NSMakeRange(i, j - i)];
            if(validate(subword, words, range)) {
                [subwords addObject:[Subword subwordWithWord:subword start:i end:j]];
            }
        }
    }
    //max in my testing is 25
    if(subwords.count == 0) {
        return nil;
    }
    
    const unsigned int count = exp2(subwords.count);
    NSMutableSet *ret = [NSMutableSet setWithCapacity:count - 1];
    for(unsigned int powerset = 1; powerset < count; powerset++) {
        WordStructure *wordStruct = [[WordStructure alloc] initWithWord:word];
        for(unsigned int i = 1, index = 0; index < subwords.count; i <<= 1, index++) {
            if(i & powerset) {
                if(![wordStruct addSubword:[subwords objectAtIndex:index] words:words range:range]) {
                    wordStruct = nil;
                    break;
                }
            }
        }
        NSArray *words = [wordStruct validate];
        if(words) {
            [ret addObjectsFromArray:words];
        }
    }
    
    return ret;
}

static BOOL filterValidate(NSString *word, NSArray *words, NSRange range) {
    if(word.length > 15) {
        NSLog(@"%@ is too long to play", word);
        return NO;
    }
    //ensure the word can be spelled in sequences of NUM_LETTERS_TURN letters (or less)
    if(!subwordSearch(word, &words, &range, NUM_LETTERS_TURN)) {
        NSLog(@"Couldn't break down %@", word);
        return NO;
    }
    return YES;
}

#endif