//
//  WordStructure.h
//  wwfmax
//
//  Created by Bion Oren on 10/5/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WordStructure : NSObject {
    @public
    Letter _letters[NUM_LETTERS_TURN];
    int _numLetters;
    char *_word;
    int _length;
    Subword _subwords[BOARD_LENGTH];
    int _numSubwords;
}

+(WordStructure*)wordAsLetters:(char*)word length:(const int)length;
-(id)initWithWord:(char*)word length:(const int)length;

-(BOOL)validateSubwords:(Subword*)subwords length:(int)numSubwords info:(const WordInfo*)info;

@end