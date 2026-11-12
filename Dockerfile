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

FROM build
RUN echo 'source /opt/ros/jazzy/setup.bash && source /ws/install/setup.bash' >> /root/.bashrc
CMD ["bash"]
