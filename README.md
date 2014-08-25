# git-raw

A [Git](http://www.git-scm.com) plug-in for managing (very) large files.

## Goal statement

The plug-in should

- provide intuitive Git-flavored commands
- allow distributed multi-user work flows
- allow centralized multi-user work flows
- handle sharing of large files across multiple Git clones (even across separate projects) without redundant copies on disk
- track the history of large files in a Git repository similar to normal files (with some caveats, e.g., diffs)
- allow the user to manage disk space by cherry-picking the files he/she wants to have available locally at any one time
- assist in practical management of up/downloads of files between clones and remotes

## Foundations

Similar to Git, git-raw stores files as a set of key/value pairs, with keys being the SHA-1 hash values of each file's content. Within a Git repository, soft links are used to point to file content and to keep track version history.

### Content stores

git-raw can be customized to use multiple user-defined locations for the storage of files. These locations may be directories on local hard drives, network drives, USB drives, etc. and are called content stores. git-raw allows each user to define his/her own preferred set of stores in which to store content. Distinct repositories on the same local machine can share content stores thereby minimize redundancies in cases when different repositories have some large files in common.

Information about the content stores associated with each repository clone is kept in a separate branch with the special name "git-raw". The "git-raw" branch is handled by the git-raw plugin and stores information that can be used by other clones to obtain the content of files, and if enabled, to push new content to remote Git repositories.

## Current project state

Just started so it's all just promises :-).

## Other similar projects

There are other solutions out there for handling large files with Git. Below I list some differences between git-raw and the projects that I have taken a closer look at. There are other projects besides the ones listed below and I might add some comparisons to those in the future.

### Git submodules

It is possible to keep track of large files of a project using a separate Git repository for large files and include that repository as a [submodule](http://git-scm.com/book/en/Git-Tools-Submodules) in the main repository.

I found this solution to be quite restrictive:

1. Each repository clone needs to clone its own submodule, leading to unnecessary bloat for the type of projects that I deal with (I usually only need a small subset of all large files in my projects at any one time)
2. Managing submodules requires a lot of manual fiddling
3. It is hard to share large files across different projects without storing redundant copies

### git-annex

I think [git-annex](https://git-annex.branchable.com/) is a very interesting project. In fact, a lot of the inspiration for git-raw comes directly from the implementation details of git-annex. The main reason for me not using git-annex is that it is not really designed for keeping track of the history of files along with the rest of your project. I may be mistaken, but after spending some time trying to understand how git-annex works, I found that it is not compatible with all the different ways that people traditionally use Git and the different types of work flows out there.

I think that the main goals of git-annex are somewhat different from my goals. git-annex is a very good tool for storing files in a decentralized manner across multiple machines and drives. But my main requirement was to be able to handle large files in the same spirit as Git manages source code and so allow for all (or at least most of) the different work flows that are in use.

Another reason is that I wanted to be able to keep a single local copy of a large file that was used in multiple different projects. This is again something that I don't think git-annex was designed for.

### git-fat

This is another project that comes very close to meeting the goals of git-raw. The downsides of git-fat, for my personal use-cases, include

1. does not use soft links, and therefore, requires an extra copy (one in the fat store and one in the working directory) of each large file that you want to work with, even if you only need read access to those large files. This is a big issue for me because I need to be able to handle really huge files (hundreds of GBs). There is no way I would want to have even a single unnecessary copy of one of those files.
2. does not (at least currently) support multiple different fat-stores
