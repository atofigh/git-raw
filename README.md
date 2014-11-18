# git-raw

A [Git](http://www.git-scm.com) plug-in for managing binary and/or large files.

#### The problem:

Adding large files (such as media files or databases) to a Git repository is unwieldy and often results in poor performance (e.g., slow cloning of repositories) and unnecessary duplication of file content (as a result of having one copy in the Git repository and one copy checked out in the working directory).

#### git-raw's solution:

Store the content of large files separately from the Git repository and let Git track symbolic links to such content.

#### Why this is a good solution:

- Results in **small Git repositories** and **fast Git operations**
- Only a **single local copy** of each large file's content is required **across any number of repositories**, even for distinct projects that share content
- **Local store contents can be kept manageable in size** by purging historic content that is no longer actively used. The full set of historic contents can be stored in a few locations and accesses as need arises.

## A small example

After some initial setup, using git-raw can be as simple as the following:

Here is a large file that I need to track in my Git repository

```
$ ls -lh
total 423264
-rw-r--r--  1 user  staff     6B 17 Nov 21:07 a-file.txt
-rw-r--r--  1 user  staff   207M 17 Nov 21:08 huge       # <-- a big clunky file
```

With git-raw's `add` command, I can move the content of the file to a local directory and replace the file with a symbolic link that is staged for committing:

```
$ git raw add huge
$ ls -lh
total 16
-rw-r--r--  1 user  staff     6B 17 Nov 21:07 a-file.txt
lrwxr-xr-x  1 user  staff    66B 17 Nov 21:09 huge -> .git/git-raw/index/e2/e28a574342a066a2431ec4520ef6a7648c12ab52/raw
$ git status
On branch master
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

        new file:   huge

```

Next, the link is committed into Git:

```
$ git commit -m 'add huge file'
[master 58d9bb8] add huge file
 1 file changed, 1 insertion(+)
 create mode 120000 huge
```

## Latest release

git-raw is currently in pre-alpha. Testing is scheduled to begin shortly.

## Dependencies

The plug-in is written in Python version 3. Testing will determine the latest version of Python required.

## Installation

To use the latest development version, clone the repository somewhere and add its location to your `PATH` environment variable. That is all you need to do to get access to a new Git command called `raw`. Alternatively, copy the `git-raw` file to a directory that is already in your `PATH`

## Documentation

The goals and internal design of git-raw is described [here](docs/goals-and-design.md)

To get started, take a look at the [tutorial](/docs/tutorial.md)

Detailed help for individual git-raw commands can be viewed using git-raw's `help` command. See `git raw help` for more info:

```
$ git raw help
usage: git raw <command> [--help | -h] [<args>]

git-raw is a plug-in for git that simplifies the process of storing and
managing large and/or binary files that need to be kept in sync with a
source code repository.


Available commands:
    add         Add files to a content store and replace with a symlink
    add-store   Add a content store
    check       A dummy command used during development/debugging
    fix         Fix broken raw links
    help        Show help on git-raw subcommands
    init        Initialize git repository for use by git-raw
    ls          List raw-links in the working directory
    ls-stores   List configured content stores
    revert      Replace symlink with a copy of its content
    unlock      Replace symlink with a dummy ordinary file

Use 'git help <command>' to read about a specific subcommand
```

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

1. does not use symlinks, and therefore, requires an extra copy (one in the fat store and one in the working directory) of each large file that you want to work with, even if you only need read access to those large files. This is a big issue for me because I need to be able to handle really huge files (hundreds of GBs). There is no way I would want to have even a single unnecessary copy of one of those files.
2. does not (at least currently) support multiple different fat-stores
