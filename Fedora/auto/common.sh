#!/bin/bash

####################################################
# Helper function to run commands with error tracking
####################################################
run_with_tracking() {
    local step_name="$1"
    shift
    echo "[*] Running: $step_name"
    if ! "$@"; then
        echo "[✗] Failed: $step_name"
        track_failure "$step_name"
        return 1
    fi
    echo "[✓] Success: $step_name"
    return 0
}

####################################################
# initial steps
####################################################

sudo dnf upgrade -y || track_failure "DNF system upgrade"

# git configure
git config --global user.name "Jayanta Debnath"
git config --global user.email Jayanta.Dn@gmail.com

# backup bashrc
cp ~/.bashrc ~/.bashrc.orig

# setup command prompt
if ! grep -q "export PS1=" ~/.bashrc; then
    echo "export PS1='\\[\\e[35m\\][\\A]\\[\\e[0m\\] \\[\\e[34m\\]\\W\\[\\e[0m\\] \\$ '" >> ~/.bashrc
fi

####################################################
# install python
####################################################
if ! (
    PYTHON_VERSION=3.10.13
    sudo dnf install -y make gcc gcc-c++ openssl-devel zlib-devel bzip2-devel \
    readline-devel sqlite-devel wget curl llvm ncurses-devel xz-utils \
    tk-devel libxml2-devel xmlsec1-devel libffi-devel xz-devel
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
); then
    track_failure "Python ${PYTHON_VERSION} installation"
fi


####################################################
# install flutter
####################################################
# install flutter
FLUTTER_VERSION="stable"
FLUTTER_DIR="$HOME/Tools/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
    echo "[*] Installing Flutter..."
    if (
        mkdir -p "$HOME/Tools"
        cd "$HOME/Tools"

        # Download Flutter
        git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION "$FLUTTER_DIR"

        # Add Flutter to PATH for current session
        export PATH="$PATH:$FLUTTER_DIR/bin"

        # Add Flutter to bashrc if not already present
        if ! grep -q "export PATH=.*\$HOME/Tools/flutter/bin" ~/.bashrc; then
            echo "export PATH=\$PATH:\$HOME/Tools/flutter/bin" >> ~/.bashrc
        fi

        # Run flutter doctor to download Dart SDK and other dependencies
        flutter doctor

        echo "[*] Flutter installation complete."
    ); then
        echo "[✓] Flutter installation successful"
    else
        track_failure "Flutter installation"
    fi
else
    echo "[*] Flutter already installed at $FLUTTER_DIR"
    export PATH="$PATH:$FLUTTER_DIR/bin"
fi


####################################################
# install android sdk
####################################################
if ! (
    SDK_DIR="$HOME/Tools/android-sdk"
    TOOLS_ZIP="commandlinetools-linux.zip"
    SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

    echo "[*] Installing Android SDK..."
    sudo dnf install -y unzip curl java-17-openjdk java-17-openjdk-devel
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
export PATH="\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator:\$PATH"
EOF
    else
        echo "[*] Android environment variables already exist in ~/.bashrc"
    fi

    # Set environment for current session
    export ANDROID_HOME="$SDK_DIR"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

    # Accept licenses and install platform tools
    yes | sdkmanager --sdk_root="$SDK_DIR" --licenses
    sdkmanager --sdk_root="$SDK_DIR" "platform-tools" "platforms;android-36" "build-tools;28.0.3" "emulator" "system-images;android-36;google_apis;x86_64"

    # Create Android Virtual Device
    echo "[*] Creating Android Virtual Device..."
    echo "no" | avdmanager create avd -n "Pixel_API_36" -k "system-images;android-36;google_apis;x86_64" -d "pixel" --force

    # Accept Flutter Android licenses
    yes | flutter doctor --android-licenses

    echo "[*] Android SDK installation complete."
); then
    track_failure "Android SDK installation"
fi

####################################################
# install node and firebase cli
####################################################
if ! (
    sudo dnf install -y curl dnf-plugins-core nodejs npm &&
    sudo npm install -g firebase-tools &&
    dart pub global activate flutterfire_cli
); then
    track_failure "Node.js and Firebase CLI installation"
fi

####################################################
# install google chrome
####################################################
if ! (
    sudo dnf install -y wget curl gnupg2 &&
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm -O /tmp/google-chrome-stable_current_x86_64.rpm &&
    sudo dnf install -y /tmp/google-chrome-stable_current_x86_64.rpm &&
    rm /tmp/google-chrome-stable_current_x86_64.rpm
); then
    track_failure "Google Chrome installation"
fi

####################################################
# install qemu
####################################################
if ! (
    sudo dnf install -y qemu-kvm libvirt-daemon libvirt-client bridge-utils virt-install virt-manager &&
    sudo usermod -aG libvirt $USER &&
    sudo usermod -aG kvm $USER &&
    sudo systemctl enable --now libvirtd
); then
    track_failure "QEMU/KVM installation"
fi

####################################################
# setup Scripts from OsSetup repo
####################################################
if ! (
    mkdir -p $HOME/GitRepos
    if [ ! -d "$HOME/GitRepos/OsSetup" ]; then
        echo "[*] Cloning OsSetup repo..."
        git clone https://github.com/jayantadn/OsSetup.git "$HOME/GitRepos/OsSetup"
    else
        echo "[*] OsSetup repo already exists at $HOME/GitRepos/OsSetup"
    fi

    SCRIPTS_DIR="$HOME/GitRepos/OsSetup/Scripts"
    python3.10 -m venv $SCRIPTS_DIR/.venv
    source $SCRIPTS_DIR/.venv/bin/activate
    pip install -r $SCRIPTS_DIR/requirements.txt
    deactivate
); then
    track_failure "Scripts setup from OsSetup repo"
fi

####################################################
# install zed editor
####################################################
if ! (
    curl -f https://zed.dev/install.sh | sh &&
    if ! printf '%s\n' "$PATH" | tr ':' '\n' | grep -qx "$HOME/.local/bin"; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi &&
    # apply for current shell
    export PATH="$HOME/.local/bin:$PATH"
); then
    track_failure "Zed editor installation"
fi



####################################################
# install other common tools
####################################################
sudo dnf install -y vim || track_failure "Vim installation"
