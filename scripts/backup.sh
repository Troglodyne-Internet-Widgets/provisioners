#!/bin/bash

# This backup script runs as root on the remote.  As such, you'll want to authorize the key like so:
# command="rrsync -ro /holophrastic -ro /mail/mailnames -ro /var/www/vhosts -ro /var/lib/mysql -ro /var/spool/cron -ro /var/lib/psa",no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding [insert key here]

# Semaphore
[[ -f /root/backup_in_progress ]] && logger --stderr "Another backup in progress, exiting" && exit 1;

touch /root/backup_in_progress

REMOTE=$1
shift
BASEDIR=$1
shift
KEYFILE=$1
shift
TARGETS="$@"
DATE=$(date -I)
YESTERDAY=$(date -I --date '-1 day')
BACKUPDIR=/$BASEDIR/$REMOTE

# Snapshot the host.
logger --stderr "Backing up $REMOTE..."
logger --stderr "Using $KEYFILE against $REMOTE to backup $TARGETS into $BASEDIR"

for TARGET in $@; do

    LINKDIR="$BACKUPDIR/$YESTERDAY/$TARGET"
    mkdir -p $LINKDIR

    DESTDIR="$BACKUPDIR/$DATE/$TARGET"
    mkdir -p $DESTDIR

    logger --stderr "Copying $TARGET data to $DESTDIR with hardlinking to $LINKDIR..."
    logger --stderr "rsync -a --delete --fuzzy --fuzzy -e \"ssh -i $KEYFILE -p2222 -o 'StrictHostKeyChecking no'\" rsync://root@$REMOTE/$TARGET --link-dest $LINKDIR $DESTDIR"
    rsync -a --delete --fuzzy --fuzzy -e "ssh -i $KEYFILE -p2222 -o 'StrictHostKeyChecking no'" rsync://root@$REMOTE/$TARGET --link-dest $LINKDIR $DESTDIR
    CHANGED_FILES=$(find $DESTDIR -type f -links 1 | wc -l)
    logger --stderr "$CHANGED_FILES changed files in $TARGET"
    USAGE=$(df -h $BASEDIR | awk '{print $5}' | tail -n1)
    logger --stderr "Disk usage at $USAGE"

done

logger --stderr "Done."

rm /root/backup_in_progress
