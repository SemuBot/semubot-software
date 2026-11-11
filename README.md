# semubot-software

All SemuBot software components as git submodules, pinned to known commits. Software counterpart of [semubot-mechanics](https://github.com/SemuBot/semubot-mechanics) and [semubot-electronics](https://github.com/SemuBot/semubot-electronics). The root is a colcon workspace.

```
semubot-software/
├── src/                            ROS 2 packages (Jazzy)
│   ├── semubot_bringup             launch files: ros2_control + micro-ROS wheelbase stack, joystick     [STM32 robot host]
│   ├── semubot_ros_control         ros2_control hardware interface + velocity controller, 3-wheel omni  [STM32 robot host]
│   ├── semubot_driver              serial driver for the STM32 wheelbase firmware                       [STM32 robot host]
│   ├── semubot_raspberry_bringup   GPIO motor driver, e-stop, joystick, battery monitor, systemd         [Raspberry Pi 5 robot]
│   ├── semubot_description         URDF/xacro model (V1 + V2 wheelbase), meshes                          [any]
│   ├── semubot_arm_description     arm + hand xacro macro, included by semubot_description               [any]
│   ├── semubot_gazebo              Gazebo worlds and launch                                              [dev PC]
│   ├── semubot_brain               speech: VAD, ASR, LLM (local or cloud), Estonian TTS                  [NUC]
│   ├── semubot_eyes                animated face driven by mic direction and brain state                 [NUC]
│   └── respeaker_ros               ReSpeaker 4-mic array: audio + direction of arrival                   [NUC]
├── apps/                           non-ROS apps
│   ├── semubot_webapp              touchscreen web control via rosbridge (FastAPI, Docker)               [NUC]
│   └── semubot_chest_display       chest touch screen: menus, speech settings, battery (Tkinter+rclpy)   [NUC]
└── firmware/                       microcontroller firmware
    └── wheelbase                   STM32F303 wheelbase: FreeRTOS, micro-ROS, DRV8353 (branch fw/ros2ctrl-microros) [STM32 board]
```

Branches tracked: `jazzy` for description, arm_description, gazebo, ros_control; `fw/ros2ctrl-microros` for the firmware (the active stack; the other variants `fw/ros2ctrl-serial`, `fw/onboard-pid-microros`, `fw/onboard-pid-serial` stay as branches of semubot-firmware); `main`/`master` for the rest. The firmware submodule is shallow (`shallow = true`) because its history is large.

Not included: `semubot-deployment` (empty), `Operating-instructions` (docs), `audio_test` (superseded), `semubot-inventory` (not robot software), `semubot_backup` (archive), `*-thesis-*` (archived submissions).

```bash
git clone --recurse-submodules https://github.com/SemuBot/semubot-software.git
rosdep install --from-paths src --ignore-src -r -y && colcon build --symlink-install
git submodule update --remote src/<pkg> && git add src/<pkg> && git commit   # move one pin
```
