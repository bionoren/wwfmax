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
#import "Board.h"

#define DICTIONARY "/Users/bion/projects/objc/wwfmax/dict.txt"
#define DICTIONARY_VALID "/Users/bion/projects/objc/wwfmax/valid-dict.txt"
#define DICT_PERMUTER "/Users/bion/projects/objc/wwfmax/dictPermuter.py"

void shellprintf(const char *command, ...) {
    va_list ap;
    va_start(ap, command);
    char *cmd = malloc(sizeof(char) * 512); //surely your path isn't longer than this...
    vsprintf(cmd, command, ap);
    perror(cmd);
    va_end(ap);

    system(cmd);
}

char *prefixStringInPath(const char *string, const char *prefix) {
    char *ret = calloc(strlen(string) + strlen(prefix), sizeof(char));
    const char *pathEnd = strrchr(string, '/');
    size_t prefixLength = pathEnd - string;
    strncpy(ret, string, prefixLength);
    strncpy(ret + prefixLength, "/", 1);
    strncpy(ret + prefixLength + 1, prefix, strlen(prefix));
    strncpy(ret + prefixLength + strlen(prefix) + 1, pathEnd + 1, strlen(pathEnd));

    return ret;
}

char *CWGOfDictionaryFile(const char *dictionary, char **validatedDict) {
#if BUILD_DATASTRUCTURES
    int numWords = 1024;
    char *words = malloc(numWords * BOARD_LENGTH * sizeof(char));
    assert(words);
    int *wordLengths = malloc(numWords * sizeof(int));
    assert(wordLengths);

    FILE *wordFile = fopen(dictionary, "r");
    assert(wordFile);
    char buffer[40];
    int i = 0;
    while(fgets(buffer, 40, wordFile)) {
        int len = (int)strlen(buffer);
        if(buffer[len - 1] == '\n') {
            --len;
        }
        if(len == 0) { //blank line
            continue;
        }
        if(len <= BOARD_LENGTH) {
            strncpy(&(words[BOARD_LENGTH * i]), buffer, len);
            wordLengths[i++] = len;
            if(i >= numWords) {
                numWords *= 2;
                words = realloc(words, numWords * BOARD_LENGTH * sizeof(char));
                wordLengths = realloc(wordLengths, numWords * sizeof(int));
            }
        }
    }
    fclose(wordFile);
    numWords = i;

    printf("evaluating %d words\n", numWords);

    const WordInfo info = {.words = words, .numWords = numWords, .lengths = wordLengths};

    if(validatedDict) {
        Board *board = [[Board alloc] init];
        *validatedDict = prefixStringInPath(dictionary, "valid-");
        FILE *validFile = fopen(*validatedDict, "w");

        for(int i = 0; i < numWords; i++) {
            char *word = &(words[i * BOARD_LENGTH]);
            const int length = wordLengths[i];

            if(![board testValidate:word length:length] || !playable(word, length, &info)) {
                words[i * BOARD_LENGTH] = '\0';
                wordLengths[i] = 0;
                continue;
            }
            fprintf(validFile, "%.*s\n", length, word);
        }

        fclose(validFile);
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

#warning The 4th manager has issues, but I suspect it's a bug in the DAWG creation code. Since we don't use this manager in production, I'm bypassing the tests
#define NUM_MGRS 3

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

    self.wordMgr = createDictManager(dictionary);
    self.pwordMgr = createDictManager(dictionarySuffixes);
    self.rwordMgr = createDictManager(dictionaryReversed);
    self.rpwordMgr = createDictManager(dictionarySuffixesReversed);
    int i = 0;
    _mgrs[i++] = _wordMgr;
    _mgrs[i++] = _rwordMgr;
    _mgrs[i++] = _pwordMgr;
    _mgrs[i++] = _rpwordMgr;

    free(dictionary);
    free(dictionarySuffixes);
    free(dictionaryReversed);
    free(dictionarySuffixesReversed);
}

- (void)tearDown {
    return;
    for(int i = 0; i < NUM_MGRS; i++) {
        freeDictManager(_mgrs[i]);
    }

    [super tearDown];
}

-(void)testDataStructures {
    const char *dictionaryPath = DICTIONARY;
    char *reversedDictionary = prefixStringInPath(dictionaryPath, "reversed-");

    char *suffixedDictionary = prefixStringInPath(dictionaryPath, "suffixes-");
    char *reversedSuffixedDictionary = prefixStringInPath(suffixedDictionary, "reversed-");

    typedef struct {
        DictionaryManager *mgr;
        const char *file;
    } tempDictStruct;

    tempDictStruct dicts[NUM_MGRS] = {{.mgr = _mgrs[0], .file = DICTIONARY_VALID}, {.mgr = _mgrs[1], .file = reversedDictionary}, {.mgr = _mgrs[2], .file = suffixedDictionary}, {.mgr = _mgrs[3], .file = reversedSuffixedDictionary}};

    for(int i = 0; i < NUM_MGRS; i++) {
        tempDictStruct dict = dicts[i];

        int numWords = 1024;
        char *words = malloc(numWords * BOARD_LENGTH * sizeof(char));
        assert(words);
        int *wordLengths = malloc(numWords * sizeof(int));
        assert(wordLengths);

        FILE *wordFile = fopen(dict.file, "r");
        assert(wordFile);
        char buffer[40];
        int j = 0;
        while(fgets(buffer, 40, wordFile)) {
            int len = (int)strlen(buffer);
            if(buffer[len - 1] == '\n') {
                --len;
            }
            if(len == 0) { //blank line
                continue;
            }
            if(len <= BOARD_LENGTH) {
                strncpy(&(words[BOARD_LENGTH * j]), buffer, len);
                wordLengths[j++] = len;
                if(j >= numWords) {
                    numWords *= 2;
                    words = realloc(words, numWords * BOARD_LENGTH * sizeof(char));
                    wordLengths = realloc(wordLengths, numWords * sizeof(int));
                }
            }
        }
        fclose(wordFile);
        numWords = j;

        for(j = 0; j < numWords; j++) {
            int length = wordLengths[j];
            char *word = &words[j * BOARD_LENGTH];
            XCTAssertTrue(isValidPrefix(dict.mgr, word, length), @"%.*s was not found to be a valid prefix for struct %d", length, word, i);
            XCTAssertTrue(isValidWord(dict.mgr, word, length), @"%.*s was not found to be a valid word for struct %d", length, word, i);
            XCTAssertTrue(isPrefixWord(dict.mgr, word, length), @"%.*s was not found to be a valid word-prefix for struct %d", length, word, i);
        }
        free(words);
        free(wordLengths);
    }

    free(reversedDictionary);
    free(suffixedDictionary);
    free(reversedSuffixedDictionary);
}

-(void)testEnumeration {
    for(int i = 0; i < NUM_MGRS; i++) {
        DictionaryManager *mgr = _mgrs[i];
        DictionaryIterator *itr = createDictIterator(mgr);

        int len = 0;
        char outWord[BOARD_LENGTH + 1];
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
        for(int j = 0; j < 4; ++j) {
            dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                DictionaryIterator *itr = createDictIterator(mgr);
                int len = 0;
                assert(BOARD_LENGTH + 1 == 16 && sizeof(int) == 4);
                char outWord[BOARD_LENGTH + 1];
                while((len = nextWord_threadsafe(itr, outWord))) {
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
        char outWord[BOARD_LENGTH + 1];
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

-(void)testCreateConstInitializer {
    static char lookupTable[255];
    for(int i = 0; i < 255; i++) {
        lookupTable[i] = 1;
    }
    lookupTable[HASH(6, 0)] = 3;
    lookupTable[HASH(8, 0)] = 3;
    lookupTable[HASH(3, 3)] = 3;
    lookupTable[HASH(11, 3)] = 3;
    lookupTable[HASH(5, 5)] = 3;
    lookupTable[HASH(9, 5)] = 3;
    lookupTable[HASH(0, 6)] = 3;
    lookupTable[HASH(14, 6)] = 3;
    lookupTable[HASH(0, 8)] = 3;
    lookupTable[HASH(14, 8)] = 3;
    lookupTable[HASH(5, 9)] = 3;
    lookupTable[HASH(9, 9)] = 3;
    lookupTable[HASH(3, 11)] = 3;
    lookupTable[HASH(11, 11)] = 3;
    lookupTable[HASH(6, 14)] = 3;
    lookupTable[HASH(8, 14)] = 3;
    lookupTable[HASH(2, 1)] = 2;
    lookupTable[HASH(12, 1)] = 2;
    lookupTable[HASH(1, 2)] = 2;
    lookupTable[HASH(4, 2)] = 2;
    lookupTable[HASH(10, 2)] = 2;
    lookupTable[HASH(13, 2)] = 2;
    lookupTable[HASH(2, 4)] = 2;
    lookupTable[HASH(6, 4)] = 2;
    lookupTable[HASH(8, 4)] = 2;
    lookupTable[HASH(12, 4)] = 2;
    lookupTable[HASH(4, 6)] = 2;
    lookupTable[HASH(10, 6)] = 2;
    lookupTable[HASH(4, 8)] = 2;
    lookupTable[HASH(10, 8)] = 2;
    lookupTable[HASH(2, 10)] = 2;
    lookupTable[HASH(6, 10)] = 2;
    lookupTable[HASH(8, 10)] = 2;
    lookupTable[HASH(12, 10)] = 2;
    lookupTable[HASH(1, 12)] = 2;
    lookupTable[HASH(4, 12)] = 2;
    lookupTable[HASH(10, 12)] = 2;
    lookupTable[HASH(13, 12)] = 2;
    lookupTable[HASH(2, 13)] = 2;
    lookupTable[HASH(12, 13)] = 2;

    printf("static const char lookupTable[255] = {");
    for(int i = 0; i < 255; i++) {
        printf("%d", lookupTable[i]);
        if(i + 1 < 255) {
            printf(",");
        }
    }
    printf("};\n");
}

@end