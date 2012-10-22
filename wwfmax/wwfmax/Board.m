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

@property (nonatomic) char *board;
@property (nonatomic) int *letters;
@property (nonatomic, strong) NSMutableDictionary *sidewordCache;

@end

@implementation Board

-(id)init {
    if(self = [super init]) {
        _letters = calloc(NUM_LETTERS, sizeof(int));
        memcpy(_letters, letterCounts, NUM_LETTERS * sizeof(int));
        _board = calloc(BOARD_LENGTH * BOARD_LENGTH, sizeof(char));
        [self clearBoard];
        NSAssert(self.letters[1] == 9, @"self.letters[1] = %d, self.letters[4] = %d", self.letters[1], self.letters[4]);
    }
    return self;
}

-(void)dealloc {
    free(_letters);
    _letters = NULL;
    free(_board);
    _board = NULL;
}

/**
 I'm strictly interested in the top half of the board and horizontal words because of bonus tile symetry.
 */
-(void)solve:(char*)words lengths:(int*)wordLengths count:(int)numWords {
    assert(validate("jezebel", 7, words, numWords, wordLengths));
    assert(validate("azotobacters", 12, words, numWords, wordLengths));
    
    NSUInteger maxScore = 0;
    char maxWord[BOARD_LENGTH];
    int maxWordLength = 0;
    Letter maxLetters[NUM_LETTERS_TURN];
    int numMaxLetters = 0;
    char *maxBoard = calloc(BOARD_LENGTH * BOARD_LENGTH, sizeof(char));
    int maxx = -1;
    int maxy = -1;

    const static int yMax = BOARD_LENGTH / 2 + BOARD_LENGTH % 2; //ceil(BOARD_LENGTH / 2) as compile time constant
    char *word = words;
    
    for(int i = 0; i < numWords; word += BOARD_LENGTH * sizeof(char), i++) {
        @autoreleasepool {
            int length = wordLengths[i];

            NSSet *playableWords = subwordsAtLocation(word, length, words, numWords, wordLengths);
            if(!playableWords) {
                continue;
            }
            
            for(WordStructure *wordStruct in playableWords) {
                assert(wordStruct->_numLetters > 0);
                if([self validateLetters:wordStruct->_letters length:wordStruct->_numLetters]) {
                    char chars[NUM_LETTERS_TURN];
                    int locs[NUM_LETTERS_TURN];
                    for(int tmp = 0; tmp < wordStruct->_numLetters; ++tmp) {
                        Letter l = wordStruct->_letters[tmp];
                        chars[tmp] = (char)Y_FROM_HASH(l);
                        locs[tmp] = X_FROM_HASH(l);
                    }
                    
                    int wordminx = locs[0];
                    int wordmaxx = locs[wordStruct->_numLetters - 1];
                    int offsets[NUM_LETTERS_TURN];
                    for(int x = 0; x < BOARD_LENGTH - length; x++) {
                        for(int tmp = 0; tmp < wordStruct->_numLetters; ++tmp) {
                            offsets[tmp] = locs[tmp]++;
                        }
                        
                        for(int y = 0; y < yMax; y++) {
                            [self clearBoard];
                            
                            for(int j = 0; j < wordStruct->_numSubwords; j++) {
                                Subword subword = wordStruct->_subwords[j];
                                assert(subword.start < subword.end);
                                int subwordLen = subword.end - subword.start;
                                char *subwordPointer = &(wordStruct->_word[subword.start]);
                                if([self testValidate:subwordPointer length:subwordLen]) {
                                    [self addSubword:subwordPointer length:subwordLen x:x + subword.start y:y];
                                } else {
                                    goto SUBWORD_FAIL;
                                }
                            }
                            
                            unsigned int score = [self scoreLetters:wordStruct->_letters length:wordStruct->_numLetters chars:chars minx:wordminx maxx:wordmaxx offsets:offsets x:x y:y];
                            if(score > maxScore) {
                                maxScore = score;
                                memcpy(maxBoard, _board, BOARD_LENGTH*BOARD_LENGTH*sizeof(char));
                                memcpy(maxLetters, wordStruct->_letters, wordStruct->_numLetters * sizeof(Letter));
                                memcpy(maxWord, word, length * sizeof(char));
                                maxWordLength = length;
                                numMaxLetters = wordStruct->_numLetters;
                                maxx = x;
                                maxy = y;
#ifdef DEBUG
                                char maxWordLetters[BOARD_LENGTH + 1] = { [0 ... BOARD_LENGTH - 1] = '_', '\0' };
                                for(int k = 0; k < numMaxLetters; k++) {
                                    char c = (char)Y_FROM_HASH(maxLetters[k]);
                                    int offset = X_FROM_HASH(maxLetters[k]);
                                    maxWordLetters[offset] = c;
                                }
                                NSLog(@"Highest scoring play is %.*s (%.*s) at (%d, %d) on (%@) for %ld points", maxWordLength, maxWordLetters, maxWordLength, maxWord, maxx, maxy, [Board debugBoard:maxBoard], maxScore);
#endif
                            }
                            wordminx++;
                            wordmaxx++;
                        }
                    }
                }
                SUBWORD_FAIL:
                ;
            }
        }
        //NSLog(@"%.2f%% complete...", i / (float)numWords * 100.0);
    }
#ifndef DEBUG
    char maxWordLetters[BOARD_LENGTH + 1] = { [0 ... BOARD_LENGTH - 1] = '_', '\0' };
    for(int i = 0; i < numMaxLetters; i++) {
        char c = (char)Y_FROM_HASH(maxLetters[i]);
        int x = X_FROM_HASH(maxLetters[i]);
        maxWordLetters[x] = c;
    }
    
    NSLog(@"Highest scoring play is %.*s (%.*s) at (%d, %d) on (%@) for %ld points", maxWordLength, maxWordLetters, maxWordLength, maxWord, maxx, maxy, [Board debugBoard:maxBoard], maxScore);
#endif
    free(maxBoard);
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

-(unsigned int)scoreLetters:(Letter *)letters length:(const int)length chars:(char*)chars minx:(int)minx maxx:(int)maxx offsets:(int*)offsets x:(const int)x y:(const int)y {
    unsigned int val = 0;
    int mult = 1;
    
    unsigned int vals[NUM_LETTERS_TURN];
    int mults[NUM_LETTERS_TURN];
    //score the letters and note the word multipliers
    for(int i = 0; i < length; ++i) {
        assert(chars[i] <= 'z' && chars[i] >= 'A');
        int hash = HASH(offsets[i], y);
        vals[i] = scoreSquareHash(chars[i], hash);
        mults[i] = wordMultiplierHash(hash);
        val += vals[i];
        mult *= mults[i];
    }
    
    //assume the word is horizontal
    //find the actual word boundaries
    while(--minx >= 0 && _board[BOARD_COORDINATE(minx, y)] != DEFAULT_CHAR);
    while(++maxx <= BOARD_LENGTH && _board[BOARD_COORDINATE(maxx, y)] != DEFAULT_CHAR);
    
    //finish scoring the word
    for(int i = minx + 1; i < maxx; ++i) {
        val += valuel(_board[BOARD_COORDINATE(i, y)]);
    }
    unsigned int ret = val * mult;
    
    //score any sidewords, noting multipliers again
    for(int i = 0; i < length; ++i) {
        int offset = offsets[i];
        
        val = 0;
        BOOL found = NO;
        if(y > 0 && _board[BOARD_COORDINATE(offset, y - 1)] != DEFAULT_CHAR) {
            found = YES;
            for(int j = y - 1; j >= 0 && _board[BOARD_COORDINATE(offset, j)] != DEFAULT_CHAR; --j) {
                val += valuel(_board[BOARD_COORDINATE(offset, j)]);
            }
        }
        if(y < BOARD_LENGTH && _board[BOARD_COORDINATE(offset, y + 1)] != DEFAULT_CHAR) {
            found = YES;
            for(int j = y + 1; j <= BOARD_LENGTH && _board[BOARD_COORDINATE(offset, j)] != DEFAULT_CHAR; ++j) {
                val += valuel(_board[BOARD_COORDINATE(offset, j)]);
            }
        }
        if(found) {
            val += vals[i];
            mult = mults[i];
            ret += val * mult;
        }
    }
    
    //add bonus for using all letters
    if(length == NUM_LETTERS_TURN) {
        ret += 35;
    }
    return ret;
}

/** this scoring method ignores bonus tiles */
-(unsigned int)scoreWord:(NSString*)word {
    unsigned int ret = 0;
    for(int i = 0; i < word.length; i++) {
        char c = (char)[word characterAtIndex:i];
        if(c >= LETTER_OFFSET_LC) {
            ret += scoreSquareHash(c, -1);
        }
    }
    return ret;
}

-(void)addSubword:(char*)word length:(int)length x:(int)x y:(int)y {
    int start = BOARD_COORDINATE(x, y);
    memcpy(&(_board[start]), word, length * sizeof(char));
}

-(void)clearBoard {
    memcpy(_board, blankBoard, BOARD_LENGTH * BOARD_LENGTH * sizeof(char));
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