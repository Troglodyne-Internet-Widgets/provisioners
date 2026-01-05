#!/bin/bash

# This backup script runs as root on the remote.  As such, you'll want to authorize the key like so:
# command="rrsync -ro /holophrastic -ro /mail/mailnames -ro /var/www/vhosts -ro /var/lib/mysql -ro /var/spool/cron -ro /var/lib/psa",no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding [insert key here]

# Semaphore
touch /root/backup_in_progress

REMOTE=$1
shift
BASEDIR=$2
shift
KEYFILE=$3
shift
TARGETS="$@"
DATE=$(date -I)
YESTERDAY=$(date -I --date '-1 day')
BACKUPDIR=/$BASEDIR/$REMOTE

# Snapshot the host.
logger --stderr "Backing up $REMOTE..."
logger --stderr "Using $KEYFILE against $REMOTE to backup $TARGETS into $BASEDIR"

for TARGET IN $@; do

    LINKDIR="$BACKUPDIR/$YESTERDAY/$TARGET"
    mkdir -p $LINKDIR

    DESTDIR="$BACKUPDIR/$DATE/$TARGET"
    mkdir -p $DESTDIR

    logger --stderr "Copying $TARGET data to $DESTDIR with hardlinking to $LINKDIR..."
    rsync -a -e "ssh -i $KEYFILE -o 'StrictHostKeyChecking no'" rsync://root@$REMOTE/$TARGET --link-dest $LINKDIR $DESTDIR

done

logger --stderr "Done."

rm /root/backup_in_progress
