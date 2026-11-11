FROM ros:jazzy-ros-base AS deps
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        git python3-pip python3-colcon-common-extensions python3-rosdep python3-vcstool \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /ws
COPY src ./src
RUN apt-get update \
    && rosdep update --rosdistro jazzy \
    && rosdep install --from-paths src --ignore-src -r -y --rosdistro jazzy \
    && rm -rf /var/lib/apt/lists/*

FROM deps AS build
RUN source /opt/ros/jazzy/setup.bash && colcon build --symlink-install

FROM build AS test
RUN source /opt/ros/jazzy/setup.bash && source /ws/install/setup.bash \
    && colcon test; colcon test-result --verbose; true

FROM microros/micro_ros_static_library_builder:jazzy AS microros
COPY firmware/wheelbase/wheelbase /project
RUN printf -- '-mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -Os --specs=nano.specs -DUSE_HAL_DRIVER -DSTM32F303xE\n' > /project/flags.mk \
    && MICROROS_LIBRARY_FOLDER=micro_ros_stm32cubemx_utils/microros_static_library_ide /entrypoint.sh

FROM ubuntu:24.04 AS firmware
RUN apt-get update && apt-get install -y --no-install-recommends gcc-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib make \
    && rm -rf /var/lib/apt/lists/*
COPY --from=microros /project /fw
RUN make -C /fw

FROM build
RUN echo 'source /opt/ros/jazzy/setup.bash && source /ws/install/setup.bash' >> /root/.bashrc
CMD ["bash"]
