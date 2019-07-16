#!/usr/bin/env bash
set -e

echo "Install TigerVNC server"
#wget -qO- https://dl.bintray.com/tigervnc/stable/tigervnc-1.8.0.x86_64.tar.gz | tar xz --strip 1 -C /
apt-get install -y tigervnc-standalone-server
apt-get install -y libglu1-mesa libxi-dev libxmu-dev libglu1-mesa-dev mesa-utils
sed -i '/# Default: $localhost = "no";/a $localhost = "no";' /etc/vnc.conf
sed -i '/# Default: $SecurityTypes = "VncAuth"/a $SecurityTypes = "VncAuth";' /etc/vnc.conf
