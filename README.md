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

Similar to Git, git-raw stores files as a set of key/value pairs, with keys being the SHA-1 hash of each file's content. Within a Git repository, symlinks are used to point to file content and to keep track of version history.

### Content stores

git-raw can be customized to use multiple user-defined locations for the storage of files. These locations may be directories on local hard drives, network drives, USB drives etc., and are called content stores. git-raw allows each user to define his/her own preferred set of stores in which to store content. Distinct repositories on the same local machine can share content stores thereby minimize redundancies in cases when different repositories have some large files in common.

## Getting started

### Installation

Clone the git-raw repository somewhere on your system and add the git-raw directory to your system's PATH environment variable. This is all you need to do get access to a new git command called 'raw'.

### Getting help

The git-raw plugin uses a subcommand structure similar to Git itself. To list all the available git-raw commands along with a short description of each do

    $ git raw help

The help for each subcommand is available via the `help` command, for example:

    $ git raw help add

### Initializing a Git repository for use by git-raw

To use git raw to manage binary/large files in your Git repository, you need to initialize you Git repository with the 'init' command and configure content stores where file content will be stored. Inside the working directory of an existing git repository do:

    $ git raw init
    $ git raw add-store <store-name> <dir>

where `<store-name>` should be a short name you will use to refer to the content store in `<dir>` in future commands. More stores can be added as required.

### Adding files to content stores

The main commands for managing binary files in your git repository are:

- add
- unlock
- revert
- fix

#### add

The 'add' command will move the content of files to a content store and replace the files with symlinks that are then added to git's staging area for committing. The permissons on contents in a store are kept read-only. The symlinks that replaced the actual files are called raw-links.

    $ ls -l
    total 423264
    -rw-r--r--  1 alix  staff          6 13 Nov 12:24 a-file.txt
    -rw-r--r--  1 alix  staff  216707072 13 Nov 12:23 big-file
    $ git status
    On branch master
    Untracked files:
      (use "git add <file>..." to include in what will be committed)

            big-file

    nothing added to commit but untracked files present (use "git add" to
    track)
    $ git raw add big-file
    $ ls -l
    total 16
    -rw-r--r--  1 alix  staff   6 13 Nov 12:24 a-file.txt
    lrwxr-xr-x  1 alix  staff  66 13 Nov 12:25 big-file -> .git/git-raw/index/e2/e28a574342a066a2431ec4520ef6a7648c12ab52/raw
    $ git status
    On branch master
    Changes to be committed:
      (use "git reset HEAD <file>..." to unstage)

            new file:   big-file

    $ git commit -m 'added huge file'
    [master c4c9572] added huge file
    1 file changed, 1 insertion(+)
    create mode 120000 big-file
    $

#### unlock

If you need to replace the content of a raw-link, use the 'unlock' command to replace the raw-link with a writeable dummy file that can be overwritten. Once the content has been replaced, add the new content using `git raw add`. Both the old and the new content will be saved in a configured store and are made available when they are checked out as part of the commits.

    $ git raw unlock big-file
    $ ls -l
    total 16
    -rw-r--r--  1 alix  staff   6 13 Nov 12:24 a-file.txt
    -rw-r--r--  1 alix  staff  96 13 Nov 15:01 big-file
    $ cat big-file
    $git raw dummy$
    big-file -->
    .git/git-raw/index/e2/e28a574342a066a2431ec4520ef6a7648c12ab52/raw
    $ echo "new content" > big-file
    $ git raw add big-file
    $ git status
    On branch master
    Changes to be committed:
      (use "git reset HEAD <file>..." to unstage)

            modified:   big-file

    $ git commit -m 'changed big-file'
    [master b45d0f1] changed big-file
     1 file changed, 1 insertion(+), 1 deletion(-)
    $ ls -l
    total 16
    -rw-r--r--  1 alix  staff   6 13 Nov 12:24 a-file.txt
    lrwxr-xr-x  1 alix  staff  66 13 Nov 15:02 big-file ->
    .git/git-raw/index/8b/8b787bd9293c8b962c7a637a9fd
    bf627fe68610e/raw
    $

Note how the symlink changed when the content of 'big-file' changed.

If you want to undo the affect of the 'unlock' command, use Git's 'checkout' command to checkout the raw-link previously committed to Git.

#### revert

Sometimes, you may want to append content to the raw files or change the raw file content directly instead of overwriting it. Since the contents of files handled by git-raw are kept read-only, you need a way to revert the raw-link back to an ordinary file. You can use the 'revert' command for this:

    $ ls -l
    total 16
    -rw-r--r--  1 alix  staff   6 13 Nov 12:24 a-file.txt
    lrwxr-xr-x  1 alix  staff  66 13 Nov 15:02 big-file ->
    .git/git-raw/index/8b/8b787bd9293c8b962c7a637a9fd
    bf627fe68610e/raw
    $ git raw revert big-file
    $ ls -l
    total 16
    -rw-r--r--  1 alix  staff   6 13 Nov 12:24 a-file.txt
    -rw-r--r--  1 alix  staff  12 13 Nov 15:02 big-file
    $ cat big-file
    new content
    $ git status
    On branch master
    Changes not staged for commit:
      (use "git add <file>..." to update what will be committed)
      (use "git checkout -- <file>..." to discard changes in working directory)

            typechange: big-file

    no changes added to commit (use "git add" and/or "git commit -a")
    $

Note that most of the time, the 'unlock' command is preferable since there will be no copying involved. Use the 'revert' command if you really need to be able to both read and write to the file at the same time.

#### fix

The fix command is used whenever a raw-link has been broken, either because the store location changed or because the symlink was moved to a different directory. You can run the 'fix' command on the whole repository or only a part of it. It will do its best to fix the symlinks to point to content in the configured content stores.

The 'fix' command is especially useful after cloning a repository that is using git-raw to manage content. After cloning a repository, you should first run the command `git raw init` to initialized the repository for use by git-raw. Then use the 'add-stores' command to set up content stores. And finally, you should run `git raw fix` at the top level directory to point all the symlinks to their actual contents.

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
