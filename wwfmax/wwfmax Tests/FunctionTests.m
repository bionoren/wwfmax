//
//  BoardTests.m
//  wwfmax
//
//  Created by Bion Oren on 12/23/13.
//  Copyright (c) 2013 Llama Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "functions.h"
#import "DictionaryFunctions.h"

@interface FunctionTests : XCTestCase

@property (nonatomic, assign) Dictionaries *dicts;

@end

@implementation FunctionTests

- (void)setUp {
    [super setUp];

    self.dicts = loadDicts(DICTIONARY_TEST);
}

- (void)tearDown {
    free(_dicts);

    [super tearDown];
}

-(void)testPrescore {
    //test prescore (ensure z works)
    char *word = "sizzle";
    int prescore = prescoreWord(word, (int)strlen(word));
    XCTAssertEqual(prescore, 1+1+10+10+2+1);

    //esnure a works and capitals are zero
    word = "alphA";
    prescore = prescoreWord(word, (int)strlen(word));
    XCTAssertEqual(prescore, 1+2+4+3+0);
}

-(void)testScoreLettersWithPrescore {
    char *word = "sizzle";
    int prescore = prescoreWord(word, (int)strlen(word));
    //preplace the first 'z'
    char chars[5] = {'s', 'i', 'z', 'l', 'e'};
    int offsets[5] = {0, 1, 3, 4, 5};
    //test playing across triple letter (l) and triple word (i)
    int score = scoreLettersWithPrescore(prescore, 5, chars, offsets, HASH(2, 0));
    XCTAssertEqual(score, (prescore + 2 + 2) * 3);
    //test playing across triple letter (e) with 'z' preplaced on the triple word
    score = scoreLettersWithPrescore(prescore, 5, chars, offsets, HASH(1, 0));
    XCTAssertEqual(score, (prescore + 1 + 1));
}

//tests 15 character limit, multiple subword combinations, and preplaced vertical word permutations.
-(void)testValidateLetters {
    char *word = "aahscdiambfulzq";
    XCTAssertEqual(strlen(word), (unsigned long)15);
    Subword subwords[2] = {{.start=0, .end=4}, {.start=6, .end=9}};
    NSArray *structs = [WordStructure validateWord:word length:(int)strlen(word) subwords:subwords length:2 iterator:self.dicts->words];
    XCTAssertEqual(structs.count, (NSUInteger)5, @"%@", structs);
    for(int i = 0; i < structs.count; i++) {
        WordStructure *ws = structs[i];
        XCTAssertTrue(ws->_hasVerticalWords);
        XCTAssertEqual(ws->_numLetters, 7);
        for(int j = 0; j < strlen(word); j++) {
            if(j == 10 + i) {
                XCTAssertTrue(ws->_verticalLetters[j], @"failed index %d", j);
            } else {
                XCTAssertFalse(ws->_verticalLetters[j], @"failed index %d", j);
            }
        }
    }
}

//tests rejection of consecutive subwords
-(void)testValidateLetters2 {
    char *word = "aahscdiambfulzq";
    Subword subwords[3] = {{.start=0, .end=2}, {.start=2, .end=4}, {.start=6, .end=9}};
    NSArray *structs = [WordStructure validateWord:word length:(int)strlen(word) subwords:subwords length:3 iterator:self.dicts->words];
    XCTAssertNil(structs);
}

//tests permuting with 2 vertical letters required
-(void)testValidateLetters3 {
    char *word = "abcdaaefghi";
    XCTAssertEqual(strlen(word), (unsigned long)11);
    Subword subwords[1] = {{.start=4, .end=6}};
    NSArray *structs = [WordStructure validateWord:word length:(int)strlen(word) subwords:subwords length:1 iterator:self.dicts->words];
    XCTAssertEqual(structs.count, (NSUInteger)16, @"%@", structs);
    WordStructure *ws = structs[0];
    XCTAssertTrue(ws->_hasVerticalWords);
    XCTAssertEqual(ws->_numLetters, 7);
    for(int i = 0; i < strlen(word); i++) {
        if(i == 0 || i == 2) {
            XCTAssertTrue(ws->_verticalLetters[i], @"failed index %d", i);
        } else {
            XCTAssertFalse(ws->_verticalLetters[i], @"failed index %d", i);
        }
    }
}

-(void)testSubwordsAtLocation {
    //TODO tests word with subwords that can be broken down
    //TODO tests word with 7 letters
    //TODO tests word with overlapping subwords (eg. fasting -> fast + sting)
    //TODO tests word that's too long and can't be broken down
}

@end