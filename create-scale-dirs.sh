#!/bin/sh

scale_src=${source_base}/Scale

if [ ! -d ${scale_src} ]
then
  echo "Cloning Scale"
  hg clone https://fogbugz.ornl.gov/kiln/RepoAlias/scale/scale ${scale_src} \
    || exit $?
fi

cd ${HOME}/_code
for v in "" "-gpu" "-nights"
do
  echo "Creating Scale$v"
  mkdir Scale$v 2>/dev/null
  cd Scale$v
  if [ -n $v ]
  then
    for f in 'CMake*' cmake '*.cmake' packages src Polaris etc doc .hg
    do
      ln -s ${scale_src}/$f .
    done
  fi
  ln -s /usr/local/src/Trilinos .
  # User needs to now clone Exnihilo into Scale dir
  cd ../
  # Symlink cloned Exnihio
  ln -s Scale$v/Exnihilo Exnihilo$v
done
