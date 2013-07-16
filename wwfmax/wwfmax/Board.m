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

static int maxBaseScore = 0;
static int maxBonusTileScores[BOARD_LENGTH * BOARD_LENGTH][26] = {0};

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

+(void)loadPreprocessedData:(PreprocessedData*)data {
    maxBaseScore = data->maxBaseScore;
    memcpy(maxBonusTileScores, data->maxBonusTileScores, BOARD_LENGTH * BOARD_LENGTH * 26 * sizeof(int));

#ifdef DEBUG
    printf("Max base score = %d\n", maxBaseScore);
#endif
}

-(PreprocessedData*)preprocess:(Dictionaries)dicts {
    PreprocessedData *ret = calloc(1, sizeof(PreprocessedData));
#ifdef DEBUG
    int maxPrescore;
#endif
    assert(ret);

    NSMutableSet *playableWords = [NSMutableSet set];
    assert(BOARD_LENGTH + 1 == 16 && sizeof(int) == 4);
    char word[BOARD_LENGTH + 1] = {0};
    int length;
    while((length = nextWord_threadsafe(dicts.words, word))) {
        //NSLog(@"Evaluating %.*s\n", length, word);
        @autoreleasepool {
            subwordsAtLocation(dicts.words, &playableWords, word, length);
            assert(playableWords.count > 0);

            for(WordStructure *wordStruct in playableWords) {
                assert(wordStruct->_numLetters > 0);
                assert([self validateLetters:wordStruct->_letters length:wordStruct->_numLetters]);
#if DEBUG
                for(int i = 0; i < wordStruct->_numSubwords; ++i) {
                    Subword subword = wordStruct->_subwords[i];
                    assert(subword.start < subword.end);
                    int subwordLen = subword.end - subword.start;
                    char *subwordPointer = &(wordStruct->_word[subword.start]);
                    assert([self testValidate:subwordPointer length:subwordLen]);
                }
#endif
                //letter allocation and caching
                char chars[NUM_LETTERS_TURN]; //letters being played
                int locs[NUM_LETTERS_TURN]; //offsets of said letters (within the word)
                int prescore = prescoreWord(word, length);
                for(int i = 0; i < wordStruct->_numLetters; ++i) {
                    Letter l = wordStruct->_letters[i];
                    chars[i] = (char)Y_FROM_HASH(l);
                    locs[i] = X_FROM_HASH(l);
                    if(chars[i] < LETTER_OFFSET_LC) {
                        prescore -= valuel(word[locs[i]]);
                    }
                }

                for(int i = 0, j = 0; i < length; i++) {
                    if(j < wordStruct->_numLetters && locs[j] == i) {
                        j++;
                        continue;
                    }
                    Letter l = (typeof(Letter))HASH(i, word[i]);
                    bool valid = [self validateLetters:&l length:1];
                    word[i] = (char)Y_FROM_HASH(l);
                    if(word[i] < LETTER_OFFSET_LC) {
                        prescore -= valuel(word[i]);
                    }
                    assert(valid);
                }
#ifdef DEBUG
                if(prescore > maxPrescore) {
                    maxPrescore = prescore;
                }
#endif

                int bonus = (wordStruct->_numLetters == NUM_LETTERS_TURN)?35:0;

                for(int y = 0; y < BOARD_LENGTH; ++y) {
                    if(y % 2 == 0 && (y != 0 && y != 14)) {
                        continue;
                    }
                    for(int x = 0; x < BOARD_LENGTH - length + 1; ++x) {
                        //get blank tiles off bonus letter squares
                        for(int i = 0; i < wordStruct->_numLetters; i++) {
                            if(chars[i] < LETTER_OFFSET_LC && isLetterBonusSquare(x + locs[i], y)) {
                                for(int j = 0; j < wordStruct->_numLetters; j++) {
                                    if(j == i) {
                                        continue;
                                    }
                                    if(!isLetterBonusSquare(x + locs[j], y)) {
                                        chars[j] ^= chars[i];
                                        chars[i] ^= chars[j];
                                        chars[j] ^= chars[i];
                                        break;
                                    }
                                    if(j + 1 == wordStruct->_numLetters) {
                                        abort(); //if it turns out with the latest dictionary that this is an irresolvable optimization, we'll at least find out early in preprocessing
                                    }
                                }
                            }
                        }

                        int wordScore = scoreLettersWithPrescore(prescore, wordStruct->_numLetters, chars, locs, x, y) + bonus;
                        for(int xb = 0; xb < wordStruct->_numLetters; xb++) {
                            int hash = HASH(x + locs[xb], y);
                            int index = y * BOARD_LENGTH + x + locs[xb];
                            assert(index < BOARD_LENGTH * BOARD_LENGTH && index >= 0);
                            int letterIndex = chars[xb] - LETTER_OFFSET_LC;
                            if(letterIndex < 0) {
                                letterIndex = chars[xb] - LETTER_OFFSET_UC;
                            }
                            assert(letterIndex < 26 && letterIndex >= 0);
                            int bonusScore = (prescore + scoreSquarePrescoredHash(chars[xb], hash)) * wordMultiplierHash(hash);
                            assert(isBonusSquareHash(hash) || (bonusScore == prescore && prescore <= maxPrescore));
                            if(bonusScore > ret->maxBonusTileScores[index][letterIndex]) {
                                ret->maxBonusTileScores[index][letterIndex] = bonusScore;
                            }
                        }

                        if(wordScore > ret->maxBaseScore) {
                            ret->maxBaseScore = wordScore;
                        }
                    }
                }
                RESET_LETTERS;
                for(int i = 0; i < length; i++) {
                    if(word[i] < LETTER_OFFSET_LC) {
                        word[i] = word[i] - LETTER_OFFSET_UC + LETTER_OFFSET_LC;
                    }
                }
            }
            [playableWords removeAllObjects];
        }
    }

    for(int i = 0; i < BOARD_LENGTH * BOARD_LENGTH; i++) {
        for(int j = 0; j < 26; j++) {
            assert(isBonusSquareHash(HASH(i % BOARD_LENGTH, i / BOARD_LENGTH)) || ret->maxBonusTileScores[i][j] <= maxPrescore);
        }
    }

    return ret;
}

/**
 I'm strictly interested in horizontal words because of bonus tile symetry.
 */
-(Solution)solve:(Dictionaries)dicts {
    assert(maxBaseScore); //need to run preprocess: first

    Solution ret;
    ret.maxScore = 0;

    /*DictionaryIterator *verticalItrs[NUM_LETTERS_TURN][3];
    VerticalState verticalState[NUM_LETTERS_TURN] = {{0, 0}};
    for(int i = 0; i < NUM_LETTERS_TURN; i++) {
        verticalItrs[i][0] = createDictIterator(dicts.pwords); //for building the bottom word
        verticalItrs[i][1] = createDictIterator(dicts.rwords); //for extending the bottom word to the top
        verticalItrs[i][2] = createDictIterator(dicts.rwords); //for building the top word
    }
    assert(BOARD_LENGTH + 1 == 16 && sizeof(int) == 4);
    char vwords[NUM_LETTERS_TURN][BOARD_LENGTH + 1];
    int vlengths[NUM_LETTERS_TURN] = {0};*/

    NSMutableSet *playableWords = [NSMutableSet set];
    assert(BOARD_LENGTH + 1 == 16 && sizeof(int) == 4);
    char word[BOARD_LENGTH + 1] = {0};
    int length;
    int temp = 0;
    while((length = nextWord_threadsafe(dicts.words, word))) {
        //NSLog(@"Evaluating %.*s\n", length, word);
        @autoreleasepool {
            subwordsAtLocation(dicts.words, &playableWords, word, length);
            assert(playableWords.count > 0);
            
            for(WordStructure *wordStruct in playableWords) {
                assert(wordStruct->_numLetters > 0);
                [self validateLetters:wordStruct->_letters length:wordStruct->_numLetters]; //assign tiles to the played letters first

                //letter allocation and caching
                char chars[NUM_LETTERS_TURN]; //letters being played
                int locs[NUM_LETTERS_TURN]; //offsets of said letters (within the word)
                int prescore = prescoreWord(word, length);
                for(int i = 0; i < wordStruct->_numLetters; ++i) {
                    Letter l = wordStruct->_letters[i];
                    chars[i] = (char)Y_FROM_HASH(l);
                    locs[i] = X_FROM_HASH(l);
                    if(chars[i] < LETTER_OFFSET_LC) {
                        prescore -= valuel(word[locs[i]]);
                    }
                }

                for(int i = 0, j = 0; i < length; i++) {
                    if(j < wordStruct->_numLetters && locs[j] == i) {
                        j++;
                        continue;
                    }
                    Letter l = (typeof(Letter))HASH(i, word[i]);
                    bool valid = [self validateLetters:&l length:1];
                    word[i] = (char)Y_FROM_HASH(l);
                    if(word[i] < LETTER_OFFSET_LC) {
                        prescore -= valuel(word[i]);
                    }
                    assert(valid);
                }

                /*int numCharGroups = 0;
                int charGroupSize[NUM_LETTERS_TURN] = {0};
                char charGroups[NUM_LETTERS_TURN][NUM_LETTERS_TURN] = {'\0'};
                for(int j = 0; j < wordStruct->_numLetters; j++) {
                    charGroups[numCharGroups][charGroupSize[numCharGroups]++] = chars[j];
                    if(j + 1 == wordStruct->_numLetters || locs[j + 1] - locs[j] != 1) {
                        numCharGroups++;
                    }
                }
                assert(numCharGroups > 0);*/
                
                int bonus = (wordStruct->_numLetters == NUM_LETTERS_TURN)?35:0;
                
                for(int y = 0; y < BOARD_LENGTH; ++y) {
                    if(y % 2 == 0 && (y != 0 && y != 14)) {
                        continue;
                    }
                    for(int x = 0; x < BOARD_LENGTH - length + 1; ++x) {
                        //get blank tiles off bonus letter squares
                        for(int i = 0; i < wordStruct->_numLetters; i++) {
                            if(chars[i] < LETTER_OFFSET_LC && isLetterBonusSquare(x + locs[i], y)) {
                                for(int j = 0; j < wordStruct->_numLetters; j++) {
                                    if(j == i) {
                                        continue;
                                    }
                                    if(!isLetterBonusSquare(x + locs[j], y)) {
                                        chars[j] ^= chars[i];
                                        chars[i] ^= chars[j];
                                        chars[j] ^= chars[i];
                                        break;
                                    }
                                }
                            }
                        }

                        int wordScore = scoreLettersWithPrescore(prescore, wordStruct->_numLetters, chars, locs, x, y) + bonus;
                        int maxTotalWordScore = wordScore;
                        for(int xb = 0; xb < wordStruct->_numLetters; xb++) {
                            int index = y * BOARD_LENGTH + x + locs[xb];
                            assert(index < BOARD_LENGTH * BOARD_LENGTH);
                            int letterIndex = chars[xb] - LETTER_OFFSET_LC;
                            if(letterIndex < 0) {
                                letterIndex = chars[xb] - LETTER_OFFSET_UC;
                            }
                            assert(letterIndex < 26 && letterIndex >= 0);
                            maxTotalWordScore += maxBonusTileScores[index][letterIndex];
                        }
                        if(maxTotalWordScore <= MAX(maxBaseScore, ret.maxScore)) {
                            continue;
                        }
                        temp++;

                        /*if(wordScore < prescore * 2) {
                            continue; //we didn't use a word multiplier
                        }
                        for(int j = 0; j < wordStruct->_numLetters; j++) {
                            loadPrefix(verticalItrs[j][0], &chars[j], 1);
                            loadPrefix(verticalItrs[j][2], &chars[j], 1);
                        }

                        int baseIndex = 0;
                        for(int j = 0; j < numCharGroups; j++) {
                            while(true) {
                                //do work here

                                vlengths[baseIndex] = nextVerticalWord(verticalItrs[baseIndex], &verticalState[baseIndex], vwords[baseIndex], y, dicts.words->mgr);
                                for(int k = 0; !vlengths[baseIndex + k];) {
                                    //nextVerticalWord handles its own resetting
                                    k++;
                                    //this exits the loop
                                    if(k == charGroupSize[j]) goto PERMUTATION_END;
                                    vlengths[baseIndex + k] = nextVerticalWord(verticalItrs[baseIndex + k], &verticalState[baseIndex + k], vwords[baseIndex + k], y, dicts.words->mgr);
                                }
                            }
                        PERMUTATION_END:;
                        }*/

                        //max score is somewhere between 1043 and 1539
                        if(wordScore > ret.maxScore) {
                            ret.maxScore = wordScore;
                            for(int i = 0; i < wordStruct->_numLetters; ++i) {
                                word[locs[i]] = chars[i]; //note wildcard tiles
                            }
                            
                            [self clearBoard:ret.maxBoard];
                            for(int i = 0; i < wordStruct->_numSubwords; ++i) {
                                Subword subword = wordStruct->_subwords[i];
                                int subwordLen = subword.end - subword.start;
                                char *subwordPointer = &(word[subword.start]);
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
                RESET_LETTERS;
                for(int i = 0; i < length; i++) {
                    if(word[i] < LETTER_OFFSET_LC) {
                        word[i] = word[i] - LETTER_OFFSET_UC + LETTER_OFFSET_LC;
                    }
                }
            }
            [playableWords removeAllObjects];
        }
    }

    printf("%d viable candidates (estimated to take %.3f days)\n", temp, temp * 10 / 60.0 / 24.0);

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

#define STR_REV_IN_PLACE(word, len) for(int z = 0; z < len / 2; ++z) { \
    word[z] ^= word[len - 1 - z];\
    word[len - 1 - z] ^= word[z];\
    word[z] ^= word[len - 1 - z];\
}
#define STR_REV(dst, src, len) for(int z = 0; z < len; ++z) { \
    dst[z] = src[len - z - 1];\
}

int nextVerticalWord(DictionaryIterator *restrict*restrict iterators, VerticalState *state, char *word, int y, DictionaryManager *wordMgr) {
    int ret = 0;
    switch(state->state) {
        case 0:
            if(BOARD_LENGTH - (y + 1) >= 2) {
                if(state->prefixLength) {
                COMPLETE_WORD:;
                    do {
                        ret = nextWordWithPrefix(iterators[1], word, y + state->prefixLength);
                    } while(ret && !isValidWord(iterators[1]->mgr, word + state->prefixLength, ret - state->prefixLength));
                    if(ret) {
                        STR_REV_IN_PLACE(word, ret);
                        return ret;
                    }
                }

            BOTTOM_WORD:;
                ret = nextWordWithPrefix(iterators[0], word, BOARD_LENGTH - (y + 1));
                if(ret) {
                    assert(isValidWord(iterators[0]->mgr, word, ret));
                    assert(ret <= BOARD_LENGTH - (y + 1));
                    if(y > 2) {
                        state->prefixLength = ret;
                        char revword[BOARD_LENGTH + 1];
                        STR_REV(revword, word, ret);
                        loadPrefix(iterators[1], revword, ret);
                    }
                    return ret;
                } else {
                    resetIteratorToPrefix(iterators[0]);
                    state->state++;
                    state->prefixLength = 0;
                }
            } else {
                state->state++;
            }
        case 1:
            if(y - 1 >= 2) {
                ret = nextWordWithPrefix(iterators[2], word, y - 1);
                if(ret) {
                    assert(ret <= y - 1);
                    return ret;
                } else {
                    resetIteratorToPrefix(iterators[2]);
                    state->state++;
                }
            } else {
                state->state++;
            }
        case 2:
            state->state = 0;
            return ret;
        default:
            return -1;
    }
}

#pragma mark - Validation

-(BOOL)validateLetters:(Letter*restrict)letters length:(int)length {
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
            return NO;
        }
    }
    return YES;
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