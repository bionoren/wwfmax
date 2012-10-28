//
//  Board.h
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    NSUInteger maxScore;
    char maxWord[BOARD_LENGTH];
    int maxWordLength;
    Letter maxLetters[NUM_LETTERS_TURN];
    int numMaxLetters;
    char maxBoard[BOARD_LENGTH * BOARD_LENGTH * sizeof(char)];
    int maxx;
    int maxy;
} Solution;

@interface Board : NSObject

-(Solution)solve:(const WordInfo*)info;
+(NSString*)debugBoard:(char*)board;

@end

static void printSolution(Solution sol) {
    char maxWordLetters[BOARD_LENGTH + 1] = { [0 ... BOARD_LENGTH - 1] = '_', '\0' };
    for(int k = 0; k < sol.numMaxLetters; k++) {
        char c = (char)Y_FROM_HASH(sol.maxLetters[k]);
        int offset = X_FROM_HASH(sol.maxLetters[k]);
        maxWordLetters[offset] = c;
    }
    NSLog(@"Highest scoring play is %.*s (%.*s) at (%d, %d) on (%@) for %ld points", sol.maxWordLength, maxWordLetters, sol.maxWordLength, sol.maxWord, sol.maxx, sol.maxy, [Board debugBoard:sol.maxBoard], sol.maxScore);
}