//
//  main.m
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Board.h"

//anecdotally, ~2.5% of the shipped dictionary is unplayable, mostly because the words are too long for the board, but also because there aren't enough of the required letters and because some words can't be broken down into sufficiently small subwords

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"%@", [[[NSFileManager alloc] init] currentDirectoryPath]);
        Board *board = [[Board alloc] init];
        
        int numWords = 173101;
        char *words = calloc(numWords * BOARD_LENGTH, sizeof(char));
        int *wordLengths = calloc(numWords, sizeof(int));
        FILE *wordFile = fopen("dict.txt", "r");
        char buffer[40];
        if(wordFile) {
            int i = 0;
            int pos = 0;
            while(fgets(buffer, 40, wordFile)) {
                size_t len = strlen(buffer) - 1;
                if(len <= BOARD_LENGTH) {
                    strncpy(&words[pos], buffer, len);
                    wordLengths[i++] = (int)len;
                    pos += BOARD_LENGTH;
                }
            }
            numWords = i - 1;
        }
        [board solve:words lengths:wordLengths count:numWords];
        free(words);
        free(wordLengths);
    }
    return 0;
}