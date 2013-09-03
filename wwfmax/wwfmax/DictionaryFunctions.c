//
//  DictionaryFunctions.c
//  wwfmax
//
//  Created by Bion Oren on 8/27/13.
//  Copyright (c) 2013 Llama Software. All rights reserved.
//

#include "DictionaryFunctions.h"
#include <stdio.h>
#include <stdarg.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#define DICTIONARY "/Users/bion/projects/objc/wwfmax/dict.txt"
#define DICT_PERMUTER "/Users/bion/projects/objc/wwfmax/dictPermuter.py"

//anecdotally, ~2.5% of the shipped dictionary is unplayable, mostly because the words are too long for the board, but also because there aren't enough of the required letters and because some words can't be broken down into sufficiently small subwords

void shellprintf(const char *command, ...) {
    va_list ap;
    va_start(ap, command);
    char *cmd = (char*)malloc(sizeof(char) * 512); //surely your path isn't longer than this...
    vsprintf(cmd, command, ap);
    perror(cmd);
    va_end(ap);

    system(cmd);
}

char *prefixStringInPath(const char *string, const char *prefix) {
    char *ret = (char*)calloc(strlen(string) + strlen(prefix), sizeof(char));
    const char *pathEnd = strrchr(string, '/');
    size_t prefixLength = pathEnd - string;
    strncpy(ret, string, prefixLength);
    strncpy(ret + prefixLength, "/", 1);
    strncpy(ret + prefixLength + 1, prefix, strlen(prefix));
    strncpy(ret + prefixLength + strlen(prefix) + 1, pathEnd + 1, strlen(pathEnd));

    return ret;
}

char *CWGOfDictionaryFile(const char *dictionary, char **validatedDict) {
#if BUILD_DATASTRUCTURES
    int numWords = 1024;
    char *words = malloc(numWords * BOARD_LENGTH * sizeof(char));
    assert(words);
    int *wordLengths = malloc(numWords * sizeof(int));
    assert(wordLengths);

    FILE *wordFile = fopen(dictionary, "r");
    assert(wordFile);
    char buffer[40];
    int i = 0;
    while(fgets(buffer, 40, wordFile)) {
        int len = (int)strlen(buffer);
        if(buffer[len - 1] == '\n') {
            --len;
        }
        if(len == 0) { //blank line
            continue;
        }
        if(len <= BOARD_LENGTH) {
            strncpy(&(words[BOARD_LENGTH * i]), buffer, len);
            wordLengths[i++] = len;
            if(i >= numWords) {
                numWords *= 2;
                words = realloc(words, numWords * BOARD_LENGTH * sizeof(char));
                wordLengths = realloc(wordLengths, numWords * sizeof(int));
            }
        }
    }
    fclose(wordFile);
    numWords = i;

    printf("evaluating %d words\n", numWords);

    const WordInfo info = {.words = words, .numWords = numWords, .lengths = wordLengths};

    if(validatedDict) {
        Board *board = [[Board alloc] init];
        *validatedDict = prefixStringInPath(dictionary, "valid-");
        FILE *validFile = fopen(*validatedDict, "w");

        for(int i = 0; i < numWords; i++) {
            char *word = &(words[i * BOARD_LENGTH]);
            const int length = wordLengths[i];

            if(![board testValidate:word length:length] || !playable(word, length, &info)) {
                words[i * BOARD_LENGTH] = '\0';
                wordLengths[i] = 0;
                continue;
            }
            fprintf(validFile, "%.*s\n", length, word);
        }

        fclose(validFile);
    }
#endif

    char *ret = calloc(strlen(dictionary) + 5, sizeof(char));
    strncpy(ret, dictionary, strlen(dictionary));
    strcat(ret, ".dat");
#if BUILD_DATASTRUCTURES
    createDataStructure(&info, ret);
    free(words);
    free(wordLengths);
#endif

    return ret;
}

int **createLetterPairLookupTableForDictionary(DictionaryIterator *itr) {
    resetIterator(itr);
    int **ret = (int**)malloc(26 * 26 * sizeof(int*));
    int *lengths = (int*)calloc(26 * 26, sizeof(int));
    for(int i = 0; i < 26 * 26; i++) {
        ret[i] = calloc(1, sizeof(int)); //first element is the size of the sublist, which calloc conveniently 0s
        assert(ret[i][0] == 0);
    }

    assert(BOARD_LENGTH + 1 == 16 && sizeof(int) == 4);
    char word[BOARD_LENGTH + 1] = {0};
    int length;
    while((length = nextWord(itr, word))) {
        for(int i = 0; i < length - 1; i++) {
            int l1 = word[i] - 'a';
            int l1index = itr->stack[i].index;
            int l2 = word[i + 1] - 'a';

            int index = l1 + l2 * 26;
            int *row = ret[index];
            for(int j = 1; j < row[0] + 1; j++) {
                if(row[j] == l1index) {
                    goto LOOP_END;
                }
            }
            if(++row[0] >= lengths[index]) {
                lengths[index] = row[0] * 2; //this gets rid of "not counting the first element" problems
                row = ret[index] = realloc(row, (lengths[index] + 1) * sizeof(int));
                assert(row);
            }
            row[row[0]] = l1index;
        LOOP_END:;
        }
    }
    //tighten up memory use
    free(lengths);
    for(int i = 0; i < 26 * 26; i++) {
        ret[i] = realloc(ret[i], (ret[i][0] + 1) * sizeof(int));
    }

    resetIterator(itr);
#if DEBUG
    int numInts = 0;
    int avglinks = 0;
    for(int i = 0; i < 26 * 26; i++) {
        avglinks += ret[i][0] + 1;
        numInts += ret[i][0] + 1;
    }
    printf("Letter pair index lookup table takes %d bytes (avg links = %.2f)\n", numInts * 4, avglinks / (26.0 * 26.0));
#endif
    return ret;
}