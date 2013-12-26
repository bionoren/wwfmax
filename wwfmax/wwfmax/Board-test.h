//
//  Board-test.h
//  wwfmax
//
//  Created by Bion Oren on 12/23/13.
//  Copyright (c) 2013 Llama Software. All rights reserved.
//

#import "Board.h"
#import "WordStructure.h"

typedef struct {
    int state;
    int prefixLength;
} VerticalState;

int preprocessWordStruct(Board *self, WordStructure *wordStruct, char word[BOARD_LENGTH + 1], int length, char chars[NUM_LETTERS_TURN], int locs[NUM_LETTERS_TURN]);
void shuffleBonusTilesForWordStruct(int numLetters, int baseHash, char chars[NUM_LETTERS_TURN], int locs[NUM_LETTERS_TURN]);
int nextVerticalWord(DictionaryIterator *restrict*restrict iterators, VerticalState *state, char word[BOARD_LENGTH + 1], int y, DictionaryManager *wordMgr);