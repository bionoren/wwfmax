//
//  dawg.h
//  wwfmax
//
//  Created by Bion Oren on 7/1/13.
//  Copyright (c) 2013 Llama Software. All rights reserved.
//

#ifndef wwfmax_dawg_h
#define wwfmax_dawg_h

// This program will compile a Traditional DAWG encoding from the "Word-List.txt" file.
// Updated on Monday, December 29, 2011.

// A graph compression algorithm this FAST is perfectly suited for record-keeping-compression while solving an NP-Complete.

// 7 Major concerns addressed:
// 0) A user defined character set of up to 256 letters is now supported.  This accomodates certain foreign lexicons.
// 1) Allowance for medium sized word lists. 2^22 DAWG node count is the new upper limit.
// 2) Superior "ReplaceMeWith" scheme.
// 3) The use of CRC-Digest calculation, "Tnode" segmentation, and stable group sorting render DAWG creation INSTANTANEOUS.
// 4) Certain Graph configurataions led the previous version of this program to crash...  NO MORE.
// 5) A new DAWG int-node format is used to reduce the number of bitwise operations + add direct "char" extraction.

// "Word-List.txt" is a text file with the number of words written on the very first line, and 1 word per line after that.
// The words are case-insensitive for English letters, and the text file may have Windows or Linux format.
// *** MAX is the length of the longest word in the list. Change this value.
// *** MIN is the length of the shortest word in the list.  Change this value.

// Include the big-three header files.
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// General high-level program constants.
#define MERGE_SORT_THRESHOLD 1
#define MIN_LEN 2
#define MAX_LEN 15
#define SIZE_OF_CHARACTER_SET 26
#define INPUT_LIMIT 35
#define LOWER_IT 32
#define INT_BITS 32
#define CHILD_BIT_SHIFT 10
// CHILD_INDEX_BIT_MASK is designed NEVER to be used.
#define CHILD_INDEX_BIT_MASK 0XFFFFFC00
#define END_OF_WORD_BIT_MASK 0X00000200
#define END_OF_LIST_BIT_MASK 0X00000100
#define LETTER_BIT_MASK 0X000000FF
#define CHILD_CYPHER 0X1EDC6F41
#define NEXT_CYPHER 0X741B8CD7
#define TWO_UP_EIGHT 256
#define LEFT_BYTE_SHIFT 24
#define BYTE_WIDTH 8

// An explicit table-lookup CRC calculation will be used to identify unique graph branch configurations.
#define LOOKUP_TABLE_DATA "/Users/bion/projects/objc/wwfmax/wwfmax/wwfmax/CRC-32.dat"

// Lookup tables used for node encoding and number-string decoding.
static const int PowersOfTwo[INT_BITS] = { 0X1, 0X2, 0X4, 0X8, 0X10, 0X20, 0X40, 0X80, 0X100, 0X200, 0X400, 0X800,
    0X1000, 0X2000, 0X4000, 0X8000, 0X10000, 0X20000, 0X40000, 0X80000, 0X100000, 0X200000, 0X400000, 0X800000, 0X1000000,
    0X2000000, 0X4000000, 0X8000000, 0X10000000, 0X20000000, 0X40000000, 0X80000000 };

static const int PowersOfTen[10] = { 1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000 };

static const unsigned char CharacterSet[SIZE_OF_CHARACTER_SET] = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
    'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' };

// Some word lists will contain letters that NO words begin with.  Place "0"s in the corresponding positions.
static const unsigned char EntryNodeIndex[SIZE_OF_CHARACTER_SET] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
    20, 21, 22, 23, 24, 25, 26 };


int createDataStructure(const WordInfo *info, const char *outFile);

#endif