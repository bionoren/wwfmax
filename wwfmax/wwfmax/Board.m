//
//  Board.m
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import "Board.h"
#import "functions.h"
#import "DictionaryManager.h"

#define NUM_LETTERS 27
#define DEFAULT_CHAR '.'

#define BOARD_COORDINATE(xvar, yvar) ((xvar) + (yvar) * BOARD_LENGTH)

/**
 Note that capital letters are used to represent blanks
 */

//ascii value, 'a'=>1
static const int letterCounts[] = {
    2, //blanks
    9, //a
    2, //b
    2, //c
    5, //d
    13,//e
    2, //f
    3, //g
    4, //h
    8, //i
    1, //j
    1, //k
    4, //l
    2, //m
    5, //n
    8, //o
    2, //p
    1, //q
    6, //r
    5, //s
    7, //t
    4, //u
    2, //v
    2, //w
    1, //x
    2, //y
    1  //z
};

static const char blankBoard[BOARD_LENGTH * BOARD_LENGTH] = { [0 ... BOARD_LENGTH * BOARD_LENGTH - 1] = DEFAULT_CHAR };

@interface Board ()

@property (nonatomic) int *letters;

@end

@implementation Board

-(id)init {
    if(self = [super init]) {
        _letters = calloc(NUM_LETTERS, sizeof(int));
        memcpy(_letters, letterCounts, NUM_LETTERS * sizeof(int));
        NSAssert(self.letters[1] == 9, @"self.letters[1] = %d, self.letters[4] = %d", self.letters[1], self.letters[4]);
    }
    return self;
}

-(void)dealloc {
    free(_letters);
    _letters = NULL;
}

/**
 I'm strictly interested in the top half of the board and horizontal words because of bonus tile symetry.
 */
-(Solution)solve:(const int*)prescores {
    Solution ret;
    ret.maxScore = 0;
    
    NSMutableSet *playableWords = [NSMutableSet set];
    char word[15];
    int length;
    while((length = nextWord(word))) {
        continue;
        @autoreleasepool {
            const int prescore = prescores[hashWord(word, length)];

            subwordsAtLocation(&playableWords, word, length);
            if(playableWords.count == 0) {
                continue;
            }
            
            for(WordStructure *wordStruct in playableWords) {
                assert(wordStruct->_numLetters > 0);
                if([self validateLetters:wordStruct->_letters length:wordStruct->_numLetters]) {
                    for(int j = 0; j < wordStruct->_numSubwords; ++j) {
                        Subword subword = wordStruct->_subwords[j];
                        assert(subword.start < subword.end);
                        int subwordLen = subword.end - subword.start;
                        char *subwordPointer = &(wordStruct->_word[subword.start]);
                        if(![self testValidate:subwordPointer length:subwordLen]) {
                            goto SUBWORD_FAIL;
                        }
                    }
                    
                    char chars[NUM_LETTERS_TURN];
                    int locs[NUM_LETTERS_TURN];
                    for(int tmp = 0; tmp < wordStruct->_numLetters; ++tmp) {
                        Letter l = wordStruct->_letters[tmp];
                        chars[tmp] = (char)Y_FROM_HASH(l);
                        locs[tmp] = X_FROM_HASH(l);
                    }
                    
                    int bonus = (wordStruct->_numLetters == NUM_LETTERS_TURN)?35:0;
                    
                    for(int y = 0; y < BOARD_LENGTH; ++y) {
                        for(int x = 0; x < BOARD_LENGTH - length; ++x) {
                            int wordScore = scoreLettersWithPrescore(prescore, wordStruct->_numLetters, chars, locs, x, y) + bonus;
                            
                            if(wordScore > ret.maxScore) {
                                ret.maxScore = wordScore;
                                
                                [self clearBoard:ret.maxBoard];
                                for(int j = 0; j < wordStruct->_numSubwords; ++j) {
                                    Subword subword = wordStruct->_subwords[j];
                                    int subwordLen = subword.end - subword.start;
                                    char *subwordPointer = &(wordStruct->_word[subword.start]);
                                    [self addSubword:subwordPointer length:subwordLen board:ret.maxBoard x:x + subword.start y:y];
                                }
                                memcpy(ret.maxLetters, wordStruct->_letters, wordStruct->_numLetters * sizeof(Letter));
                                memcpy(ret.maxWord, word, length * sizeof(char));
                                ret.maxWordLength = length;
                                ret.numMaxLetters = wordStruct->_numLetters;
                                ret.maxx = x;
                                ret.maxy = y;
#ifdef DEBUG
                                printSolution(ret);
#endif
                            }
                        }
                    }
                }
                SUBWORD_FAIL:
                ;
            }
            [playableWords removeAllObjects];
        }
        //NSLog(@"%.2f%% complete...", i / (float)numWords * 100.0);
    }
    return ret;
}

#pragma mark - Validation

-(BOOL)validateLetters:(Letter*)letters length:(int)length {
    BOOL ret = YES;
    for(int i = 0; i < length; i++) {
        Letter l = letters[i];
        char c = (char)Y_FROM_HASH(l);
        int index = c - LETTER_OFFSET_LC + 1;
        assert(index > 0);
        if(self.letters[index]-- > 0) {
        } else if(self.letters[0]-- > 0) {
            letters[i] = HASH(X_FROM_HASH(l), index + LETTER_OFFSET_UC - 1);
            assert(Y_FROM_HASH(letters[i]) >= 'A' && Y_FROM_HASH(letters[i]) <= 'Z');
        } else {
            ret = NO;
            break;
        }
    }
    memcpy(_letters, letterCounts, NUM_LETTERS * sizeof(int));
    NSAssert(self.letters[1] == 9, @"self.letters[1] = %d, self.letters[4] = %d", self.letters[1], self.letters[4]);
    return ret;
}

-(BOOL)testValidate:(char*)word length:(int)length {
    BOOL ret = YES;
    //ensure we have enough letters to spell this word
    for(int i = 0; i < length; i++) {
        char c = word[i];
        int index = c - LETTER_OFFSET_LC + 1;
        if(self.letters[index]-- > 0) {
        } else if(self.letters[0]-- > 0) {
            word[i] = (char)(index + LETTER_OFFSET_LC - 1);
        } else {
            ret = NO;
            break;
        }
    }
    memcpy(_letters, letterCounts, NUM_LETTERS * sizeof(int));
    NSAssert(self.letters[1] == 9, @"self.letters[1] = %d, self.letters[4] = %d", self.letters[1], self.letters[4]);
    return ret;
}

#pragma mark - Scoring

-(void)addSubword:(char*)word length:(int)length board:(char*)board x:(int)x y:(int)y {
    int start = BOARD_COORDINATE(x, y);
    memcpy(&(board[start]), word, length * sizeof(char));
}

-(void)clearBoard:(char*)board {
    memcpy(board, blankBoard, BOARD_LENGTH * BOARD_LENGTH * sizeof(char));
}

#pragma mark - Debug / Helper

+(NSString*)debugBoard:(char*)board {
    NSMutableString *ret = [[NSMutableString alloc] initWithString:@"\n"];
    for(int y = 0; y < BOARD_LENGTH; y++) {
        for(int x = 0; x < BOARD_LENGTH; x++) {
            char c = board[BOARD_COORDINATE(x, y)];
            [ret appendFormat:@"%c", c];
        }
        [ret appendString:@"\n"];
    }
    return ret;
}

@end