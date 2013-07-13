#It's not so much permutations now as it is suffixes - allowing indexing of words by the first letter of their suffix
#What I really want are words or suffixes for which the string is a word with the first letter removed
from iohelper import IOHelper

helper = IOHelper()
indict = helper.readlines("validDict.txt")

outDict = {}

from bisect import bisect_left

def binary_search(a, x, lo=0, hi=None):   # can't use a to specify default for hi
    hi = hi if hi is not None else len(a) # hi defaults to len(a)
    pos = bisect_left(a,x,lo,hi)          # find insertion position
    return (pos if pos != hi and a[pos] == x else -1) # don't walk off the end

for word in indict:
    for start in range(0, len(word) - 2):
        string = word[start:]
        if binary_search(indict, string[1:]) >= 0:
            outDict[string[:len(string) - 1]] = True

helper.writelines("dictPermuted.txt", sorted(outDict.keys()), "\n")