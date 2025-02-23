#!/usr/bin/env sh
# Script to validate the adherence to the FHS and our standards for a package

set -euo pipefail

RETVAL=0

check_dir() {
    local ROOTDIR="$1"
    local ALLOWED_DIRS="$2"

    for DIR in "$ROOTDIR"/*; do
        # Empty directory, no matches.
        [ "$DIR" = "$ROOTDIR/*" ] && break
        local RELATIVE_DIR=$(basename "$DIR")

        if ! echo "${ALLOWED_DIRS}" | grep -wq "${RELATIVE_DIR}"; then
            [ -d "${DIR}" ] && echo "Package validator: ${DIR} is not an allowed directory" || echo "Package validator: ${DIR} is not an allowed file"
            RETVAL=1
        fi
    done
}

ROOTDIR="${1:-/rootfs}"

# Test for extra files/directories
# bin, lib and other directories moved to /usr are not allowed
ALLOWED_DIRS="usr etc dev proc sys opt run var root tmp home"
check_dir "$ROOTDIR" "$ALLOWED_DIRS"
echo "Validated /"

# No need for this test in pkgs which only have files under /etc for example
[ ! -d "${ROOTDIR}/usr" ] && exit $RETVAL

# Test for extra files/directories in /usr
# lib64 and sbin are not allowed
ALLOWED_USR_DIRS="bin lib share libexec include etc local src var"
check_dir "$ROOTDIR/usr" "$ALLOWED_USR_DIRS"

# Do not install man pages and locale info for optimal image size
for DIR in $ROOTDIR/usr/man $ROOTDIR/usr/share/man $ROOTDIR/usr/local/man $ROOTDIR/usr/local/share/man \
           $ROOTDIR/usr/share/info $ROOTDIR/usr/share/doc $ROOTDIR/usr/share/locale $ROOTDIR/usr/lib/locale; do
    [ -e ${DIR} ] && echo "Package validator: ${DIR} is not an allowed directory (man/info/locale)" && RETVAL=1
done

echo "Validated /usr"
exit $RETVAL
