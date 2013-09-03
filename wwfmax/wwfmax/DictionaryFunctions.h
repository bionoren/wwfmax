//
//  DictionaryFunctions.h
//  wwfmax
//
//  Created by Bion Oren on 8/27/13.
//  Copyright (c) 2013 Llama Software. All rights reserved.
//

#ifndef wwfmax_DictionaryFunctions_h
#define wwfmax_DictionaryFunctions_h

#import "DictionaryManager.h"

#define DICTIONARY "/Users/bion/projects/objc/wwfmax/dict.txt"
#define DICT_PERMUTER "/Users/bion/projects/objc/wwfmax/dictPermuter.py"

//anecdotally, ~2.5% of the shipped dictionary is unplayable, mostly because the words are too long for the board, but also because there aren't enough of the required letters and because some words can't be broken down into sufficiently small subwords

void shellprintf(const char *command, ...);
char *prefixStringInPath(const char *string, const char *prefix);
char *CWGOfDictionaryFile(const char *dictionary, char **validatedDict);
int **createLetterPairLookupTableForDictionary(DictionaryIterator *itr);

#endif