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

With Docker (also what CI runs; the `firmware` target builds the STM32 image with the Makefile from `semubot-firmware`, and CI builds the webapp image from `apps/semubot_webapp` as well):

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

On a robot computer (Ubuntu 24.04, ROS 2 Jazzy, user `semubot`), after the clone. The first run creates `~/.config/semubot/semubot.env`; set `SEMUBOT_MACHINE` there to `pi` (drive stack) or `nuc` (speech, face, webapp, chest display) and run again:

```bash
deploy/semubot install            # build, user units, udev rule, start at boot
deploy/semubot update [REF]       # switch to a commit or tag (default origin/main) and reinstall
deploy/semubot rollback           # back to the commit the last update replaced
```

Units are `semubot-drive` on the Pi; `semubot-rosbridge`, `semubot-brain`, `semubot-respeaker`, `semubot-eyes`, `semubot-webapp` and the chest display's own unit on the NUC. The speech backends (whisper, llama, TTS) are not part of this workspace yet.

Move a pin after a component repo changed:

```bash
git submodule update --remote ros2_ws/src/<pkg> && git add ros2_ws/src/<pkg> && git commit
```

ROS 2 topics between the components (domain 5, CycloneDDS):

| Topic | Type | Content | From | To |
|---|---|---|---|---|
| `/joy` | `sensor_msgs/Joy` | gamepad axes and buttons | `joy` | `teleop_twist_joy` |
| `/cmd_vel` | `geometry_msgs/Twist` | V2: m/s and rad/s, clamped to 0.4; V1: unitless −1..1 | `teleop_twist_joy`, `semubot_webapp` | `semubot_ros_control` velocity controller (V2), `semubot_raspberry_bringup` (V1) |
| `/hardware_interface/velocity_cmd` | `std_msgs/Float32MultiArray` | PWM duty per motor `[M1, M2, M3]`, clamped to 0.30 by the controller and 0.50 by the firmware | `semubot_ros_control` hardware interface | `firmware/wheelbase` (motors stop after 1 s without a message) |
| `/motor_states` | `sensor_msgs/JointState` | joints `omni_ball_{1,2,3}_joint`: position rad, velocity rad/s, effort = driver fault bits | `firmware/wheelbase` | `semubot_ros_control` hardware interface and fault diagnostics |
| `/joint_states` | `sensor_msgs/JointState` | wheel joints | `joint_state_broadcaster` | `robot_state_publisher` |
| `/odom` | `nav_msgs/Odometry` | `odom` → `base_link` from wheel kinematics | `semubot_ros_control` velocity controller | none |
| `/diagnostics` | `diagnostic_msgs/DiagnosticArray` | one entry per motor driver, decoded from the fault bits | `semubot_ros_control` fault diagnostics | none |
| `/controller_manager/diagnostics` | `diagnostic_msgs/DiagnosticArray` | controller manager status | `controller_manager` | none |
| `/emergency_stop` | `std_msgs/Bool` | only `true` is sent | `semubot_webapp` | `semubot_raspberry_bringup` (V1 only) |
| `/semubot/speed_scale` | `std_msgs/Float32` | 0.1–1.0 multiplier on `/cmd_vel`, latched | `semubot_chest_display` | `semubot_raspberry_bringup` (V1 only) |
| `/semubot/battery` | `sensor_msgs/BatteryState` | voltage and percentage | `semubot_raspberry_bringup` (V1) | `semubot_chest_display`, `semubot_webapp` |
| `audio` | `audio_common_msgs/AudioData` | 16 kHz mono int16, 0.1 s chunks | `respeaker_ros` | `semubot_brain` |
| `vad` | `std_msgs/Bool` | mic-array voice flag, latched | `respeaker_ros` | none |
| `doa_raw` | `std_msgs/Int32` | direction of arrival in degrees, latched | `respeaker_ros` | none |
| `/speech_input` | `std_msgs/String` | text to say, spoken in every mode | `semubot_webapp`, `semubot_chest_display` | `semubot_brain`; also the webapp's speech node when it runs |
| `/semubot/mode` | `std_msgs/String` | `manual`, `local` or `cloud` | `semubot_webapp`, `semubot_chest_display` | `semubot_brain` |
| `/semubot/mode_state` | `std_msgs/String` | current mode, latched | `semubot_brain` | `semubot_webapp`, `semubot_chest_display` |
| `/semubot/state` | `std_msgs/String` | JSON `{"stage","mode","since"}`, latched | `semubot_brain` | `semubot_eyes`, `semubot_chest_display` |
| `/semubot/audio_level` | `std_msgs/Float32MultiArray` | `[rms, speech_probability]` | `semubot_brain` | `semubot_chest_display` |
| `/semubot/vad_threshold` | `std_msgs/Float32` | RMS threshold to set | `semubot_chest_display` | `semubot_brain` |
| `/semubot/vad_threshold_state` | `std_msgs/Float32` | current threshold, latched | `semubot_brain` | `semubot_chest_display` |
| `/semubot/tts_settings` | `std_msgs/String` | JSON `{"speaker","speed"}` to set | `semubot_chest_display` | `semubot_brain` |
| `/semubot/tts_settings_state` | `std_msgs/String` | current settings with the speaker list, latched | `semubot_brain` | `semubot_chest_display` |
| `/semubot/conversation_log` | `std_msgs/String` | JSON list of the last 30 entries, latched | `semubot_brain` | `semubot_chest_display`, `semubot_eyes` |
| `/semubot/conversation_log_clear` | `std_msgs/Empty` | | `semubot_chest_display` | `semubot_brain` |
| `/semubot/cloud_usage` | `std_msgs/String` | JSON `{"today","month","model","priced"}`, latched | `semubot_brain` | `semubot_chest_display` |
| `/face/background_color` | `std_msgs/String` | `#RRGGBB`, latched | `semubot_chest_display` | `semubot_eyes` |

Topics without a leading slash are relative and land under the node's namespace. No services or actions are declared.

Interfaces outside ROS:

| Interface | Between | Contract |
|---|---|---|
| micro-ROS serial | Raspberry Pi 5 ↔ STM32 wheelbase | USB CDC, `/dev/semubot_wheelbase`, `micro_ros_agent serial`; the firmware stops the motors when the agent link drops |
| Text serial protocol | host ↔ STM32 (other firmware branches) | `CMD:vx,vy,wz` → `STATE:p1,p2,p3,v1,v2,v3` at 115200 baud; spoken only by `semubot_driver` |
| rosbridge websocket | webapp container → NUC | `ws://ROSBRIDGE_HOST:9090` |
| Webapp HTTP | phone or tablet → NUC `:8000` | `POST /api/robot/{move,chat,mode,emergency_stop}`, `GET /api/robot/status`; no authentication |
| Speech backends | brain → NUC localhost | HTTP: whisper `:8081/inference`, llama `:8082`, TTS `:8001/v2`; overridable in `~/.config/semubot/brain.env` |
| Battery sensor | Raspberry Pi 5 (V1) | INA260 on I2C bus 1, address 0x40 |
