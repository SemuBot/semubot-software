#!/bin/bash
# Run a command with ROS 2 Jazzy, this checkout's workspace and ~/.config/semubot/semubot.env loaded.
REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
source /opt/ros/jazzy/setup.bash
source "$REPO/ros2_ws/install/setup.bash"
[ -f "$HOME/.config/semubot/semubot.env" ] && set -a && source "$HOME/.config/semubot/semubot.env" && set +a
# The robot profile for the apps that are not ROS nodes; launch files resolve it themselves
export SEMUBOT_PROFILE_FILE=${SEMUBOT_PROFILE_FILE:-$REPO/ros2_ws/install/semubot_bringup/share/semubot_bringup/config/profiles/${SEMUBOT_PROFILE:-v2}.yaml}
exec "$@"
