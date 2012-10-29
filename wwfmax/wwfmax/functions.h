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

#pragma mark - Threading

//threadsafe
int nextWord(int numWords);
void resetWords();

#pragma mark - Debugging

void printSubwords(char* word, int length, Subword *subwords, int numSubwords);

#pragma mark - Scoring

unsigned int valuel(char letter);

unsigned int scoreSquarePrescoredHash(char letter, unsigned int hash);

unsigned int scoreSquarePrescored(char letter, unsigned int x, unsigned int y);

unsigned int scoreSquareHash(char letter, unsigned int hash);

unsigned int scoreSquare(char letter, unsigned int x, unsigned int y);

unsigned int wordMultiplierHash(unsigned int hash);

unsigned int wordMultiplier(unsigned int x, unsigned int y);

int prescoreWord(const char *word, const int length);

unsigned int scoreLettersWithPrescore(const int prescore, const int length, char *chars, int *offsets, const int y);

#pragma mark - Validation

BOOL validate(const char *word, const int length, const WordInfo *info);

void subwordsAtLocation(NSMutableSet **ret, const char *word, const int length, const WordInfo *info);

#endif