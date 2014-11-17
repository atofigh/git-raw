#!/usr/bin/env python3

# Skeleton for a pre-commit hook that parses the output from
# 'git status --porcelain'.

import sys
import os
import subprocess
from subprocess import check_output, CalledProcessError
import time
from collections import namedtuple

def git_status():
    return check_output(["git", "status", "--porcelain", "-z", "--untracked-files=no"],
                        universal_newlines=True)

def git_attribute(fname, cached = False):
    command = ["git", "check-attr", "-z", "raw"]
    command += ["--cached", fname] if cached else [fname]
    output = check_output(command, universal_newlines=True)
    return output.split("\0")[2]

class PathStatus:
    def __init__(self, **kwargs):
        self.__dict__ = dict(kwargs)

    def __str__(self):
        ret = self.path + ": '" + self.status_cache + self.status_wd + "'"
        ret += "  raw_cache: " + self.raw_cache
        ret += "  raw_wd: " + self.raw_wd
        if (self.status_cache == "R"):
            ret += "  old_path: " + self.old_path
            ret += "  old_raw_wd: " + self.old_raw_wd
            ret += "  old_raw_cache: " + self.old_raw_cache
        return ret

def parse_status(status):
    status = status.rstrip('\0')
    elems = status.split('\0')
    i = 0
    while i < len(elems):
        path = elems[i][3:]
        ret = PathStatus(status_cache=elems[i][0],
                         status_wd=elems[i][1],
                         path=path,
                         raw_wd=git_attribute(path, False),
                         raw_cache=git_attribute(path, True))
        if (ret.status_cache == "R"):
            i += 1
            ret.old_path=elems[i]
            ret.old_raw_wd=git_attribute(elems[i], False)
            ret.old_raw_cache=git_attribute(elems[i], True)


        i += 1
        yield ret

paths = [x for x in parse_status(git_status()) if x.status_cache != ' ']

for x in paths:
    print(x)

exit(1)
