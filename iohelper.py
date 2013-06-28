"""
A collection of helper functions for dealing with the files in the filesystem.
"""
from __future__ import with_statement
import string
import sys



class IOHelper:
    """
    See file description.
    """

    def __init__(self, linebreak="\n"):
        """
        Sets defaults data
        Defines constants for performance benefits (such as precompiling
            regular expressions)
        """
        self.linebreak = linebreak
        self.countstart = False

    def read(self, name):
        """
        Reads all data from the specified file

        name must be the fully qualified path to the file
        """
        with open(name) as temp:
            return temp.read()

    def readlines(self, name):
        """
        Reads all data from the specified file line by line

        name must be the fully qualified path to the file
        """
        with open(name) as temp:
            return temp.readlines()

    def write(self, name, data):
        """
        Erases the file specified by name and writes the given data to it

        name must be the fully qualified path to the file
        """
        with open(name, "w") as temp:
            temp.write(data)

    def writelines(self, name, data, eol=''):
        """
        Erases the file specified by name and writes the given list of data to
            it.
        Each item in the list is written on its own line.

        name must be the fully qualified path to the file.
        eol specifies an optional arguement to use to join the list elements
            Defaults to '' to correctly save data read in from readlines so
            that writelines(file, readlines(file)) has no effect, as expected.
        """
        with open(name, "w") as temp:
            temp.writelines(string.join(data, eol))

    def append(self, name, data):
        """
        Identical to write, except that no data is erased, only appended.
        """
        with open(name, "a") as temp:
            temp.write(data)

    def appendlines(self, name, data, eol=''):
        """
        Identical to writelines, except that no data is erased, only appended.
        """
        with open(name, "a") as temp:
            temp.write(string.join(data, eol))

    def update(self, i=None, length=None):
        """
        Handles percentage and spinner updating
        """
        sys.stdout.flush()
        if i is None and self.countstart:
            print "\b\b"+get_spinner(),
        elif not i is None:
            print "\b\b\b\b\b\b"+str(i*100/length)+"% "+get_spinner(),
            self.countstart = True
        if i == length and not i is None:
            print "\b\b "
            self.countstart = False

    def test(self):
        """
        Performs tests on this module
        """
        try:
            #test standard io
            text = "This is a test of the emergency broadcast system..."
            self.write("testdata/test.txt", text)
            assert(self.read("testdata/test.txt") == text)
            self.append("testdata/test.txt", self.linebreak+text)
            assert(self.read("testdata/test.txt") == text+self.linebreak+text)

            #test io with lists
            data = self.readlines("testdata/test.txt")
            assert(len(data) == 2)
            for line in data:
                assert(line == text+self.linebreak or line == text)
            self.writelines("testdata/test.txt", data)
            assert(self.read("testdata/test.txt") == text+self.linebreak+text)
            self.writelines("testdata/test.txt",
                    [text, text], eol=self.linebreak)
            assert(self.read("testdata/test.txt") == text+self.linebreak+text)
            self.write("testdata/test.txt", "")
            self.appendlines("testdata/test.txt", [text+self.linebreak, text])
            assert(self.read("testdata/test.txt") == text+self.linebreak+text)
            self.write("testdata/test.txt", "")
            self.appendlines("testdata/test.txt",
                    [text, text], eol=self.linebreak)
            assert(self.read("testdata/test.txt") == text+self.linebreak+text)
        except AssertionError:
            print "IOHelper: fail"
            raise
        else:
            print "IOHelper: pass"
