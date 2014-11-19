# Tutorial

## Installation

You will need to have Python 3 installed on your system. At the moment, git-raw assumes that Python 3 can be run using the command `python3`.

Clone the git-raw repository somewhere on your system and add the git-raw directory to your system's PATH environment variable. This is all you need to do to get access to a new git command called `raw`.

## Getting help

The git-raw plug-in uses a subcommand structure similar to Git itself. To list all the available git-raw commands along with a short description of each, type the following on the command-line:

```
$ git raw help
```

Detailed help for each subcommand is available via the `help` command, for example:

```
$ git raw help add
```

## Initializing a Git repository for use by git-raw

To use git-raw to manage binary/large files in your Git repository, you need to initialize you Git repository with the 'init' command and configure content stores where file content will be stored. Inside the working directory of the Git repository in which you want to track large files do:

```
$ git raw init
Initialized Git repository for git-raw
NOTE: no stores have been configured!
      use 'git raw add-store' to add content stores
$ git raw add-store <store-name> <dir>
```

where `<store-name>` should be a short name you will use to refer to the content store in `<dir>` in future commands. More stores can be added as required.

## Adding files to content stores

The main commands for managing binary files in your Git repository are:

- add
- unlock
- revert
- fix

### add

The 'add' command will move the content of files to a content store and replace the files with symlinks that are then added to Git's staging area for committing. The permissons on contents in a store are kept read-only. The symlinks that replaced the actual files are called raw-links:

```
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
```

### unlock

If you need to replace the content of a raw-link, first use the 'unlock' command to replace the raw-link with a writeable dummy file that can be overwritten. Once the content has been replaced, add the new content using `git raw add` and commit. Both the old and the new content will be saved in the content store and can be made available when they are checked out as part of the commits:

```
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
```

Note how the symlink changed when the content of 'big-file' changed.

If you want to undo the affect of the 'unlock' command, use Git's 'checkout' command to checkout the raw-link previously committed to Git.

### revert

Sometimes, you may want to append content to the raw files or change the raw file content directly instead of overwriting it. Since the contents of files handled by git-raw are kept read-only, you need a way to revert the raw-link back to an ordinary file. You can use the 'revert' command for this. 'revert' will replace the raw-link with a copy of the content from a store:

```
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
```

Note that most of the time, the 'unlock' command is preferable since there will be no copying involved. Use the 'revert' command if you really need to be able to both read and write to the file at the same time.

### fix

The fix command is used to fix broken raw-links. Raw-links can break for many reasons including:

- A store is no longer available
- The raw-link was moved to a different directory
- You have just cloned a repository that uses git-raw


You can run the 'fix' command on the whole repository or only a part of it. It will do its best to find the right content in any of the stores that have been configured.
The 'fix' command is especially useful after cloning a repository that is using git-raw to manage content. After cloning a repository, you should first run the command `git raw init` to initialized the repository for use by git-raw. Then use the 'add-stores' command to set up content stores. And finally, you should run `git raw fix` at the top level directory to point all the symlinks to their actual contents.

As an example, assume that we have just cloned the repository that we have been working on in the above examples. This is what the working directory looks like:

```
$ ls -l
total 16
-rw-r--r--  1 user  staff   6 18 Nov 21:23 a-file.txt
lrwxr-xr-x  1 user  staff  66 18 Nov 21:23 big-file -> .git/git-raw/index/8b/8b787bd9293c8b962c7a637a9fdbf627fe68610e/raw
$ cat big-file
cat: big-file: No such file or directory
```

The raw-link is broken. To make the content available again, we first need to initialize the repository for use with git-raw and configure a content store that contains the content we need:

```
$ git raw init
Initialized Git repository for git-raw
NOTE: no stores have been configured!
      use 'git raw add-store' to add content stores
$ git raw add-store s1 ../local-store-1/
$ git raw fix
$ ls -l
total 16
-rw-r--r--  1 user  staff   6 18 Nov 21:23 a-file.txt
lrwxr-xr-x  1 user  staff  66 18 Nov 21:23 big-file -> .git/git-raw/index/8b/8b787bd9293c8b962c7a637a9fdbf627fe68610e/raw
```

At this point nothing has changed in the working directory; the raw-link and its target are the same. But the link now points (magically) to the correct content:

```
$ cat big-file
new content
```

## Other useful commands

### ls-stores

`git raw ls-stores` will list all configured stores. If you have multiple stores configured, one of them can be set to the default store for use by the `add` command. That store will be highlighed in the list with an asterisk: `*`. You can change the default add store with the `add-store` command. See `git raw help add-store` for information on how to do that.

### ls

The `ls` command is used to list raw-links. With the `--broken` flag, `ls` will list only broken raw-links that need to be `fix`ed. See `git raw help ls` for details.

## Managing content stores

At the moment, git-raw does not have builtin commands for managing content stores. These will (hopefully) be added in the future.

In the meantime, the easiest solution is to keep content stores synced across different machines using `rsync`. To copy the missing contents from one store to another, you could do

```
$ rsync -r --ignore-existing --perm --chmod=Fa-w,Dg+w <src-store>/ <dest-store>
```

The `<src-store>` and `<dest-store>` are paths to content stores, with possibly one of them being on a remote maching. Please note that the slash after `<src-store>/` is very important. As a concrete example, assume that you have a content store locally on your machine at `/my/local/store-1` and you want to copy over content to a store `/central/stores/store-8` that resides on a remote machine called 'server', on which your username is 'user'. You could then do:

```
rsync -r --ignore-existing --perm --chmod=Fa-w /my/local/store-1/ user@server:/central/stores/store-8
```

To get all the missing content from the remote machine, reverse the order of the local store and the store on the server, but don't forget the `/` after the source!

```
rsync -r --ignore-existing --perm --chmod=Fa-w user@server:/central/stores/store-8/ /my/local/store-1
```

### A note on store permissions

The above rsync commands will copy contents between stores and remove any write permissions on the files. Often, it is also practical to set the group write permissions on the directories in the store so that other users can add content. One way to achieve that is to change the `--chmod=Fa-w` option in the above commands to `--chmod=Fa-w,Dg+w`. For more configuration options, see the rsync manual.
