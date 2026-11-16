#!/bin/bash
# Run a command with ROS 2 Jazzy, this checkout's workspace and ~/.config/semubot/semubot.env loaded.
REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
source /opt/ros/jazzy/setup.bash
source "$REPO/ros2_ws/install/setup.bash"
[ -f "$HOME/.config/semubot/semubot.env" ] && set -a && source "$HOME/.config/semubot/semubot.env" && set +a
exec "$@"
