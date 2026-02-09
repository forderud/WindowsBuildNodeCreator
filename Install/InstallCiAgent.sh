#!/bin/bash
# NOTICE: The script expects $BUILD_SERVER_URL and $BUILDER_SECRET to have already been set

# create workspace relative to user home folder
mkdir Dev
cd Dev

# DOC: https://docs.gitlab.com/runner/install/linux-repository/
echo "Adding official GitLab repository..."
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" -o script.deb.sh
sudo bash script.deb.sh

echo "Installing GitLab runner..."
sudo apt install -y gitlab-runner

echo "Registering GitLab runner..."
sudo gitlab-runner register \
  --non-interactive \
  --url $BUILD_SERVER_URL \
  --token $BUILDER_SECRET \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "docker-runner"
