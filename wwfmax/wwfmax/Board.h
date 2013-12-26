//
//  Board.h
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DictionaryManager.h"

typedef struct {
    int maxScore;
    char maxWord[BOARD_LENGTH];
    int maxWordLength;
    Letter maxLetters[NUM_LETTERS_TURN];
    int numMaxLetters;
    char maxBoard[BOARD_LENGTH * BOARD_LENGTH * sizeof(char)];
    int maxx;
    int maxy;
} Solution;

typedef struct {
    int maxBaseScore; //lower bound on max score
    float maxScoreRatio; //lower bound on max ratio of (score / prescore)
    int maxBonusTileScores[BOARD_LENGTH * BOARD_LENGTH][26]; //lower bound on max score for each square on a per-letter basis
} PreprocessedData;

@interface Board : NSObject

+(void)loadPreprocessedData:(PreprocessedData*)data;
-(PreprocessedData*)preprocess:(Dictionaries*)dicts;
-(Solution*)solveWord:(char[BOARD_LENGTH + 1])word length:(int)length maxScore:(int)maxScore dict:(Dictionaries*)dicts;
+(NSString*)debugBoard:(char*)board;
-(BOOL)testValidate:(char*restrict)word length:(int)length;

@end