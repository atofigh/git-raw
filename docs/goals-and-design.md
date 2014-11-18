# Goal statement

The need for git-raw arose when I needed to deal with *very* large files, some containing hundreds of gigabytes of data. In such cases, it is simply not feasible to add data files directly to a Git repository. Not only would most Git operations become painfully slow, but I would also be wasting huge amounts of disk space by keeping multiple copies of these data files (at least two copies would be required, one in Git and one checked out in my working directory).

When I wrote git-raw, I wanted it to

- provide intuitive Git-flavored commands
- allow distributed multi-user work flows
- allow centralized multi-user work flows
- handle sharing of large files across multiple Git clones (even across separate projects) without redundant copies on disk
- track the history of large files in a Git repository similar to normal files (with some caveats, e.g., diffs)
- allow the user to manage disk space by cherry-picking the files he/she wants to have available locally at any one time
- assist in practical management of up/downloads of files between clones and remotes

# Foundations

Similar to Git, git-raw stores file content as a set of key/value pairs, with keys being the SHA-1 hash of each file's content. Within a Git repository, symlinks are used to point to file content and to keep track of version history.

## Content stores

git-raw can be customized to use multiple user-defined locations where file content can be stored. These locations may be directories on local hard drives, network drives, USB drives etc., and are called *content stores*. git-raw allows each user to define his/her own preferred set of local stores in which to store content and also allows users to share the same stores when they have access to the same filesystem. Even distinct repositories on the same local machine can share content stores thereby minimizing redundancies when the same large files are used in multiple different projects.

## Initialization

## The symlink structure

## Distribution of content
