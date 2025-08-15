#!/bin/bash

# initial steps
sudo apt update && sudo apt upgrade -y

# git configure
git config --global user.name "Jayanta Debnath"
git config --global user.email Jayanta.Dn@gmail.com

# add path
echo "export PATH=$PATH:$HOME/Tools/flutter/bin" >> ~/.bashrc

# setup command prompt
echo "export PS1='\\[\\e[35m\\][\\A]\\[\\e[0m\\] \\[\\e[34m\\]\\W\\[\\e[0m\\] \\$ '" >> ~/.bashrc

# install python 3.10
sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
cd /usr/src
sudo wget https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz
sudo tar xvf Python-3.10.13.tgz
sudo rm Python-3.10.13.tgz
cd Python-3.10.13
sudo ./configure --enable-optimizations
sudo make -j$(nproc)
sudo make altinstall
sudo rm -rf /usr/src/Python-3.10.13

# install android sdk
SDK_DIR="$HOME/Tools/android-sdk"
TOOLS_ZIP="commandlinetools-linux.zip"
SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
sudo apt install -y unzip curl openjdk-17-jdk
mkdir -p "$SDK_DIR/cmdline-tools"
curl -o "$TOOLS_ZIP" "$SDK_URL"
unzip -q "$TOOLS_ZIP" -d "$SDK_DIR/cmdline-tools"
mv "$SDK_DIR/cmdline-tools/cmdline-tools" "$SDK_DIR/cmdline-tools/latest"
rm "$TOOLS_ZIP"
if ! grep -q "ANDROID_HOME" "$HOME/.bashrc"; then
    echo "[*] Adding environment variables to ~/.bashrc"
    cat <<EOF >> "$HOME/.bashrc"

# Android SDK
export ANDROID_HOME="$SDK_DIR"
export PATH="\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH"
EOF
fi
rm -rf "$ANDROID_HOME/cmdline-tools/latest"
mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
export ANDROID_HOME="$SDK_DIR"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
yes | sdkmanager --sdk_root="$SDK_DIR" --licenses
$HOME/Tools/android-sdk/cmdline-tools/cmdline-tools/bin/sdkmanager --sdk_root="$SDK_DIR" "platform-tools" "platforms;android-34" "build-tools;34.0.0"
flutter doctor --android-licenses

