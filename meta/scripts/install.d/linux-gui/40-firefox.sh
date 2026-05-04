#!/bin/bash
# Firefox — web browser
apt_package_current firefox && return 0
echo "  Installing/updating Firefox..."
apt_install firefox
