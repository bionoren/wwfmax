//
//  Board.m
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import "Board.h"
#import "Letter.h"
#import "functions.h"
#import "NSString+CharacterSets.h"

#define NUM_LETTERS 27

/**
 Note that capital letters are used to represent blanks
 */

//ascii value, 'a'=>1
static const int letters[] = {
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

@interface Board ()

@property (nonatomic) char *board;
@property (nonatomic) int *letters;
@property (nonatomic, strong) NSMutableDictionary *sidewordCache;

@end

@implementation Board

-(id)init {
    if(self = [super init]) {
        _letters = calloc(NUM_LETTERS, sizeof(int));
        memcpy(_letters, letters, NUM_LETTERS * sizeof(int));
        _board = calloc(15 * 15, sizeof(char));
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

-(void)debug:(NSArray**)words {
    for(int i = 0; i < NUM_LETTERS; i++) {
        NSLog(@"Found letter %c => %d", i + LETTER_OFFSET - 1, self.letters[i]);
    }
    NSRange range = NSMakeRange(0, (*words).count);
    for(NSString *word in *words) {
        filterValidate(word, *words, range);
    }
    NSLog(@"Validation complete");
}

/**
 I'm strictly interested in the top half of the board and horizontal words because of bonus tile symetry.
 */
-(void)solve:(NSArray*)words {
    NSRange range = NSMakeRange(0, words.count);
    words = [words filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *evaluatedObject, NSDictionary *bindings) {
        return filterValidate(evaluatedObject, words, range);
    }]];
    range = NSMakeRange(0, words.count);
    
    NSUInteger maxScore = 0;
    NSMutableSet *maxLetters = [NSMutableSet setWithCapacity:7];
    char *maxBoard = calloc(15 * 15, sizeof(char));
    for(int y = 0; y < 9;) {
        for(int x = 0; x < 14; x++) {
            @autoreleasepool {
                for(NSString *word in words) {
                    if(word.length - x > 15) {
                        continue;
                    }
#warning incomplete
                    if(word.length <= NUM_LETTERS_TURN) {
                        NSString *playableWord = [self testValidate:word words:&words range:&range];
                        if(!playableWord) {
                            continue;
                        }
                        for(NSSet *letters in [playableWord characterSetsAtX:x y:y]) {
                            int score = [self scoreLetters:letters];
                            if(score > maxScore) {
                                maxScore = score;
                                memcpy(maxBoard, self.board, 15*15*sizeof(char));
                                [maxLetters removeAllObjects];
                                for(Letter *l in letters) {
                                    [maxLetters addObject:[l copy]];
                                }
                            }
                        }
                    }
                }
            }
        }
        NSLog(@"%.2f%% complete...", ++y / 9.0 * 100);
    }
    NSLog(@"Highest scoring play is %@ on (%@) for %ld points", [maxLetters sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"x" ascending:YES]]], [self debugBoard:maxBoard], maxScore);
}

#pragma mark - Validation

-(NSString*)testValidate:(NSString*)word words:(NSArray**)words range:(NSRange*)range {
    NSMutableString *ret = [NSMutableString stringWithCapacity:word.length];
    //ensure we have enough letters to spell this word
    for(int i = 0; i < word.length; i++) {
        char c = [word characterAtIndex:i];
        int index = c - LETTER_OFFSET + 1;
        if(self.letters[index]-- > 0) {
            [ret appendFormat:@"%c", c];
        } else if(self.letters[0]-- > 0) {
            [ret appendFormat:@"%c", index + 64];
        } else {
            ret = nil;
            break;
        }
    }
    memcpy(_letters, letters, NUM_LETTERS * sizeof(int));
    
    return ret;
}

#pragma mark - Scoring

-(unsigned int)scoreLetters:(NSSet*)letters {
    unsigned int ret = 0;
    unsigned int val = 0;
    int mult = 1;
    int minx = 14;
    int maxx = 0;
    const int y = ((Letter*)[letters anyObject]).y;
    //score the letters and note the word multipliers
    for(Letter *l in letters) {
        val += scoreSquare(l.letter, l.x, y);
        mult *= wordMultiplier(l.x, y);
        minx = MIN(minx, l.x);
        maxx = MAX(maxx, l.x);
    }
    
    //assume the word is horizontal
    //find the actual word boundaries
    while(--minx >= 0 && self.board[[self boardCoordinateX:minx y:y]]);
    while(++maxx <= 15 && self.board[[self boardCoordinateX:maxx y:y]]);
    
    //finish scoring the word
    for(int i = minx + 1; i < maxx; ++i) {
        val += valuel(self.board[[self boardCoordinateX:i y:y]]);
    }
    ret = val * mult;
    
    //score any sidewords, noting multipliers again
    val = 0;
    mult = 1;
    for(Letter *l in letters) {
        BOOL found = NO;
        if(y > 0 && self.board[[self boardCoordinateX:minx y:y - 1]]) {
            found = YES;
            for(int i = y - 1; i >= 0 && self.board[[self boardCoordinateX:minx y:i]]; --i) {
                val += valuel(self.board[[self boardCoordinateX:minx y:i]]);
            }
        }
        if(y < 15 && self.board[[self boardCoordinateX:minx y:y + 1]]) {
            found = YES;
            for(int i = y + 1; i <= 15 && self.board[[self boardCoordinateX:minx y:i]]; ++i) {
                val += valuel(self.board[[self boardCoordinateX:minx y:i]]);
            }
        }
        if(found) {
            val += scoreSquare(l.letter, l.x, y);
            mult *= wordMultiplier(l.x, y);
        }
    }
    ret += val * mult;
    
    //add bonus for using all letters
    if(letters.count == NUM_LETTERS_TURN) {
        ret += 35;
    }
    return ret;
}

/** this scoring method ignores bonus tiles */
-(unsigned int)scoreWord:(NSString*)word {
    unsigned int ret = 0;
    for(int i = 0; i < word.length; i++) {
        char c = [word characterAtIndex:i];
        if(c >= LETTER_OFFSET) {
            ret += scoreSquareHash(c, -1);
        }
    }
    return ret;
}

#pragma mark - Debug / Helper

-(int)boardCoordinateX:(int)x y:(int)y {
    return x + y * 15;
}

-(NSString*)debugBoard:(char*)board {
    NSMutableString *ret = [[NSMutableString alloc] initWithString:@"\n"];
    for(int i = 0; i < 15; i++) {
        for(int j = 0; j < 15; j++) {
            char c = board[[self boardCoordinateX:j y:i]];
            if(c) {
                [ret appendFormat:@"%c", c];
            } else {
                [ret appendString:@"-"];
            }
        }
        [ret appendString:@"\n"];
    }
    return ret;
}

@end