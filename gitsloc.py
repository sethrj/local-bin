#!/usr/bin/env python

from collections import defaultdict
import os
import re
import subprocess

name_and_line = re.compile(".*? \(([a-zA-Z. ]+) .*?\) (.*)")

# Class that stores statistics. Using += on this class accumulates the stats.
class LineStats(object):
    __slots__ = ('name','code','comment','blank')
    _numeric_fields = __slots__[1:]

    def __init__(self, **kwargs):
        # Default values
        for attr in LineStats._numeric_fields:
            setattr(self, attr, 0)
        # Construct with args?
        for (attr, v) in kwargs.iteritems():
            setattr(self, attr, v)

    def __iadd__(self, rhs):
        self.name = rhs.name
        for k in LineStats._numeric_fields:
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

    results = dict()

    for line in text.split('\n'):
        result = name_and_line.match(line)
        if not result:
            continue
        (name,line) = result.groups()
        line = line.strip()

        k = name.strip().split()[-1] # Key is last name

        try:
            stats = results[k]
        except KeyError:
            # New entry
            stats = results[k] = LineStats(name=name.strip())

        if not line:
            stats.blank += 1
        elif ext in (".h", ".cpp", '.hh', '.cc', ".i"):
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
    for ext in ('.h','.c','.hpp','.hh','.cc','.cpp', '.i','.py',
            #'.sh', '.cmake', '.txt',
            ):
        try:
            chosen_files.extend(files[ext])
        except KeyError as e:
            print "No files of type", e

    # Print output every so often
    stride_num = max(50, len(chosen_files) / 20)

    results = defaultdict(LineStats)
    for (i, path) in enumerate(chosen_files):
        if not i % stride_num:
            print "Blaming file %4d of %4d : %s" % (i, len(chosen_files), path)
        # Do git blame on the file
        this_results = blame_contents(path)
        for (k,v) in this_results.iteritems():
            # Update existing stats
            results[k] += v

    print "%30s %10s %10s %10s %4s" % ("",
            "CODE","COMMENT","BLANK","COMMENT/CODE")
    totcode = 0
    totcomment = 0
    totblank = 0

    # Sort keys based on increasing amount of code lines
    sorted_keys = sorted(results, key=lambda k: results[k].code)

    # Print results
    for k in reversed(sorted_keys):
        v = results[k]
        comment_fraction = float(v.comment) / v.code
        print "%30s %10d %10d %10d %4.2f" % (v.name, v.code, v.comment,
                v.blank, comment_fraction)
        totcode    += v.code
        totcomment += v.comment
        totblank   += v.blank
    print "%30s %10d %10d %10d" % ("TOTAL", totcode, totcomment, totblank)


