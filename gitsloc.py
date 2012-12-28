#!/usr/bin/env python

from collections import defaultdict
import os
import re
import subprocess

name_and_line = re.compile(".*? \(([a-zA-Z. ]+) .*?\) (.*)")

class LineStats(object):
    __slots__ = ('code','comment','blank')

    def __init__(self, **kwargs):
        # Default values
        for attr in self.__slots__:
            setattr(self, attr, 0)
        # Construct with args?
        for (attr, v) in kwargs:
            setattr(self, attr, v)

    def __iadd__(self, rhs):
        for k in self.__slots__:
            v = getattr(self, k) + getattr(rhs, k)
            setattr(self, k, v)
        return self

    def __repr__(self):
        return ("LineStats(" + ",".join("%s=%s" % (k, getattr(self,k))
                for k in self.__slots__) + ")")

def get_files(ref='HEAD'):
    files = subprocess.check_output(['git','ls-tree','-r',ref])

    by_ext = defaultdict(list)
    for line in files.split('\n'):
        path = line[53:]
        if not path:
            continue
        (base, ext) = os.path.splitext(path)
        by_ext[ext].append(path)

    return dict(by_ext)

def blame_contents(path):
    text = subprocess.check_output(['git','blame','--',path])
    ext = os.path.splitext(path)[1]

    results = defaultdict(LineStats)

    for line in text.split('\n'):
        result = name_and_line.match(line)
        if not result:
            continue
        (name,line) = result.groups()
        name = name.strip()
        line = line.strip()

        stats = results[name]
        if not line:
            stats.blank += 1
        elif ext in (".h", ".cpp", ".i"):
            if (line.startswith('//')
                    or line.startswith('/*')
                    or line.startswith('* ')):
                stats.comment += 1
            else:
                stats.code += 1
        elif ext == ".py":
            if line.startswith('#'):
                stats.comment += 1
            else:
                stats.code += 1
        else:
            stats.code += 1

    return results


if __name__ == '__main__':
    files = get_files()

    chosen_files = []
    for ext in ('.h','.c','.hpp','.hh','.cc','.cpp','.i','.py'):
        try:
            chosen_files.extend(files[ext])
        except KeyError as e:
            print "No files of type", e

    results = defaultdict(LineStats)
    for path in chosen_files:
        print "Blaming", path
        this_results = blame_contents(path)
        for (k,v) in this_results.iteritems():
            results[k] += v

    print "%30s %10s %10s %10s" % ("","CODE","COMMENT","BLANK")
    totcode = 0
    totcomment = 0
    totblank = 0
    for k,v in results.iteritems():
        print "%30s %10d %10d %10d" % (k,v.code, v.comment, v.blank)
        totcode    += v.code
        totcomment += v.comment
        totblank   += v.blank
    print "%30s %10d %10d %10d" % ("TOTAL",totcode, totcomment, totblank)


