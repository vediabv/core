# Automatically generated by hassfest.
#
# To update, run python3 -m script.hassfest -p docker
ARG BUILD_FROM
FROM ${BUILD_FROM}

# Synchronize with homeassistant/core.py:async_stop
ENV \
    S6_SERVICES_GRACETIME=240000 \
    UV_SYSTEM_PYTHON=true

ARG QEMU_CPU
# Needs to be redefine inside the FROM statement to be set for RUN commands
ARG BUILD_ARCH

# Install uv
RUN pip3 install uv==0.4.9

WORKDIR /usr/src

## Setup Home Assistant Core dependencies
COPY requirements.txt homeassistant/
COPY homeassistant/package_constraints.txt homeassistant/homeassistant/
RUN \
    uv pip install \
        --no-build \
        -r homeassistant/requirements.txt

COPY requirements_all.txt home_assistant_frontend-* home_assistant_intents-* homeassistant/
RUN \
    if ls homeassistant/home_assistant_*.whl 1> /dev/null 2>&1; then \
        uv pip install homeassistant/home_assistant_*.whl; \
    fi \
    && if [ "${BUILD_ARCH}" = "i386" ]; then \
        linux32 uv pip install \
            --no-build \
            -r homeassistant/requirements_all.txt; \
    else \
        uv pip install \
            --no-build \
            -r homeassistant/requirements_all.txt; \
    fi

## Setup Home Assistant Core
COPY . homeassistant/
RUN \
    uv pip install \
        -e ./homeassistant \
    && python3 -m compileall \
        homeassistant/homeassistant

# Home Assistant S6-Overlay
COPY rootfs /

# Get go2rtc binary
RUN \
    case "${BUILD_ARCH}" in \
        "aarch64") go2rtc_suffix='arm64' ;; \
        "armhf") go2rtc_suffix='armv6' ;; \
        "armv7") go2rtc_suffix='arm' ;; \
        *) go2rtc_suffix=${BUILD_ARCH} ;; \
    esac \
    && curl -L https://github.com/AlexxIT/go2rtc/releases/download/v1.9.4/go2rtc_linux_${go2rtc_suffix} --output /bin/go2rtc \
    && chmod +x /bin/go2rtc \
    # Verify go2rtc can be executed
    && go2rtc --version

WORKDIR /config
