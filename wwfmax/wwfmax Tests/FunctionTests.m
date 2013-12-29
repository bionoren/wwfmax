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

//tests word with subwords that can be broken down
-(void)testSubwordsAtLocation {
    char *word = "aahscdfu";
    NSMutableSet *ret = [[NSMutableSet alloc] init];
    subwordsAtLocation(self.dicts->words, &ret, word, (int)strlen(word));
    XCTAssertEqual(ret.count, (NSUInteger)11, @"%@", ret);
    XCTAssertEqual([ret objectsPassingTest:^BOOL(WordStructure *obj, BOOL *stop) {
        return obj->_numSubwords == 1;
    }].count, (NSUInteger)3);
}

//tests word with 7 letters and at least one valid subword
-(void)testSubwordsAtLocation2 {
    char *word = "aahfjkl";
    NSMutableSet *ret = [[NSMutableSet alloc] init];
    subwordsAtLocation(self.dicts->words, &ret, word, (int)strlen(word));
    XCTAssertEqual(ret.count, (NSUInteger)1, @"%@", ret);
}

//tests word with overlapping subwords (eg. fasting -> fast + sting)
-(void)testSubwordAtLocation3 {
    char *word = "refastinglys";
    NSMutableSet *ret = [[NSMutableSet alloc] init];
    subwordsAtLocation(self.dicts->words, &ret, word, (int)strlen(word));
    XCTAssertEqual([ret objectsPassingTest:^BOOL(WordStructure *obj, BOOL *stop) {
        return obj->_numSubwords > 1;
    }].count, (NSUInteger)0);
    XCTAssertTrue([ret objectsPassingTest:^BOOL(WordStructure *obj, BOOL *stop) {
        return obj->_numSubwords == 1;
    }].count > 0);
    //assert that fast appears, and more than once
    int numFast = (int)[ret objectsPassingTest:^BOOL(WordStructure *obj, BOOL *stop) {
        return obj->_numSubwords == 1 && obj->_subwords[0].start == 2 && obj->_subwords[0].end == 6;
    }].count;
    XCTAssertTrue(numFast > 1);
    //asert that sting appears, and only once
    XCTAssertEqual([ret objectsPassingTest:^BOOL(WordStructure *obj, BOOL *stop) {
        return obj->_numSubwords == 1 && obj->_subwords[0].start == 4 && obj->_subwords[0].end == 9;
    }].count, (NSUInteger)1);
    //assert that fasting appears, and only once
    XCTAssertEqual([ret objectsPassingTest:^BOOL(WordStructure *obj, BOOL *stop) {
        return obj->_numSubwords == 1 && obj->_subwords[0].start == 2 && obj->_subwords[0].end == 9;
    }].count, (NSUInteger)1);
    //assert that no other subwords appear
    XCTAssertEqual([ret objectsPassingTest:^BOOL(WordStructure *obj, BOOL *stop) {
        return obj->_numSubwords == 1;
    }].count, (NSUInteger)(numFast + 2));
}

@end