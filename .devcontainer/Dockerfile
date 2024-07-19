FROM mcr.microsoft.com/devcontainers/python:1-3.9-bookworm
#FROM mcr.microsoft.com/vscode/devcontainers/base:bookworm

ARG DEV_USER="vscode"
ARG DEV_PKGS="fish screenfetch nano"
ARG DEV_PKGS_UNINSTALL="zsh"
ARG DEV_PYTHON_VERSION="3.9"

RUN apt update -y
RUN apt install $DEV_PKGS -y
RUN apt remove $DEV_PKGS_UNINSTALL -y

RUN sudo -u $DEV_USER pip install --upgrade pip

RUN install -d -m 0755 -o $DEV_USER -g $DEV_USER "/home/$DEV_USER/.local/share"
