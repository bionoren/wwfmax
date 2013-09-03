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
#import "DictionaryFunctions.h"

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
        char *dictionary = CWGOfDictionaryFile(dictionaryPath, &validDictionary);
        char *reversedDictionary = prefixStringInPath(dictionaryPath, "reversed-");
#if BUILD_DATASTRUCTURES
        shellprintf("cat %s | rev > %s", validDictionary, reversedDictionary);
#endif
        char *dictionaryReversed = CWGOfDictionaryFile(reversedDictionary, NULL);

        char *suffixedDictionary = prefixStringInPath(dictionaryPath, "suffixes-");
        char *reversedSuffixedDictionary = prefixStringInPath(suffixedDictionary, "reversed-");
#if BUILD_DATASTRUCTURES
        shellprintf("python %s %s %s", DICT_PERMUTER, validDictionary, suffixedDictionary);
#endif
        char *dictionarySuffixes = CWGOfDictionaryFile(suffixedDictionary, NULL);
#if BUILD_DATASTRUCTURES
        shellprintf("cat %s | rev > %s", suffixedDictionary, reversedSuffixedDictionary);
#endif
        char *dictionarySuffixesReversed = CWGOfDictionaryFile(reversedSuffixedDictionary, NULL);

#if BUILD_DATASTRUCTURES
        free(validDictionary);
#endif
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
        dicts.letterPairLookupTable = createLetterPairLookupTableForDictionary(dicts.words);

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
                if(preprocessedData->maxScoreRatio > masterPreprocessedData->maxScoreRatio) {
                    masterPreprocessedData->maxScoreRatio = preprocessedData->maxScoreRatio;
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
        
        __block Solution *sol = malloc(sizeof(Solution));
        sol->maxScore = 0;
        FILE *existingSolutionFile = fopen("solutionSoFar.dat", "rb");
        if(existingSolutionFile) {
            //Load state info
            assert(BOARD_LENGTH + 1 == 16 && sizeof(int) == 4);
            char targetWord[BOARD_LENGTH + 1];
            int targetLength;
            fread(&targetLength, sizeof(int), 1, existingSolutionFile);
            fread(targetWord, sizeof(char), BOARD_LENGTH + 1, existingSolutionFile);
            fread(sol, sizeof(Solution), 1, existingSolutionFile);
            fclose(existingSolutionFile);

            //seek to the last word we confirmed was interesting (read time consuming) to evaluate
            char word[BOARD_LENGTH + 1];
            int length;
            while((length = nextWord_threadsafe(dicts.words, word))) {
                if(length == targetLength && strncmp(word, targetWord, length) == 0) {
                    break;
                }
            }
        }
        for(int i = 0; i < NUM_THREADS; ++i) {
            dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Board *board = [[Board alloc] init];
                assert(BOARD_LENGTH + 1 == 16 && sizeof(int) == 4);
                char word[BOARD_LENGTH + 1];
                int length;
                while((length = nextWord_threadsafe(dicts.words, word))) {
                    Solution *temp = [board solveWord:word length:length maxScore:sol->maxScore dict:dicts]; //NOTE: It's possible this could be called while sol is being updated, but the pointer assignment is an atomic operation, so we will get *some* value (and not garbage); it just might be lower than necessary. This could result in some unnecessary computation.
                    if(temp->maxWordLength) {
                        OSSpinLockLock(&lock);

                        if(temp->maxScore > sol->maxScore) {
                            sol = temp;
#ifdef DEBUG
                            printSolution(temp);
#endif
                        }

                        //save the current place and best solution as atomically as possible, in case of a crash
                        FILE *solutionFile = fopen("solutionSoFar.dat", "rb");
                        if(solutionFile) {
                            int status = rename("solutionSoFar.dat", "solutionSoFar.dat_backup");
                            if(status) {
                                fprintf(stderr, "Error backing up solution file");
                                exit(status);
                            }
                        }
                        solutionFile = fopen("solutionSoFar.dat", "wb");
                        fwrite(&length, sizeof(int), 1, solutionFile);
                        fwrite(word, sizeof(char), BOARD_LENGTH + 1, solutionFile);
                        fwrite(sol, sizeof(Solution), 1, solutionFile);
                        fclose(solutionFile);

                        OSSpinLockUnlock(&lock);
                    }
                }
            });
        }
        
        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
        printSolution(sol);

        freeDictionaries(dicts);
        freeDictManager(mgr);
    }
    return 0;
}