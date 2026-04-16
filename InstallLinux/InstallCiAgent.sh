#!/bin/bash

# DOC: https://docs.gitlab.com/runner/install/linux-repository/
echo "Adding official GitLab repository..."
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" -o script.deb.sh
sudo bash script.deb.sh

echo "Installing GitLab runner..."
sudo apt install -y gitlab-runner

# Runner registration postponed to instance creation
