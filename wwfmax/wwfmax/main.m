//
//  main.m
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <string.h>
#import <stdio.h>
#import "Board.h"
#import "functions.h"
#import "DictionaryManager.h"
#import "dawg.h"

#define DICTIONARY "/Users/bion/projects/objc/wwfmax/dict.txt"
#define DICT_PERMUTER "/Users/bion/projects/objc/wwfmax/dictPermuter.py"

//anecdotally, ~2.5% of the shipped dictionary is unplayable, mostly because the words are too long for the board, but also because there aren't enough of the required letters and because some words can't be broken down into sufficiently small subwords

void shellprintf(const char *command, ...) {
    va_list ap;
    va_start(ap, command);
    char *cmd = malloc(sizeof(char) * 512); //surely your path isn't longer than this...
    vsprintf(cmd, command, ap);
    perror(cmd);
    va_end(ap);

    system(cmd);
}

char *prefixStringInPath(const char *string, const char *prefix) {
    char *ret = calloc(strlen(string) + strlen(prefix), sizeof(char));
    const char *pathEnd = strrchr(string, '/');
    size_t prefixLength = pathEnd - string;
    strncpy(ret, string, prefixLength);
    strncpy(ret + prefixLength, "/", 1);
    strncpy(ret + prefixLength + 1, prefix, strlen(prefix));
    strncpy(ret + prefixLength + strlen(prefix) + 1, pathEnd + 1, strlen(pathEnd));

    return ret;
}

char *CWGOfDictionaryFile(const char *dictionary, int numWords, char **validatedDict) {
#if BUILD_DATASTRUCTURES
    char *words = calloc(numWords * BOARD_LENGTH, sizeof(char));
    assert(words);
    int *wordLengths = malloc(numWords * sizeof(int));
    assert(wordLengths);

    FILE *wordFile = fopen(dictionary, "r");
    assert(wordFile);
    char buffer[40];
    int i = 0;
    char *word = words;
    while(fgets(buffer, 40, wordFile)) {
        int len = (int)strlen(buffer);
        if(buffer[len - 1] == '\n') {
            --len;
        }
        if(len == 0) { //blank line
            continue;
        }
        if(len <= BOARD_LENGTH) {
            strncpy(word, buffer, len);
            assert(i < numWords);
            wordLengths[i++] = len;
            word += BOARD_LENGTH * sizeof(char);
        }
    }
    fclose(wordFile);
    numWords = i;

    printf("evaluating %d words\n", numWords);

    const WordInfo info = {.words = words, .numWords = numWords, .lengths = wordLengths};

    if(validatedDict) {
        *validatedDict = prefixStringInPath(dictionary, "valid-");
        FILE *validFile = fopen(*validatedDict, "w");

        for(int i = 0; i < numWords; i++) {
            char *word = &(words[i * BOARD_LENGTH]);
            const int length = wordLengths[i];

            if(!playable(word, length, &info)) {
                words[i * BOARD_LENGTH] = 0;
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

int main(int argc, const char * argv[]) {
    @autoreleasepool {
#if DEBUG
        assert(sizeof(short) >= 2);
        assert(HASH(11, 3) == 59); //3,11
        Letter hash = HASH(BOARD_LENGTH, 'z');
        assert(X_FROM_HASH(hash) == BOARD_LENGTH);
        assert((char)Y_FROM_HASH(hash) == 'z');
#endif
        
        NSLog(@"%@", [[[NSFileManager alloc] init] currentDirectoryPath]);
        //NOTE: generated datastructures account for approximately 3Mb of storage
        const char *dictionaryPath = DICTIONARY;
        char *validDictionary;
        char *dictionary = CWGOfDictionaryFile(dictionaryPath, 173101, &validDictionary);
        char *reversedDictionary = prefixStringInPath(dictionaryPath, "reversed-");
        shellprintf("cat %s | rev > %s", validDictionary, reversedDictionary);
        char *dictionaryReversed = CWGOfDictionaryFile(reversedDictionary, 173101, NULL);

        char *suffixedDictionary = prefixStringInPath(dictionaryPath, "suffixes-");
        char *reversedSuffixedDictionary = prefixStringInPath(suffixedDictionary, "reversed-");
        shellprintf("python %s %s %s", DICT_PERMUTER, validDictionary, suffixedDictionary);
        char *dictionarySuffixes = CWGOfDictionaryFile(suffixedDictionary, 952650, NULL);
        shellprintf("cat %s | rev > %s", suffixedDictionary, reversedSuffixedDictionary);
        char *dictionarySuffixesReversed = CWGOfDictionaryFile(reversedSuffixedDictionary, 952650, NULL);

        free(validDictionary);
        free(reversedDictionary);
        free(suffixedDictionary);
        free(reversedSuffixedDictionary);

        DictionaryManager *mgr = createDictManager(dictionary);
        Dictionaries dicts;
        dicts.words = createDictIterator(mgr);
        dicts.pwords = createDictManager(dictionarySuffixes);
        dicts.rwords = createDictManager(dictionaryReversed);
        dicts.rpwords = createDictManager(dictionarySuffixesReversed);
        free(dictionary);
        free(dictionarySuffixes);
        free(dictionaryReversed);
        free(dictionarySuffixesReversed);

        __block OSSpinLock lock = OS_SPINLOCK_INIT;
        dispatch_group_t dispatchGroup = dispatch_group_create();

        __block PreprocessedData *masterPreprocessedData = calloc(1, sizeof(PreprocessedData));
        for(int i = 0; i < NUM_THREADS; ++i) {
            dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Board *board = [[Board alloc] init];
                PreprocessedData *preprocessedData = [board preprocess:dicts];

                OSSpinLockLock(&lock);

                if(preprocessedData->maxBaseScore > masterPreprocessedData->maxBaseScore) {
                    masterPreprocessedData->maxBaseScore = preprocessedData->maxBaseScore;
                }
                for(int j = 0; j < BOARD_LENGTH * BOARD_LENGTH; j++) {
                    for(int k = 0; k < 26; k++) {
                        if(preprocessedData->maxBonusTileScores[j][k] > masterPreprocessedData->maxBonusTileScores[j][k]) {
                            masterPreprocessedData->maxBonusTileScores[j][k] = preprocessedData->maxBonusTileScores[j][k];
                        }
                    }
                }

                OSSpinLockUnlock(&lock);

                free(preprocessedData);
            });
        }

        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
        NSLog(@"Preprocessing complete");
        [Board loadPreprocessedData:masterPreprocessedData];
        free(masterPreprocessedData);
        resetIterator(dicts.words);
        
        __block Solution sol;
        sol.maxScore = 0;
        for(int i = 0; i < NUM_THREADS; ++i) {
            dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Board *board = [[Board alloc] init];
                Solution temp = [board solve:dicts];

                OSSpinLockLock(&lock);

                if(temp.maxScore > sol.maxScore) {
                    sol = temp;
                }

                OSSpinLockUnlock(&lock);
            });
        }
        
        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
        printSolution(sol);

        freeDictionaries(dicts);
        freeDictManager(mgr);
    }
    return 0;
}