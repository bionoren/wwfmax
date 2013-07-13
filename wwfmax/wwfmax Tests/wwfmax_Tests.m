//
//  DictionaryManagerTests.m
//  wwfmax
//
//  Created by Bion Oren on 7/10/13.
//  Copyright (c) 2013 Llama Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <sys/time.h>
#import "DictionaryManager.h"

char *CWGOfDictionaryFile(const char *dictionary, int numWords, bool validate) {
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

    if(validate) {
        for(int i = 0; i < numWords; i++) {
            char *word = &(words[i * BOARD_LENGTH]);
            const int length = wordLengths[i];

            if(!playable(word, length, &info)) {
                words[i * BOARD_LENGTH] = 0;
                wordLengths[i] = 0;
                continue;
            }
        }
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
        while((len = nextWord(itr, outWord))) {
            XCTAssert(isValidWord(mgr, outWord, len), @"Generated %.*s, but it's not recognized as a valid word...", len, outWord);
        }
        resetIterator(itr);
        while((len = nextWord(itr, outWord)));
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
                while((len = nextWord(itr, outWord))) {
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
        while((len = nextWord(baseitr, outWord))) {
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

-(void)testProfileSuffixVsWord {
#define STR_REV_IN_PLACE(word, len) for(int z = 0; z < len / 2; ++z) { \
    word[z] ^= word[len - 1 - z];\
    word[len - 1 - z] ^= word[z];\
    word[z] ^= word[len - 1 - z];\
}
#define STR_REV(dst, src, len) for(int z = 0; z < len; ++z) { \
    dst[z] = src[len - z - 1];\
}

    DictionaryIterator *wordItr = createDictIterator(_wordMgr);
    DictionaryIterator *pwordItr = createDictIterator(_pwordMgr);

    int len = 0;
    char outWord[BOARD_LENGTH + 1];
    char *revWord = calloc(BOARD_LENGTH + 1, sizeof(char));
    struct timeval tv;
    long start, end;
    unsigned int foo;

    foo = 0;
    gettimeofday(&tv, NULL);
    start = 1000000 * tv.tv_sec + tv.tv_usec;
    for(int i = 0; i < 26; i++) {
        char c = 'a' + (char)i;
        while((len = nextWord(wordItr, outWord))) {
            if(len < BOARD_LENGTH) {
                STR_REV(revWord, outWord, len);
                revWord[len++] = c;
                if(isValidPrefix(_rwordMgr, revWord, len)) {
                    foo++;
                }
            }
        }
        resetIterator(wordItr);
    }
    gettimeofday(&tv, NULL);
    end = 1000000 * tv.tv_sec + tv.tv_usec;
    printf("foo = %d\n", foo);
    printf("Word iteration took %ld microseconds\n", end - start);

    foo = 0;
    gettimeofday(&tv, NULL);
    start = 1000000 * tv.tv_sec + tv.tv_usec;
    for(int i = 0; i < 26; i++) {
        char c = 'a' + (char)i;
        loadPrefix(pwordItr, &c, 1);
        while((len = nextWordWithPrefix(pwordItr, outWord, BOARD_LENGTH - 1))) {
            if(isValidWord(_wordMgr, outWord + 1, len - 1)) {
                STR_REV(revWord, outWord, len);
                foo++;
            }
        }
        resetIterator(pwordItr);
    }
    gettimeofday(&tv, NULL);
    end = 1000000 * tv.tv_sec + tv.tv_usec;
    printf("pWord iteration took %ld microseconds\n", end - start);
    printf("foo = %d\n", foo);

    free(revWord);
}

@end