#!/bin/sh

src_dir=$HOME/_code/advantg

regression_dir=${src_dir}/python/tests/data/regression

cd python/tests/regression_run || exit !?
rm -R *00* 2>/dev/null
for d in *
do
  for f in ${d}/*/*.json ${d}/*.json
  do
    cp $f ${regression_dir}/$f
  done
done

