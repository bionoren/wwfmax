//
//  main.m
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#define BUILD_DATASTRUCTURES 0

#import <Foundation/Foundation.h>
#import "Board.h"
#import "functions.h"
#import "CWG-Creator.h"
#import "Justin-CWG-Search.h"
#import "DictionaryManager.h"

//anecdotally, ~2.5% of the shipped dictionary is unplayable, mostly because the words are too long for the board, but also because there aren't enough of the required letters and because some words can't be broken down into sufficiently small subwords

int main(int argc, const char * argv[]) {
    @autoreleasepool {
#if BUILD_DATASTRUCTURES
        assert(sizeof(short) >= 2);
        assert(HASH(11, 3) == 59); //3,11
        Letter hash = HASH(BOARD_LENGTH, 'z');
        assert(X_FROM_HASH(hash) == BOARD_LENGTH);
        assert((char)Y_FROM_HASH(hash) == 'z');
        
        NSLog(@"%@", [[[NSFileManager alloc] init] currentDirectoryPath]);
        
        int numWords = 173101;
        char *words = calloc(numWords * BOARD_LENGTH, sizeof(char));
        assert(words);
        int *wordLengths = malloc(numWords * sizeof(int));
        assert(wordLengths);
        
        FILE *wordFile = fopen("dict.txt", "r");
        assert(wordFile);
        char buffer[40];
        int i = 0;
        char *word = words;
        while(fgets(buffer, 40, wordFile)) {
            int len = (int)strlen(buffer);
            if(buffer[len - 1] == '\n') {
                --len;
            }
            if(len <= BOARD_LENGTH) {
                strncpy(word, buffer, len);
                wordLengths[i++] = len;
                assert(i < numWords);
                word += BOARD_LENGTH * sizeof(char);
            }
        }
        numWords = i;
        
        NSLog(@"evaluating %d words", numWords);
        
        const WordInfo info = {.words = words, .numWords = numWords, .lengths = wordLengths, .prescores = prescores};
        
        for(int i = 0; i < numWords; i++) {
            char *word = &(words[i * BOARD_LENGTH]);
            const int length = wordLengths[i];
            
            if(!playable(word, length, &info)) {
                words[i * BOARD_LENGTH] = 0;
                wordLengths[i] = 0;
                continue;
            }
        }
        
        createDataStructure(&info);
        free(words);
        free(wordLengths);
#endif
#ifdef DEBUG
        debug();
#endif
        
        createDictManager();

        int *prescores = malloc(numWords() * sizeof(int));
        assert(prescores);
        char word[BOARD_LENGTH];
        int length;
        while((length = nextWord(word))) {
            prescores[hashWord(word, length)] = prescoreWord(word, length);
        }
        resetDictionary();
        
        __block Solution sol;
        sol.maxScore = 0;
        NSLock *lock = [[NSLock alloc] init];
        dispatch_group_t dispatchGroup = dispatch_group_create();
        for(int i = 0; i < NUM_THREADS; ++i) {
            dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Board *board = [[Board alloc] init];
                Solution temp = [board solve:prescores];
                if([lock lockBeforeDate:[NSDate distantFuture]]) {
                    if(temp.maxScore > sol.maxScore) {
                        sol = temp;
                    }
                    [lock unlock];
                }
            });
        }
        
        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
        printSolution(sol);
        
        destructDictManager();
        free(prescores);
    }
    return 0;
}