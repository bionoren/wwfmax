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
                [self clearBoard];
                
                if(strncmp("jimjams", word, length) == 0) {
                    NSLog(@"here");
                }
                if([self validateLetters:wordStruct->_letters length:wordStruct->_numLetters]) {
                    for(int y = 0; y < yMax; y++) {
                        for(int x = 0; x < BOARD_LENGTH - length; x++) {
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
                            
                            unsigned int score = [self scoreLetters:wordStruct->_letters length:wordStruct->_numLetters x:x y:y];
                            if(score > maxScore) {
                                maxScore = score;
                                memcpy(maxBoard, _board, BOARD_LENGTH*BOARD_LENGTH*sizeof(char));
                                memcpy(maxLetters, wordStruct->_letters, wordStruct->_numLetters * sizeof(Letter));
                                memcpy(maxWord, word, length * sizeof(char));
                                maxWordLength = length;
                                numMaxLetters = wordStruct->_numLetters;
                                maxx = x;
                                maxy = y;
                                
                                char maxWordLetters[BOARD_LENGTH + 1] = { [0 ... BOARD_LENGTH - 1] = '_', '\0' };
                                for(int k = 0; k < numMaxLetters; k++) {
                                    char c = (char)Y_FROM_HASH(maxLetters[k]);
                                    int offset = X_FROM_HASH(maxLetters[k]);
                                    maxWordLetters[offset] = c;
                                }
                                NSLog(@"Highest scoring play is %.*s (%.*s) at (%d, %d) on (%@) for %ld points", numMaxLetters, maxWordLetters, maxWordLength, maxWord, maxx, maxy, [self debugBoard:maxBoard], maxScore);
                            }
                        }
                    }
                }
                SUBWORD_FAIL:
                ;
            }
        }
        //NSLog(@"%.2f%% complete...", i / (float)numWords * 100.0);
    }
    char maxWordLetters[BOARD_LENGTH + 1] = { [0 ... BOARD_LENGTH - 1] = '_', '\0' };
    for(int i = 0; i < numMaxLetters; i++) {
        char c = (char)Y_FROM_HASH(maxLetters[i]);
        int x = X_FROM_HASH(maxLetters[i]);
        maxWordLetters[x] = c;
    }
    
    NSLog(@"Highest scoring play is %.*s (%.*s) at (%d, %d) on (%@) for %ld points", numMaxLetters, maxWordLetters, maxWordLength, maxWord, maxx, maxy, [self debugBoard:maxBoard], maxScore);
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

-(unsigned int)scoreLetters:(Letter *)letters length:(int)length x:(int)x y:(int)y {
    unsigned int ret = 0;
    unsigned int val = 0;
    int mult = 1;
    int minx = BOARD_LENGTH;
    int maxx = 0;
    //score the letters and note the word multipliers
    for(int i = 0; i < length; i++) {
        Letter l = letters[i];
        char c = (char)Y_FROM_HASH(l);
        int offset = X_FROM_HASH(l) + x;
        assert(c <= 'z' && c >= 'A');
        assert(x <= BOARD_LENGTH);
        val += scoreSquare(c, offset, y);
        mult *= wordMultiplier(offset, y);
        minx = MIN(minx, offset);
        maxx = MAX(maxx, offset);
    }
    
    //assume the word is horizontal
    //find the actual word boundaries
    while(--minx >= 0 && self.board[[self boardCoordinateX:minx y:y]] != DEFAULT_CHAR);
    while(++maxx <= BOARD_LENGTH && self.board[[self boardCoordinateX:maxx y:y]] != DEFAULT_CHAR);
    
    //finish scoring the word
    for(int i = minx + 1; i < maxx; ++i) {
        val += valuel(self.board[[self boardCoordinateX:i y:y]]);
    }
    ret = val * mult;
    
    //score any sidewords, noting multipliers again
    val = 0;
    mult = 1;
    for(int i = 0; i < length; i++) {
        BOOL found = NO;
        if(y > 0 && self.board[[self boardCoordinateX:minx y:y - 1]] != DEFAULT_CHAR) {
            found = YES;
            for(int i = y - 1; i >= 0 && self.board[[self boardCoordinateX:minx y:i]] != DEFAULT_CHAR; --i) {
                val += valuel(self.board[[self boardCoordinateX:minx y:i]]);
            }
        }
        if(y < BOARD_LENGTH && self.board[[self boardCoordinateX:minx y:y + 1]] != DEFAULT_CHAR) {
            found = YES;
            for(int i = y + 1; i <= BOARD_LENGTH && self.board[[self boardCoordinateX:minx y:i]] != DEFAULT_CHAR; ++i) {
                val += valuel(self.board[[self boardCoordinateX:minx y:i]]);
            }
        }
        if(found) {
            Letter l = letters[i];
            char c = (char)Y_FROM_HASH(l);
            int offset = X_FROM_HASH(l) + x;
            val += scoreSquare(c, offset, y);
            mult *= wordMultiplier(offset, y);
        }
=    }
    ret += val * mult;
    
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
    int start = [self boardCoordinateX:x y:y];
    memcpy(&(_board[start]), word, length * sizeof(char));
}

-(void)clearBoard {
    memcpy(_board, blankBoard, BOARD_LENGTH * BOARD_LENGTH * sizeof(char));
}

#pragma mark - Debug / Helper

-(int)boardCoordinateX:(int)x y:(int)y {
    return x + y * BOARD_LENGTH;
}

-(NSString*)debugBoard:(char*)board {
    NSMutableString *ret = [[NSMutableString alloc] initWithString:@"\n"];
    for(int y = 0; y < BOARD_LENGTH; y++) {
        for(int x = 0; x < BOARD_LENGTH; x++) {
            char c = board[[self boardCoordinateX:x y:y]];
            [ret appendFormat:@"%c", c];
        }
        [ret appendString:@"\n"];
    }
    return ret;
}

@end