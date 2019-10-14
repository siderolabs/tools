#!/toolchain/bin/bash

set -eoux pipefail

mv -v /toolchain/bin/{ld,ld-old}
mv -v /toolchain/$(gcc -dumpmachine)/bin/{ld,ld-old}
mv -v /toolchain/bin/{ld-new,ld}
ln -sv /toolchain/bin/ld /toolchain/$(gcc -dumpmachine)/bin/ld

gcc -dumpspecs | sed -e "s@/toolchain@@g" \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /include@}' > `dirname $(gcc --print-libgcc-file-name)`/specs

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
grep -o '/lib.*/crt[1in].*succeeded' dummy.log
grep -B1 '^ /include' dummy.log
grep 'SEARCH.*/lib' dummy.log | sed 's|; |\n|g'
grep "/lib/libc.so succeeded" dummy.log
rm -v dummy.c a.out dummy.log
