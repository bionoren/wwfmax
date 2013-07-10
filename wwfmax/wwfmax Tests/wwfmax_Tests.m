//
//  DictionaryManagerTests.m
//  wwfmax
//
//  Created by Bion Oren on 7/10/13.
//  Copyright (c) 2013 Llama Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DictionaryManager.h"

#define NUM_MGRS 4

@interface wwfmax_Tests : XCTestCase {
    DictionaryManager *_mgrs[NUM_MGRS];
}

@property (nonatomic, assign) DictionaryManager *wordMgr;
@property (nonatomic, assign) DictionaryManager *rwordMgr;
@property (nonatomic, assign) DictionaryManager *pwordMgr;
@property (nonatomic, assign) DictionaryManager *rpwordMgr;

@end

@implementation wwfmax_Tests

- (void)setUp {
    [super setUp];

    char *dictionary = CWGOfDictionaryFile("/Users/bion/projects/objc/wwfmax/dict.txt", 173101, true);
    char *dictionaryReversed = CWGOfDictionaryFile("/Users/bion/projects/objc/wwfmax/dictReversed.txt", 173101, false);
    char *dictionaryPermuted = CWGOfDictionaryFile("/Users/bion/projects/objc/wwfmax/dictPermuted.txt", 952650, false);
    char *dictionaryPermutedReversed = CWGOfDictionaryFile("/Users/bion/projects/objc/wwfmax/dictPermutedReversed.txt", 952650, false);

    self.wordMgr = createDictManager(dictionary);
    self.rwordMgr = createDictManager(dictionaryReversed);
    self.pwordMgr = createDictManager(dictionaryPermuted);
    self.rpwordMgr = createDictManager(dictionaryPermutedReversed);
    int i = 0;
    _mgrs[i++] = _wordMgr;
    _mgrs[i++] = _rwordMgr;
    _mgrs[i++] = _pwordMgr;
    _mgrs[i++] = _rpwordMgr;
}

- (void)tearDown {
    for(int i = 0; i < NUM_MGRS; i++) {
        freeDictManager(_mgrs[i]);
    }

    [super tearDown];
}

-(void)testEnumeration {
    for(int i = 0; i < NUM_MGRS; i++) {
        DictionaryManager *mgr = _mgrs[i];
        DictionaryIterator *itr = createDictIterator(mgr);

        int len = 0;
        char *outWord;
        while((len = nextWord(itr, &outWord))) {
            XCTAssert(isValidWord(mgr, outWord, len), @"Generated %.*s, but it's not recognized as a valid word...", len, outWord);
        }
        resetIterator(itr);
        while((len = nextWord(itr, &outWord)));
    }
}

-(void)testThreadsafeEnumeration {
    for(int i = 0; i < NUM_MGRS; i++) {
        DictionaryManager *mgr = _mgrs[i];

        dispatch_group_t dispatchGroup = dispatch_group_create();
        for(int i = 0; i < 4; ++i) {
            dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                DictionaryIterator *itr = createDictIterator(mgr);
                int len = 0;
                assert(BOARD_LENGTH + 1 == 16 && sizeof(int) == 4);
                char *outWord;
                while((len = nextWord(itr, &outWord))) {
                    XCTAssert(isValidWord(mgr, outWord, len), @"Generated %.*s, but it's not recognized as a valid word...", len, outWord);
                }
            });
        }

        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
    }
}

-(void)testFastPrefixEnumeration {
    for(int i = 0; i < NUM_MGRS; i++) {
        DictionaryManager *mgr = _mgrs[i];
        DictionaryIterator *itr = createDictIterator(mgr);

        int len = 0;
        char *outWord;
        while((len = nextPrefix(itr, &outWord))) {
            XCTAssert(isValidPrefix(mgr, outWord, len) >= 0, @"Valid prefix %.*s is not recognized as valid", len, outWord);
        }
    }
}

-(void)testPrefixedEnumeration {
    for(int i = 0; i < 1; i++) {
        DictionaryManager *mgr = _mgrs[i];
        DictionaryIterator *baseitr = createDictIterator(mgr);
        DictionaryIterator *prefixitr = createDictIterator(mgr);

        int len = 0;
        char *outWord;
        int prefixLen = 0;
        assert(BOARD_LENGTH + 1 == 16 && sizeof(int) == 4);
        char *prefixOutWord = calloc(BOARD_LENGTH + 1, sizeof(char));
        while((len = nextWord(baseitr, &outWord))) {
            for(int j = 1; j < len; j++) {
                XCTAssert(loadPrefix(prefixitr, outWord, j), @"Failed to load prefix %.*s", j, outWord);

                int numGeneratedWords = 0;
                while(true) {
                    prefixLen = nextWordWithPrefix(prefixitr, prefixOutWord, BOARD_LENGTH);
                    if(prefixLen == 0) {
                        break;
                    }
                    XCTAssert(strncmp(outWord, prefixOutWord, j) == 0, @"%.*s != %.*s", j, outWord, j, prefixOutWord);
                    numGeneratedWords++;
                }
                XCTAssert(numGeneratedWords > 0 || isValidWord(mgr, outWord, len), @"No words generated from prefix %.*s (which is also not a word)", j, outWord);

                resetIteratorToPrefix(prefixitr);
                numGeneratedWords = 0;
                while(true) {
                    int maxLen = rand() % (BOARD_LENGTH - len + 1) + len;
                    XCTAssert(maxLen <= BOARD_LENGTH && maxLen >= len, @"%d not between the expected range [%d, %d]", maxLen, len, BOARD_LENGTH);
                    prefixLen = nextWordWithPrefix(prefixitr, prefixOutWord, maxLen);
                    if(prefixLen == 0) {
                        break;
                    }
                    XCTAssert(strncmp(outWord, prefixOutWord, j) == 0, @"%.*s != %.*s", j, outWord, j, prefixOutWord);
                    numGeneratedWords++;
                }
                XCTAssert(numGeneratedWords > 0 || isValidWord(mgr, outWord, len), @"No words generated from prefix %.*s (which is also not a word)", j, outWord);
            }
        }
        free(prefixOutWord);
    }
}

@end