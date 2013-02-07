//
//  DictionaryManager.h
//  wwfmax
//
//  Created by Bion Oren on 12/9/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>

bool isValidWord(const char *TheCandidate, int CandidateLength);
int hashWord(const char *TheCandidate, int CandidateLength);
int nextWord(char *outWord);

void createDictManager();
void destructDictManager();