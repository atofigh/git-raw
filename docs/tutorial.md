# Tutorial

## Installation

Clone the git-raw repository somewhere on your system and add the git-raw directory to your system's PATH environment variable. This is all you need to do get access to a new git command called `raw`.

## Getting help

The git-raw plugin uses a subcommand structure similar to Git itself. To list all the available git-raw commands along with a short description of each, type the following on the command-line:

```
$ git raw help
```

The help for each subcommand is available via the `help` command, for example:

```
$ git raw help add
```

## Initializing a Git repository for use by git-raw

To use git raw to manage binary/large files in your Git repository, you need to initialize you Git repository with the 'init' command and configure content stores where file content will be stored. Inside the working directory of an existing git repository do:

    $ git raw init
    $ git raw add-store <store-name> <dir>

where `<store-name>` should be a short name you will use to refer to the content store in `<dir>` in future commands. More stores can be added as required.

## Adding files to content stores

The main commands for managing binary files in your Git repository are:

- add
- unlock
- revert
- fix

### add

The 'add' command will move the content of files to a content store and replace the files with symlinks that are then added to Git's staging area for committing. The permissons on contents in a store are kept read-only. The symlinks that replaced the actual files are called raw-links.

    $ ls -l
    total 423264
    -rw-r--r--  1 user  staff          6 13 Nov 12:24 a-file.txt
    -rw-r--r--  1 user  staff  216707072 13 Nov 12:23 big-file
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
    -rw-r--r--  1 user  staff   6 13 Nov 12:24 a-file.txt
    lrwxr-xr-x  1 user  staff  66 13 Nov 12:25 big-file -> .git/git-raw/index/e2/e28a574342a066a2431ec4520ef6a7648c12ab52/raw
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

### unlock

If you need to replace the content of a raw-link, use the 'unlock' command to replace the raw-link with a writeable dummy file that can be overwritten. Once the content has been replaced, add the new content using `git raw add`. Both the old and the new content will be saved in a configured store and are made available when they are checked out as part of the commits.

    $ git raw unlock big-file
    $ ls -l
    total 16
    -rw-r--r--  1 user  staff   6 13 Nov 12:24 a-file.txt
    -rw-r--r--  1 user  staff  96 13 Nov 15:01 big-file
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
    -rw-r--r--  1 user  staff   6 13 Nov 12:24 a-file.txt
    lrwxr-xr-x  1 user  staff  66 13 Nov 15:02 big-file ->
    .git/git-raw/index/8b/8b787bd9293c8b962c7a637a9fd
    bf627fe68610e/raw
    $

Note how the symlink changed when the content of 'big-file' changed.

If you want to undo the affect of the 'unlock' command, use Git's 'checkout' command to checkout the raw-link previously committed to Git.

### revert

Sometimes, you may want to append content to the raw files or change the raw file content directly instead of overwriting it. Since the contents of files handled by git-raw are kept read-only, you need a way to revert the raw-link back to an ordinary file. You can use the 'revert' command for this:

    $ ls -l
    total 16
    -rw-r--r--  1 user  staff   6 13 Nov 12:24 a-file.txt
    lrwxr-xr-x  1 user  staff  66 13 Nov 15:02 big-file ->
    .git/git-raw/index/8b/8b787bd9293c8b962c7a637a9fd
    bf627fe68610e/raw
    $ git raw revert big-file
    $ ls -l
    total 16
    -rw-r--r--  1 user  staff   6 13 Nov 12:24 a-file.txt
    -rw-r--r--  1 user  staff  12 13 Nov 15:02 big-file
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

### fix

The fix command is used whenever a raw-link has been broken, either because the store location changed or because the symlink was moved to a different directory. You can run the 'fix' command on the whole repository or only a part of it. It will do its best to fix the symlinks to point to content in the configured content stores.

The 'fix' command is especially useful after cloning a repository that is using git-raw to manage content. After cloning a repository, you should first run the command `git raw init` to initialized the repository for use by git-raw. Then use the 'add-stores' command to set up content stores. And finally, you should run `git raw fix` at the top level directory to point all the symlinks to their actual contents.
