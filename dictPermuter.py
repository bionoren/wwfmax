from iohelper import IOHelper

helper = IOHelper()
indict = helper.readlines("validDict.txt")

outDict = {}

for word in indict:
    for start in range(0, len(word)):
        for end in range(start + 2, len(word)):
            outDict[word[start:end]] = True

helper.writelines("dictPermuted.txt", sorted(outDict.keys()), "\n")