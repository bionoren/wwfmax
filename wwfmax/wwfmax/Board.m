//
//  Board.m
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import "Board.h"
#import "functions.h"

#define NUM_LETTERS 27
#define DEFAULT_CHAR '.'

#define BOARD_COORDINATE(xvar, yvar) ((xvar) + (yvar) * BOARD_LENGTH)

#define RESET_LETTERS memcpy(_letters, letterCounts, NUM_LETTERS * sizeof(int))

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
        RESET_LETTERS;
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
-(Solution)solve:(Dictionaries)dicts; {
    Solution ret;
    ret.maxScore = 0;

    DictionaryIterator *verticalItrs[NUM_LETTERS_TURN][3];
    VerticalState verticalState[NUM_LETTERS_TURN] = {{0, 0}};
    for(int i = 0; i < NUM_LETTERS_TURN; i++) {
        verticalItrs[i][0] = createDictIterator(dicts.pwords); //for building the bottom word [fragment]
        verticalItrs[i][1] = createDictIterator(dicts.rwords); //for completing the bottom fragment
        verticalItrs[i][2] = createDictIterator(dicts.rwords); //for building the top word
    }
    assert(BOARD_LENGTH + 1 == 16 && sizeof(int) == 4);
    char vwords[NUM_LETTERS_TURN][BOARD_LENGTH + 1];
    int vlengths[NUM_LETTERS_TURN] = {0};

    NSMutableSet *playableWords = [NSMutableSet set];
    assert(BOARD_LENGTH + 1 == 16 && sizeof(int) == 4);
    char word[BOARD_LENGTH + 1] = {0};
    int length;
    while((length = nextWord_threadsafe(dicts.words, word))) {
        NSLog(@"Evaluating %.*s\n", length, word);
        @autoreleasepool {
            const int prescore = prescoreWord(word, length);

            subwordsAtLocation(dicts.words, &playableWords, word, length);
            if(playableWords.count == 0) {
                continue;
            }
            
            for(WordStructure *wordStruct in playableWords) {
                assert(wordStruct->_numLetters > 0);
                if([self validateLetters:wordStruct->_letters length:wordStruct->_numLetters]) {
#if DEBUG
                    for(int j = 0; j < wordStruct->_numSubwords; ++j) {
                        Subword subword = wordStruct->_subwords[j];
                        assert(subword.start < subword.end);
                        int subwordLen = subword.end - subword.start;
                        char *subwordPointer = &(wordStruct->_word[subword.start]);
                        assert([self testValidate:subwordPointer length:subwordLen]);
                    }
#endif
                    char chars[NUM_LETTERS_TURN]; //letters being played
                    int locs[NUM_LETTERS_TURN]; //offsets of said letters (within the word)
                    for(int j = 0; j < wordStruct->_numLetters; ++j) {
                        Letter l = wordStruct->_letters[j];
                        chars[j] = (char)Y_FROM_HASH(l);
                        locs[j] = X_FROM_HASH(l);
                    }

                    int numCharGroups = 0;
                    int charGroupSize[NUM_LETTERS_TURN] = {0};
                    char charGroups[NUM_LETTERS_TURN][NUM_LETTERS_TURN] = {'\0'};
                    for(int j = 0; j < wordStruct->_numLetters; j++) {
                        charGroups[numCharGroups][charGroupSize[numCharGroups]++] = chars[j];
                        if(j + 1 == wordStruct->_numLetters || locs[j + 1] - locs[j] != 1) {
                            numCharGroups++;
                        }
                    }
                    assert(numCharGroups > 0);
                    
                    int bonus = (wordStruct->_numLetters == NUM_LETTERS_TURN)?35:0;
                    
                    for(int y = 0; y < BOARD_LENGTH; ++y) {
                        if(y % 2 == 1 || (y != 0 && y != 14)) { //high scoring plays will involve a word multiplier
                            continue;
                        }
                        for(int x = 0; x < BOARD_LENGTH - length; ++x) {
                            int wordScore = scoreLettersWithPrescore(prescore, wordStruct->_numLetters, chars, locs, x, y) + bonus;

                            for(int j = 0; j < wordStruct->_numLetters; j++) {
                                loadPrefix(verticalItrs[j][0], &chars[j], 1);
                                loadPrefix(verticalItrs[j][2], &chars[j], 1);
                            }

                            int baseIndex = 0;
                            for(int j = 0; j < numCharGroups; j++) {
                                while(true) {
                                    //do work here

                                    vlengths[baseIndex] = nextVerticalWord(verticalItrs[baseIndex], verticalState[baseIndex], vwords[baseIndex], y);
                                    for(int k = 0; !vlengths[baseIndex + k];) {
                                        //nextVerticalWord handles its own resetting
                                        k++;
                                        //this exits the loop
                                        if(k == charGroupSize[j]) goto PERMUTATION_END;
                                        vlengths[baseIndex + k] = nextVerticalWord(verticalItrs[baseIndex + k], verticalState[baseIndex + k], vwords[baseIndex + k], y);
                                    }
                                }
                            PERMUTATION_END:;
                            }

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
                RESET_LETTERS;
            }
            [playableWords removeAllObjects];
        }
    }
    return ret;
}

typedef struct {
    int state;
    int prefixLength;
} VerticalState;

/**
[o]
 word
 n
 e
 d

 wned is the generated partial validation from dictPermuted
 use the reverse dictionary to walk all the combinations from "denw*" to get to the top (like [o] for "owned")

 This will cover all the bottom words and top/bottom combo words, leaving just the top-only scenario
 */
int nextVerticalWord(DictionaryIterator *restrict*restrict iterators, VerticalState state, char *word, int y) {
    int ret = 0;
    switch(state.state) {
        case 0:
            if(BOARD_LENGTH - (y + 1) >= 2) {
                //TODO: Handle the bottom/top combo case
                if(state.prefixLength) {
                COMPLETE_WORD:;
                    do {
                        ret = nextWordWithPrefix(iterators[1], word, y + state.prefixLength);
                    } while(ret && ret - state.prefixLength <= y - 1);
                    if(ret) {
                        return ret;
                    }
                }

                ret = nextWordWithPrefix(iterators[0], word, BOARD_LENGTH - (y + 1));
                if(!ret) {
                    resetIteratorToPrefix(iterators[0]);
                    state.state++;
                    state.prefixLength = 0;
                } else {
                    assert(isValidWord(iterators[0]->mgr, word, ret));
                    assert(ret <= BOARD_LENGTH - (y + 1));
                    for(int i = 0; i < ret / 2; ++i) { //strrev in place
                        word[i] ^= word[ret - 1 - i];
                        word[ret - 1 - i] ^= word[i];
                        word[i] ^= word[ret - 1 - i];
                    }
                    state.prefixLength = ret;
                    bool success = loadPrefix(iterators[1], word, ret);
                    assert(success);
                    if(isValidWord(iterators[1]->mgr, word, ret)) {
                        return ret;
                    } else {
                        goto COMPLETE_WORD;
                    }
                }
            } else {
                state.state++;
            }
        case 1:
            if(y - 1 >= 2) {
                ret = nextWordWithPrefix(iterators[2], word, y - 1);
                if(!ret) {
                    resetIteratorToPrefix(iterators[2]);
                    state.state++;
                } else {
                    assert(ret <= y - 1);
                    return ret;
                }
            } else {
                state.state++;
            }
        case 2:
            state.state = 0;
            return ret;
        default:
            return -1;
    }
}

#pragma mark - Validation

-(BOOL)validateLetters:(Letter*restrict)letters length:(int)length {
    BOOL ret = YES;
    for(int i = 0; i < length; i++) {
        Letter l = letters[i];
        char c = (char)Y_FROM_HASH(l);
        int index = c - LETTER_OFFSET_LC + 1;
        assert(index > 0);
        if(self.letters[index]-- > 0) {
        } else if(self.letters[0]-- > 0) {
            letters[i] = (typeof(Letter))HASH(X_FROM_HASH(l), (index + LETTER_OFFSET_UC - 1));
            assert(Y_FROM_HASH(letters[i]) >= 'A' && Y_FROM_HASH(letters[i]) <= 'Z');
        } else {
            ret = NO;
            break;
        }
    }
    return ret;
}

-(BOOL)testValidate:(char*restrict)word length:(int)length {
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
    RESET_LETTERS;
    NSAssert(self.letters[1] == 9, @"self.letters[1] = %d, self.letters[4] = %d", self.letters[1], self.letters[4]);
    return ret;
}

#pragma mark - Scoring

-(void)addSubword:(char*restrict)word length:(int)length board:(char*restrict)board x:(int)x y:(int)y {
    int start = BOARD_COORDINATE(x, y);
    memcpy(&(board[start]), word, length * sizeof(char));
}

-(void)clearBoard:(char*restrict)board {
    memcpy(board, blankBoard, BOARD_LENGTH * BOARD_LENGTH * sizeof(char));
}

#pragma mark - Debug / Helper

+(NSString*)debugBoard:(char*)board {
    NSMutableString *ret = [[NSMutableString alloc] initWithString:@"\n"];
    for(int y = 0; y < BOARD_LENGTH; y++) {
        for(int x = 0; x < BOARD_LENGTH; x++) {
            char c = board[BOARD_COORDINATE(x, y)];
            if(x == BOARD_LENGTH / 2 && y == BOARD_LENGTH / 2 && c == '.') {
                c = '*';
            }
            [ret appendFormat:@"%c", c];
        }
        [ret appendString:@"\n"];
    }
    return ret;
}

@end