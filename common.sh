#!/bin/bash

# initial steps
sudo apt update && sudo apt upgrade -y

# git configure
git config --global user.name "Jayanta Debnath"
git config --global user.email Jayanta.Dn@gmail.com

# add path
cp ~/.bashrc ~/.bashrc.orig
echo "export PATH=\$PATH:\$HOME/Tools/flutter/bin" >> ~/.bashrc

# setup command prompt
echo "export PS1='\\[\\e[35m\\][\\A]\\[\\e[0m\\] \\[\\e[34m\\]\\W\\[\\e[0m\\] \\$ '" >> ~/.bashrc

# install python
PYTHON_VERSION=3.10.13
sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils \
tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
cd /usr/src
sudo wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
sudo tar xvf Python-${PYTHON_VERSION}.tgz
sudo rm Python-${PYTHON_VERSION}.tgz
cd Python-${PYTHON_VERSION}
sudo ./configure --enable-optimizations
sudo make -j"$(nproc)"
sudo make altinstall
cd /usr/src
sudo rm -rf Python-${PYTHON_VERSION}


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

# install node and firebase cli
sudo apt install -y curl software-properties-common
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo bash -
sudo apt install -y nodejs
sudo npm install -g firebase-tools
dart pub global activate flutterfire_cli

# install google chrome
sudo apt install -y wget curl apt-transport-https gnupg
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome-stable_current_amd64.deb
sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb
rm /tmp/google-chrome-stable_current_amd64.deb

# install qemu
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER
sudo systemctl enable --now libvirtd

# clone the Scripts repo
git clone https://github.com/jayantadn/Scripts.git "$HOME/Tools/Scripts"
python3.10 -m venv $HOME/Tools/Scripts/.venv
source $HOME/Tools/Scripts/.venv/bin/activate
pip install -r $HOME/Tools/Scripts/requirements.txt
deactivate

