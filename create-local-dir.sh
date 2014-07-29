#! /bin/bash
# Link multiple subdirectories' contents into a single 'opt' folder

subdirs="bin doc etc include lib lib64 libexec man modules python share"
destdir=$(pwd)

echo "Creating dirs in: ${destdir}"
echo "Prefix dir: ${prefix_base}"
cd ${destdir}
mkdir ${subdirs} 2>/dev/null

for d in \
  gcc         hdf5           numpy    silo   swig \
  Exnihilo  gcc-prereq  openmpi  python  lava advantg
do
  echo $d
  for subd in ${subdirs}
  do
    if [ -d ${prefix_base}/$d/$subd ]; then
      ln -s $prefix_base/$d/$subd/* ${destdir}/$subd/
    fi
  done
done

# Remove empty directories
rmdir ${subdirs} 2>/dev/null
