#It's not so much permutations now as it is suffixes - allowing indexing of words by the first letter of their suffix
from iohelper import IOHelper

helper = IOHelper()
indict = helper.readlines("validDict.txt")

outDict = {}

for word in indict:
    for start in range(0, len(word) - 2):
        #for end in range(2, len(word)):
            outDict[word[start:len(word) - 1]] = True

helper.writelines("dictPermuted.txt", sorted(outDict.keys()), "\n")
