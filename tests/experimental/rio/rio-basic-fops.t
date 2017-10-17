#!/bin/bash

. $(dirname $0)/../../include.rc
. $(dirname $0)/../../volume.rc

cleanup;

TEST glusterd
TEST pidof glusterd

# This is currently static 5 brick (2MDS 3DS configuration)
brick_list=$(echo $H0:$B0/${V0}{1..5})

# The helper script creates the volume as well, at present
$PYTHON $(dirname $0)/../../../xlators/experimental/rio/scripts/rio-volfile-generator/GlusterCreateVolume.py $V0 2 3 "$brick_list" --force

EXPECT "$V0" volinfo_field $V0 'Volume Name'
EXPECT 'Created' volinfo_field $V0 'Status'

cd /var/lib/glusterd/vols/$V0
for i in $(ls *.gen); do j=$(echo $i | sed 's/\(.gen\)//'); mv -f $i $j; done
cd -

TEST $CLI volume start $V0
EXPECT 'Started' volinfo_field $V0 'Status'

## Mount FUSE
TEST $GFS -s $H0 --volfile-id $V0 $M0


#TODO: The fops are failing with EINVAL as conf->fops are not set at client xlator (i.e., client handshake
#is not complete yet). It gets fixed once that is taken care. For now sleep for 5 secs
sleep 5

# empty file creations
TEST touch $M0/f{0..300}

# stat() check
TEST stat $M0/f{0..300}

# Directory creations upto three levels
TEST mkdir $M0/dir{0..50}
TEST mkdir $M0/dir0/dir{0..50}
TEST mkdir $M0/dir0/dir0/dir{0..50}
TEST touch $M0/dir0/file{0..50}
TEST touch $M0/dir0/dir0/file{0..50}

# NOTE: no umoun test as there's a segfault due to missing statfs() implementation
#       in posix, v2.
# TEST umount $M0

cleanup;
