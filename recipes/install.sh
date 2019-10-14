#!/bin/bash

NAME="John Doe"
EMAIL="johndoe@domain.tld"
SERVER_NAME=$HOSTNAME

# ------------------------------------------
# Helper functions to output text in colors.
# ------------------------------------------

msg() { echo $(tput bold)$(tput setaf $1)"$2" $(tput sgr0); }
msg-dark() { msg 0 "$1"; }
msg-error() { msg 1 "$1"; }
msg-success() { msg 2 "$1"; }
msg-warn() { msg 3 "$1"; }
msg-primary() { msg 4 "$1"; }
msg-info() { msg 6 "$1"; }
msg-light() { msg 7 "$1"; }
msg-default() { msg 9 "$1"; }

msg-primary "Installing dependencies"
apt update --fix-missing && \
apt install -y sudo \
  tzdata \
  rsync \
  python \
  python-setuptools \
  curl \
  openssh-server \
  ca-certificates
msg-success "Dependencies installed"
echo ""

# Add known hosts
msg-primary "Add known hosts (github, gitlab and bitbucket)"

# Create The Root SSH Directory If Necessary
if [ ! -d /root/.ssh ]
then
    mkdir -p /root/.ssh
    touch /root/.ssh/authorized_keys
    touch /root/.ssh/known_hosts
fi
ssh-keyscan -H github.com >> /root/.ssh/known_hosts
ssh-keyscan -H gitlab.com >> /root/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> /root/.ssh/known_hosts
msg-success "Known hosts added"
echo ""

# Configure Git Settings
msg-primary "Setting git global user name and email"
git config --global user.name $NAME
git config --global user.email $EMAIL
msg-success "Git global config set"
echo ""

# Install Backblaze B2 CLI.
msg-primary "Installing Backblaze B2-CLI"
git clone https://github.com/Backblaze/B2_Command_Line_Tool.git && cd /root/B2_Command_Line_Tool && python setup.py install
# Remove B2 CLI Setup files.
cd /root/ && rm -rf /root/B2_Command_Line_Tool
msg-success "Backblaze B2-CLI Installed"
msg-info "Please configure Backblaze B2-CLI with your bucket credentials from your account"
msg-info "Ex: b2 authorize-account [<applicationKeyId>] [<applicationKey>]"
echo ""

# Install auto-gitlab-backup
msg-primary "Installing Auto Gitlab Backup Tool (Backblaze B2 Supported)"
git clone https://github.com/sund/auto-gitlab-backup.git /root/auto-gitlab-backup
cp /root/auto-gitlab-backup/auto-gitlab-backup.conf.sample /root/auto-gitlab-backup/auto-gitlab-backup.conf
msg-success "Auto Gitlab backup tool installed: ~/auto-gitlab-backup"
msg-info "Please make sure to update config: ~/auto-gitlab-backup/auto-gitlab-backup.conf"
echo ""

# Setup Mail Server
msg-primary "Setting up mail server for Gitlab"
echo $SERVER_NAME > "/etc/mailname"
debconf-set-selections <<< "postfix postfix/mailname string $SERVER_NAME"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt install -y postfix mailutils
msg-success "Mail server installed"
echo ""

# Setup Gitlab-EE
msg-primary "Installing Gitlab EE"
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
apt install -y gitlab-ee
gitlab-ctl reconfigure
msg-success "Gitlab Installed"
msg-info "Please update gitlab config and reconfigure: gitlab-ctl reconfigure"
msg-info "Gitlab config file: /etc/gitlab/gitlab.rb"
echo ""

# Secure SSH
msg-primary "Securing SSH config"
msg-info "Creating existing config backup"
echo "cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config-backup"
cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config-backup
msg-success "/etc/ssh/sshd_config has been backed up"

msg-primary "Applying recommended SSH config"
sed -i \
    -e 's/.*PasswordAuthentication yes.*/PasswordAuthentication no/g' \
    -e 's/.*PermitEmptyPasswords .*/PermitEmptyPasswords no/g' \
    -e 's/.*ChallengeResponseAuthentication yes.*/ChallengeResponseAuthentication no/g' \
    -e 's/.*PubkeyAuthentication .*/PubkeyAuthentication yes/g' \
    -e 's/.*UsePAM yes.*/UsePAM no/g' \
    -e 's/.*IgnoreRhosts .*/IgnoreRhosts yes/g' \
    -e 's/.*HostbasedAuthentication .*/HostbasedAuthentication no/g' \
    /etc/ssh/sshd_config

CHECKAUTHMETHOD=$(grep 'AuthenticationMethods' /etc/ssh/sshd_config)

if [[ ! -z "$CHECKAUTHMETHOD" ]]; then
    echo "AuthenticationMethods publickey" >> /etc/ssh/sshd_config
fi

msg-success "Recommended config has been applied"

# Change SSH Port
msg-primary "Change SSH Port"
CURRENTSSHDPORT=$(echo ${SSH_CLIENT##* })

msg-info "Your current default SSH port is: $CURRENTSSHDPORT"
echo ""

read -ep "Enter the SSH port number you want to change to: " PORTNUM
sed -i 's/.*Port.*[0-9]$/Port '$PORTNUM'/gI' /etc/ssh/sshd_config

echo ""
msg-success "Post $PORTNUM configured in /etc/ssh/sshd_config"
grep "Port $PORTNUM" /etc/ssh/sshd_config
echo ""

msg-info "Restarting ssh"
ssh-keygen -A
service ssh restart
msg-success "SSH has been restarted"
msg-info "Please make sure to update your firewall with appropriate rules to accept/reject port changes"

# Setup crontab
msg-primary "Setting up crontab"
echo ""

set +H # disable history expansion
CRONTAB_ENTRIES=$(cat <<CONTENTS_HEREDOC
# m h  dom mon dow   command

# This will automatically initiate gitlab backup and then move to BackBlaze B2
5 5 * * * /root/auto-gitlab-backup/auto-gitlab-backup.sh

# Auto update Gitlab
5 4 24 * * apt update && apt -y install gitlab-ee  >> /var/log/gitlab-auto-update.log

# Renew Let's Encrypt Cert, Twice a day.
0 */12 * * * /opt/gitlab/bin/gitlab-ctl renew-le-certs > /dev/null
CONTENTS_HEREDOC
)
set -H # re-enable history expansion
echo "${CRONTAB_ENTRIES}" | crontab -
msg-success "Crontab installed"

# Setup ssh key
if [ ! -f /root/.ssh/id_ed25519.pub ]; then
  ssh-keygen -t ed25519 -o -a 100 -C "Gitlab@$SERVER_NAME"
fi
msg-primary '############################################'
msg-primary '###### Public SSH key of this machine ######'
msg-primary '############################################'
echo ''
cat /root/.ssh/id_ed25519.pub
echo ''
echo ''
msg-primary '############################################'
