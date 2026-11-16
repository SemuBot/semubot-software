#!/bin/bash
# Start the V2 drive stack from this checkout with the robot's ROS settings.
REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
source /opt/ros/jazzy/setup.bash
source "$REPO/ros2_ws/install/setup.bash"
[ -f "$HOME/.config/semubot/semubot.env" ] && set -a && source "$HOME/.config/semubot/semubot.env" && set +a
exec ros2 launch semubot_bringup ros2ctrl_microros.launch.py "serial_port:=${SEMUBOT_WHEELBASE_PORT:-/dev/semubot_wheelbase}"
