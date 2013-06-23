//
//  DictionaryManager.m
//  wwfmax
//
//  Created by Bion Oren on 12/9/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import "DictionaryManager.h"

#import "CWGLib.h"

#define GRAPH_DATA "/Users/bion/Downloads/CWG_Data_For_Word-List.dat"

// The CWG basic-type arrays will have global scope to reduce function-argument overhead.
static int *nodeArray;
static int *listFormatArray;
static int *root_WTEOBL_Array;
static short *short_WTEOBL_Array;
static unsigned char *unsignedChar_WTEOBL_Array;

// These two values are needed for the CWG Hash-Function.
static int WTEOBL_Transition;

// Use the first two CWG arrays to return a boolean value indicating if "TheCandidate" word is in the lexicon.
bool isValidWord(const char *TheCandidate, int CandidateLength) {
    int CurrentLetterPosition = TheCandidate[0] - 'a';
    int CurrentNodeIndex = CurrentLetterPosition + 1;
    for(int X = 1; X < CandidateLength; X++) {
        if(!(nodeArray[CurrentNodeIndex] & CHILD_MASK)) {
            return false;
        }
        int CurrentChildListFormat = listFormatArray[(nodeArray[CurrentNodeIndex] & LIST_FORMAT_INDEX_MASK) >> LIST_FORMAT_BIT_SHIFT];
        CurrentLetterPosition = TheCandidate[X] - 'a';
        if(!(CurrentChildListFormat & PowersOfTwo[CurrentLetterPosition])) {
            return false;
        } else {
            CurrentNodeIndex = (nodeArray[CurrentNodeIndex] & CHILD_MASK) + ListFormatPopCount(CurrentChildListFormat, CurrentLetterPosition);
        }
    }
    return nodeArray[CurrentNodeIndex] & EOW_FLAG;
}

// Using a novel graph mark-up scheme, this function returns the hash index of "TheCandidate", and "0" if it does not exist.
// This function uses the additional 3 WTEOBL arrays.
int hashWord(const char *TheCandidate, const int CandidateLength) {
    int CurrentLetterPosition = TheCandidate[0] - 'a';
    int CurrentNodeIndex = CurrentLetterPosition + 1;
    int CurrentHashMarker = root_WTEOBL_Array[CurrentNodeIndex];
    for(int i = 1; i < CandidateLength; i++) {
        int node = nodeArray[CurrentNodeIndex];
        if(!(node & CHILD_MASK)) {
            return 0;
        }

        int TheChildListFormatIndex = (node & LIST_FORMAT_INDEX_MASK) >> LIST_FORMAT_BIT_SHIFT;
        bool extendedList = TheChildListFormatIndex & PowersOfTwo[12];
        TheChildListFormatIndex -= extendedList * PowersOfTwo[12];
        int CurrentChildListFormat = listFormatArray[TheChildListFormatIndex];
        CurrentChildListFormat += extendedList << (CurrentChildListFormat >> NUMBER_OF_ENGLISH_LETTERS);

        CurrentLetterPosition = TheCandidate[i] - 'a';
        if(!(CurrentChildListFormat & PowersOfTwo[CurrentLetterPosition])) {
            return 0;
        } else {
            CurrentNodeIndex = node & CHILD_MASK;
            // Use "TheShort_WTEOBL_Array".
            if(CurrentNodeIndex < WTEOBL_Transition) {
                CurrentHashMarker -= short_WTEOBL_Array[CurrentNodeIndex];
                CurrentNodeIndex += ListFormatPopCount(CurrentChildListFormat, CurrentLetterPosition);
                CurrentHashMarker += short_WTEOBL_Array[CurrentNodeIndex];
            } else { // Use "TheUnsignedChar_WTEOBL_Array".
                CurrentHashMarker -= unsignedChar_WTEOBL_Array[CurrentNodeIndex - WTEOBL_Transition];
                CurrentNodeIndex += ListFormatPopCount(CurrentChildListFormat, CurrentLetterPosition);
                CurrentHashMarker += unsignedChar_WTEOBL_Array[CurrentNodeIndex - WTEOBL_Transition];
            }
            if(nodeArray[CurrentNodeIndex] & EOW_FLAG) {
                CurrentHashMarker--;
            }
        }
    }
    return (nodeArray[CurrentNodeIndex] & EOW_FLAG) * (root_WTEOBL_Array[1] - CurrentHashMarker);
}

static NSObject *syncObject;

#define HASH_DEBUG DEBUG && NUM_THREADS == 1

#if HASH_DEBUG
static int lastHash = 0;
#endif

//cf. Justin-CWG-Search.c:104ff
int nextWord(char *outWord) {
    typedef struct dictStack {
        //current node list. This will get you a node, which lets you go down a level.
        int index; //index into the start of a child group in the nodeArray
        int childLetterIndexOffset; //offset into the child group
        //from parent. This will get you a letter at this stack level (by updating childLetterIndexOffset)
        char childLetterFormatOffset; //english letter offset into the child group (a=0 to z)
        int childListFormat; //z-a bitstring (NOT index into the childLists table)
    } dictStack;
    
    static dictStack stack[BOARD_LENGTH] = {{.index = 1, .childLetterIndexOffset = 0, .childLetterFormatOffset = 0, .childListFormat = 0xFFFFFFFF}, {0}};
    
    //word we've currently built / are building
    static char tmpWord[BOARD_LENGTH] = {'\0'};
    //position in all of the above stacks
    static int stackDepth = 0;

    int length = 0;
    @synchronized(syncObject) {
        //1. go down as far as you can
        //2. go up 1 AND over 1 - childLetterIndexOffset++ (via childLetterFormatOffset += from childListFormat)
        //3. goto 1
        //stop if you've gone up past 0
        //break if you hit EOW

        assert(stackDepth >= 0 && stackDepth <= BOARD_LENGTH);
        //load state
        dictStack *item = &(stack[stackDepth]);
        int node = nodeArray[item->index + item->childLetterIndexOffset];
        int childIndex = node & CHILD_MASK;
        
        //if there are unexplored children
        //else drop back until there are unexplored children
        if(!node) {
            while(true) {
                for(item->childLetterFormatOffset++; item->childLetterFormatOffset < NUMBER_OF_ENGLISH_LETTERS; item->childLetterFormatOffset++) {
                    if(item->childListFormat & PowersOfTwo[item->childLetterFormatOffset]) {
                        ++item->childLetterIndexOffset;
                        goto LOOP_END;
                    }
                }
                item = &(stack[--stackDepth]);
                if(stackDepth < 0) {
                    return 0;
                }
            }
        }
    LOOP_END:
        
        //and explore them
        do {
            //get the node
            node = nodeArray[item->index + item->childLetterIndexOffset];
            childIndex = node & CHILD_MASK;

            //store the letter and go down
            tmpWord[stackDepth++] = 'a' + item->childLetterFormatOffset;
            assert(stackDepth <= BOARD_LENGTH);

            //setup the next node
            item = &(stack[stackDepth]);
            item->index = childIndex;
            item->childLetterIndexOffset = 0;
            item->childLetterFormatOffset = 0;
            int childListFormatIndex = (node & LIST_FORMAT_INDEX_MASK) >> LIST_FORMAT_BIT_SHIFT;
            bool extendedList = childListFormatIndex & PowersOfTwo[12];
            childListFormatIndex -= extendedList * PowersOfTwo[12];
            int childListFormat = listFormatArray[childListFormatIndex];
            childListFormat += extendedList << (childListFormat >> NUMBER_OF_ENGLISH_LETTERS);
            item->childListFormat = childListFormat;

            //seek to the first letter in the list
            for(; item->childLetterFormatOffset < NUMBER_OF_ENGLISH_LETTERS; item->childLetterFormatOffset++) {
                if(item->childListFormat & PowersOfTwo[item->childLetterFormatOffset]) {
                    break;
                }
            }
        } while(!(node & EOW_FLAG));
        
        length = stackDepth;
        assert(length > 1 && length <= BOARD_LENGTH);
        strncpy(outWord, tmpWord, length);
        //NSLog(@"Evaluating %.*s", length, tmpWord);
    }
#if HASH_DEBUG
    assert(hashWord(outWord, length) == ++lastHash);
#endif
    return length;
}

void createDictManager() {
    syncObject = [[NSObject alloc] init];
    
    // Array size variables.
    int NodeArraySize;
    int ListFormatArraySize;
    int Root_WTEOBL_ArraySize;
    int Short_WTEOBL_ArraySize;
    int UnsignedChar_WTEOBL_ArraySize;
    
    // Read the CWG graph, from the "GRAPH_DATA" file, into the global arrays.
    FILE *data = fopen(GRAPH_DATA, "rb");
    assert(data);
    
    // Read the array sizes.
    fread(&NodeArraySize, sizeof(int), 1, data);
    assert(NodeArraySize > 0);
    fread(&ListFormatArraySize, sizeof(int), 1, data);
    assert(ListFormatArraySize > 0);
    fread(&Root_WTEOBL_ArraySize, sizeof(int), 1, data);
    assert(Root_WTEOBL_ArraySize > 0);
    fread(&Short_WTEOBL_ArraySize, sizeof(int), 1, data);
    assert(Short_WTEOBL_ArraySize > 0);
    fread(&UnsignedChar_WTEOBL_ArraySize, sizeof(int), 1, data);
    assert(UnsignedChar_WTEOBL_ArraySize > 0);
    
    // Allocate memory to hold the arrays.
    nodeArray = (int *)malloc(NodeArraySize*sizeof(int));
    listFormatArray = (int *)malloc(ListFormatArraySize*sizeof(int));
    root_WTEOBL_Array = (int *)malloc(Root_WTEOBL_ArraySize*sizeof(int));
    short_WTEOBL_Array = (short int *)malloc(Short_WTEOBL_ArraySize*sizeof(short int));
    unsignedChar_WTEOBL_Array = (unsigned char *)malloc(UnsignedChar_WTEOBL_ArraySize*sizeof(unsigned char));
    
    // Read the 5 arrays into memory.
    fread(nodeArray, sizeof(int), NodeArraySize, data);
    fread(listFormatArray, sizeof(int), ListFormatArraySize, data);
    printf("list format array = %p\n", listFormatArray);
    fread(root_WTEOBL_Array, sizeof(int), Root_WTEOBL_ArraySize, data);
    fread(short_WTEOBL_Array, sizeof(short int), Short_WTEOBL_ArraySize, data);
    fread(unsignedChar_WTEOBL_Array, sizeof(unsigned char), UnsignedChar_WTEOBL_ArraySize, data);
    
    fclose(data);
    
    // Make the proper assignments and adjustments to use the CWG.
    WTEOBL_Transition = Short_WTEOBL_ArraySize;
}

void destructDictManager() {
    free(nodeArray);
    free(listFormatArray);
    free(root_WTEOBL_Array);
    free(short_WTEOBL_Array);
    free(unsignedChar_WTEOBL_Array);
}