# semubot-software

The software side of [SemuBot](https://github.com/SemuBot) in one place: every production ROS 2 package and app is a git submodule pinned to a known commit, so a checkout of this repository is a complete, reproducible software state of the robot. It is the software counterpart of [semubot-mechanics](https://github.com/SemuBot/semubot-mechanics) and [semubot-electronics](https://github.com/SemuBot/semubot-electronics).

The repository root is a colcon workspace: ROS 2 packages live under `src/`, non-ROS apps under `apps/` (no `package.xml`, so colcon ignores them).

## Components

| Component | Path | Branch | Kind | Runs on | Role | Depends on |
|---|---|---|---|---|---|---|
| [semubot_bringup](https://github.com/SemuBot/semubot_bringup) | `src/semubot_bringup` | `main` | ROS 2 package | wheelbase host of the STM32 robot (verify: NUC or laptop) | Launch files for the ros2_control + micro-ROS wheelbase stack: controller manager, micro-ROS agent, joystick teleop, robot state publisher | semubot_ros_control, semubot_description, `micro_ros_agent`, `joy`, `teleop_twist_joy`, `robot_state_publisher` |
| [semubot_brain](https://github.com/SemuBot/semubot_brain) | `src/semubot_brain` | `main` | ROS 2 package | NUC | Conversational brain: speech detection, speech recognition, LLM (local llama.cpp or cloud), Estonian TTS; owns the speech mode and is the only process that speaks | respeaker_ros (`audio`), whisper.cpp / llama.cpp / TTS servers (external, configured in `~/.config/semubot/brain.env`) |
| [semubot_description](https://github.com/SemuBot/semubot_description) | `src/semubot_description` | `jazzy` | ROS 2 package | any | URDF/xacro model of the robot (V1 and V2 wheelbase), meshes, RViz config | semubot_arm_description, `realsense2_description` |
| [semubot_arm_description](https://github.com/SemuBot/semubot_arm_description) | `src/semubot_arm_description` | `jazzy` | ROS 2 package | any | xacro macro for one arm and hand (6 arm joints + 5 finger joints), included by semubot_description | – |
| [semubot_driver](https://github.com/SemuBot/semubot_driver) | `src/semubot_driver` | `main` | ROS 2 package | wheelbase host of the STM32 robot | Host-side serial driver for the STM32 wheelbase firmware; serial backend for ros2_control | STM32 firmware (serial variants) |
| [semubot_eyes](https://github.com/SemuBot/semubot_eyes) | `src/semubot_eyes` | `main` | ROS 2 package | NUC (face screen) | Animated face: eyes follow the mic-array direction of arrival, mouth and expressions follow the brain's state | respeaker_ros, semubot_brain topics |
| [semubot_gazebo](https://github.com/SemuBot/semubot_gazebo) | `src/semubot_gazebo` | `jazzy` | ROS 2 package | development PC | Gazebo simulation worlds and launch files | semubot_description, Gazebo (gz) |
| [semubot_raspberry_bringup](https://github.com/SemuBot/semubot_raspberry_bringup) | `src/semubot_raspberry_bringup` | `main` | ROS 2 package | Raspberry Pi 5 (V2 robot) | GPIO motor driver with watchdog and emergency stop, joystick teleop, battery monitor (INA260); installed as a systemd service | `joy`, `teleop_twist_joy`, `lgpio` |
| [semubot_ros_control](https://github.com/SemuBot/semubot_ros_control) | `src/semubot_ros_control` | `jazzy` | ROS 2 package | wheelbase host of the STM32 robot | ros2_control hardware interface and velocity controller for the 3-motor omni wheelbase; motor fault diagnostics | STM32 firmware (micro-ROS or serial via semubot_driver), semubot_description |
| [respeaker_ros](https://github.com/SemuBot/respeaker_ros) | `src/respeaker_ros` | `master` | ROS 2 package | NUC | ReSpeaker 4-mic array wrapper: audio stream and direction of arrival | `audio_common`, ReSpeaker USB device |
| [semubot_webapp](https://github.com/SemuBot/semubot_webapp) | `apps/semubot_webapp` | `main` | app (FastAPI, Docker) | NUC | Touchscreen web control: driving, speech mode, chat, battery; talks to ROS through rosbridge | `rosbridge_server`, semubot_brain (`/speech_input`), `/semubot/battery` |
| [semubot_chest_display](https://github.com/SemuBot/semubot_chest_display) | `apps/semubot_chest_display` | `main` | app (Tkinter + rclpy) | NUC desktop session (chest touch screen) | Chest screen: images, Estonian/English menu, admin menu for speech mode, voice, microphone threshold, drive speed, battery; systemd user service in `deploy/` | semubot_brain topics, `/semubot/battery`, `/semubot/speed_scale` |

"Runs on" follows the component READMEs and the October 2026 architecture audit; entries marked *verify* have not been confirmed on the robots.

### Not included, and why

| Repository | Reason |
|---|---|
| [semubot-firmware](https://github.com/SemuBot/semubot-firmware) | Microcontroller firmware; to be added under `firmware/` once its `main` is brought up to date (the current variants live on the `fw/*` branches). |
| [semubot-deployment](https://github.com/SemuBot/semubot-deployment) | Empty placeholder; deployment tooling is planned. |
| [Operating-instructions](https://github.com/SemuBot/Operating-instructions) | Operator documentation, linked rather than vendored. |
| [audio_test](https://github.com/SemuBot/audio_test) | 2024 audio experiments, superseded by respeaker_ros. |
| [semubot-inventory](https://github.com/SemuBot/semubot-inventory) | Makerspace inventory tool, not robot software. |
| [semubot_backup](https://github.com/SemuBot/semubot_backup) | Archive of 2025 NUC and Raspberry Pi home directories. |
| `*-thesis-*` repositories | Archived thesis submissions; production work continues in the repositories above. |

Planned sections: `firmware/` (wheelbase and servo firmware), `ai/` (speech backends), deployment.

## Clone

```bash
git clone --recurse-submodules https://github.com/SemuBot/semubot-software.git
```

An existing clone without submodules: `git submodule update --init --recursive`.

## Build

The ROS 2 packages target Jazzy on Ubuntu 24.04. From the repository root:

```bash
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
```

The apps have their own instructions in their READMEs. Whether every package builds from a clean machine is being worked on; this repository records the state, it does not yet guarantee a green build.

## Update a pin

Submodules track the branch named in `.gitmodules`. To move one component to its latest commit:

```bash
git submodule update --remote src/semubot_brain
git add src/semubot_brain
git commit -m "semubot_brain: <subject of the new commit>"
```

Each commit here therefore documents a known-good combination of component versions.
