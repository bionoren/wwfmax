//
//  WordStructure.h
//  wwfmax
//
//  Created by Bion Oren on 10/5/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DictionaryManager.h"

@interface WordStructure : NSObject {
    @public
    Letter _letters[NUM_LETTERS_TURN];
    int _numLetters;
    char *_word;
    int _length;
    Subword _subwords[BOARD_LENGTH / 2];
    int _numSubwords;
    bool _hasVerticalWords;
    bool _verticalLetters[BOARD_LENGTH];
}

+(WordStructure*)wordAsLetters:(char[BOARD_LENGTH + 1])word length:(const int)length;
+(NSArray*)validateWord:(char[BOARD_LENGTH + 1])word length:(int)length subwords:(Subword*)subwords length:(int)numSubwords iterator:(DictionaryIterator*)itr wordInfo:(const WordInfo*)info;

@end