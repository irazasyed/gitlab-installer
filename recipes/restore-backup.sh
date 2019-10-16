#!/bin/bash

# Set these vars
REMOTE_USER=root
REMOTE_HOST=YOUR_REMOTE_HOST_WITH_GITLAB_BACKUP
BACKUP_NAME=1571029775_2019_10_14_12.3.5-ee
# Enable if you want to restore from B2 Bucket
# B2_BUCKET_NAME=gitlab-backups

# --------------------------------------------------------------
# Don't edit below this line unless you know what you're doing!
# --------------------------------------------------------------
date

if [ "$(id -u)" != "0" ]; then
  echo "Must be run as root, directly or with sudo"
  exit 1
fi

if [[ -n "$B2_BUCKET_NAME" ]]; then
    # Restore from Backblaze B2 (Requires pre-configuration done)
    b2 sync --replaceNewer "b2://$B2_BUCKET_NAME/backups/${BACKUP_NAME}_gitlab_backup.tar" /var/opt/gitlab/backups/
else
    # Restore from remote host using rsync
    rsync -avHzPe ssh $REMOTE_USER@$REMOTE_HOST:"/var/opt/gitlab/backups/${BACKUP_NAME}_gitlab_backup.tar" /var/opt/gitlab/backups/
fi

chown git.git /var/opt/gitlab/backups/*.tar

gitlab-ctl stop unicorn
gitlab-ctl stop sidekiq
gitlab-backup restore BACKUP=$BACKUP_NAME
gitlab-ctl reconfigure
gitlab-ctl restart
gitlab-rake gitlab:check SANITIZE=true
