//
//  functions.h
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#ifndef FUNCTIONS_WWFMAX
#define FUNCTIONS_WWFMAX

#import "WordStructure.h"
#import "DictionaryManager.h"

#pragma mark - Debugging

void printSubwords(char* word, int length, Subword *subwords, int numSubwords);

#pragma mark - Scoring

int valuel(char letter);

int scoreSquarePrescoredHash(char letter, int hash);

int scoreSquarePrescored(char letter, int x, int y);

int scoreSquareHash(char letter, int hash);

int scoreSquare(char letter, int x, int y);

int wordMultiplierHash(int hash);

int wordMultiplier(int x, int y);

int prescoreWord(const char *word, const int length);

int scoreLettersWithPrescore(const int prescore, const int length, char *chars, int *offsets, const int x, const int y);

#pragma mark - Validation

BOOL validate(const char *word, const int length, const WordInfo *info);

void subwordsAtLocation(DictionaryIterator *itr, NSMutableSet **ret, char *word, const int length);

BOOL playable(char *word, const int length, const WordInfo *info);

#endif