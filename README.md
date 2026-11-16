# semubot-software

All SemuBot software components as git submodules, pinned to known commits. Software counterpart of [semubot-mechanics](https://github.com/SemuBot/semubot-mechanics) and [semubot-electronics](https://github.com/SemuBot/semubot-electronics). The root is a colcon workspace.

```
semubot-software/
├── ros2_ws/src/                    ROS 2 packages (Jazzy); build from ros2_ws
│   ├── semubot_bringup             launch files: ros2_control + micro-ROS wheelbase stack, joystick      [V2: Raspberry Pi 5]
│   ├── semubot_ros_control         ros2_control hardware interface + velocity controller, 3-wheel omni   [V2: Raspberry Pi 5]
│   ├── semubot_driver              serial driver for the STM32 wheelbase firmware                        [V2: Raspberry Pi 5]
│   ├── semubot_raspberry_bringup   GPIO motor driver, e-stop, joystick, battery monitor, systemd         [V1: Raspberry Pi 5, legacy]
│   ├── semubot_description         URDF/xacro model (V1 + V2 wheelbase), meshes                          [any]
│   ├── semubot_arm_description     arm + hand xacro macro, included by semubot_description               [any]
│   ├── semubot_gazebo              Gazebo worlds and launch                                              [dev PC]
│   ├── semubot_brain               speech: VAD, ASR, LLM (local or cloud), Estonian TTS                  [NUC]
│   ├── semubot_eyes                animated face driven by the brain's state                             [NUC]
│   ├── respeaker_ros               ReSpeaker 4-mic array: audio + direction of arrival                   [NUC]
│   ├── micro_ros_agent             micro-ROS agent (eProsima), bridges the STM32 board to ROS 2          [V2: Raspberry Pi 5]
│   └── micro_ros_msgs              messages the agent needs                                               [V2: Raspberry Pi 5]
├── apps/                           non-ROS apps
│   ├── semubot_webapp              touchscreen web control via rosbridge (FastAPI, Docker)               [NUC]
│   └── semubot_chest_display       chest touch screen: menus, speech settings, battery (Tkinter+rclpy)   [NUC]
├── firmware/                       microcontroller firmware
│   └── wheelbase                   STM32F303 wheelbase: FreeRTOS, micro-ROS, DRV8353 (branch fw/ros2ctrl-microros) [STM32 board]
├── deploy/                         install, update and roll back on a robot computer: units, udev rule, env
└── docs/
    └── operating-instructions      how to start, connect to and operate the robots: machines, IPs, services
```

V2 is the robot this workspace targets: Raspberry Pi 5 runs the ROS nodes, the STM32 board drives the motors, the NUC runs speech. V1 (old wheelbase driven from the Pi's GPIO) stays pinned but is not developed further.

Start here:

```bash
git clone --recurse-submodules https://github.com/SemuBot/semubot-software.git
cd semubot-software
```

With Docker (also what CI runs; the `firmware` target builds the STM32 image with the Makefile from `semubot-firmware`):

```bash
docker build --target build -t semubot-software .
docker build --target firmware -t semubot-software:firmware .
```

Natively on Ubuntu 24.04 with ROS 2 Jazzy:

```bash
cd ros2_ws
source /opt/ros/jazzy/setup.bash
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
```

VS Code with the Dev Containers extension opens the same image through `.devcontainer/`.

On a robot computer (Ubuntu 24.04, ROS 2 Jazzy, user `semubot`), after the clone:

```bash
deploy/semubot install            # build, user units, udev rule, start at boot
deploy/semubot update [REF]       # switch to a commit or tag (default origin/main) and reinstall
deploy/semubot rollback           # back to the commit the last update replaced
```

Settings live in `~/.config/semubot/semubot.env`; logs: `journalctl --user -u semubot-drive -f`.

Move a pin after a component repo changed:

```bash
git submodule update --remote ros2_ws/src/<pkg> && git add ros2_ws/src/<pkg> && git commit
```
