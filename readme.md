### About
This is a research project. I don't expect this to be useful for anyone, it simply satisfies my curiousity in a really challenging way.

Speaking of which, this problem is hard. Really hard. There's ongoing discussion amongst my friends on the tractability of this problem. I examine assembly output to verify optimizations I expect - That's the level I'm working at. Don't be surprised when you encounter obtuse code.

### Requirements
Xcode 4.3+ (Xcode 5 for unit tests)

### Note on the Dictionary Structure
I'm using the best data structure I could find - the Caroline Word Graph (blame [this guy](http://www.pathcom.com/~vadco/cwg.html "Title") for the name). Basically, small dictionaries mean less cache thrash which translates into less waiting and more processing. His implementation is broken though, so I fixed it and added some enhancements to further compact the datastructure. It was designed to be iterated recursively, so I'm currently writing a threadsafe iterator.

### Architecture Notes
Words with friends has 4 axes of symmetry of which we can only use 1 in practice. Words are played horizontally before examining words played vertically off them (what I call "side-words"). Interaction with these side-words and with bonus tiles is why we can't fully exploit all axes.

Individual words can be examined in parallel, allowing the algorithm to fully utilize (at least initially) as many cores are there are english words, making the word fetching (ie dictionary walking) code the major synchronization point. It is probably also possible to thread aspects of the side-word search space, but it has not become practical because all available cores are already in use. If someone would like to donate supercomputer time to this project, that may be worth investigating.

There are dozen of other optimizations from local caching to putting the xy coordinates in a single int so we can switch on it. I'm not going to go into great detail here, but I probably should provide more documentation than I do. You should file an issue if you're interested in better docs.

A quick note about GPUs: [Stanford](http://ppl.stanford.edu/cs315a/pub/Main/CS315aWiki2010/FP_wheelerj_yifanz.pdf "Title") says no. In fairness, it was scrabble in 2010, but it's probably still true that it's a lot of work for little benefit. People who know better should submit issues (or pull requests!) and tell me why I'm wrong. I might look into this later too...
