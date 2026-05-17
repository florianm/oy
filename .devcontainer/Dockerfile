FROM ghcr.io/astral-sh/uv:latest AS uv

FROM rust:1.95-slim-trixie

ENV PYTHONUNBUFFERED 1
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN apt-get update  \
    && apt-get -y --no-install-recommends install  \
        sudo curl git git-lfs ca-certificates build-essential openssh-client wget locales \
    && sed -i '/^# *en_US.UTF-8 UTF-8/s/^# *//' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*


RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash vscode \
    && echo "vscode ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

COPY --from=uv --chown=vscode: /uv /uvx /bin/

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN cargo install --locked oy-cli
