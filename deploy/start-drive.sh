#!/bin/bash
# Start the V2 drive stack on the Pi.
exec "$(dirname "$(readlink -f "$0")")/run.sh" bash -c 'exec ros2 launch semubot_bringup ros2ctrl_microros.launch.py "serial_port:=${SEMUBOT_WHEELBASE_PORT:-/dev/semubot_wheelbase}"'
