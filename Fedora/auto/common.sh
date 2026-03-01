#!/bin/bash

####################################################
# initial steps
####################################################

sudo dnf upgrade -y

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
(
PYTHON_VERSION="3.10.14"
PREFIX="/usr/local"
SRC_DIR="/usr/src"
BUILD_DIR="${SRC_DIR}/Python-${PYTHON_VERSION}"
TARBALL="Python-${PYTHON_VERSION}.tgz"
URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/${TARBALL}"

echo "==> Installing build dependencies..."

sudo dnf install -y \
    gcc \
    gcc-c++ \
    make \
    openssl-devel \
    bzip2-devel \
    libffi-devel \
    zlib-devel \
    readline-devel \
    sqlite-devel \
    tk-devel \
    xz-devel \
    gdbm-devel \
    ncurses-devel \
    libuuid-devel \
    libnsl2-devel \
    wget \
    tar

echo "==> Downloading Python ${PYTHON_VERSION}..."
sudo mkdir -p "${SRC_DIR}"
cd "${SRC_DIR}"

if [ ! -f "${TARBALL}" ]; then
    sudo wget "${URL}"
fi

echo "==> Extracting..."
sudo tar -xzf "${TARBALL}"

cd "${BUILD_DIR}"

echo "==> Configuring build..."
sudo ./configure \
    --enable-optimizations \
    --with-lto \
    --prefix="${PREFIX}"

echo "==> Building (this will take a while)..."
sudo make -j"$(nproc)"

echo "==> Installing (altinstall, safe for system Python)..."
sudo make altinstall

echo "==> Verifying installation..."
${PREFIX}/bin/python3.10 --version

echo "==> Done."
echo "Binary location: ${PREFIX}/bin/python3.10"
)


####################################################
# install flutter
####################################################
# install flutter
FLUTTER_VERSION="stable"
FLUTTER_DIR="$HOME/Tools/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
    echo "[*] Installing Flutter..."
    (
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
    )
else
    echo "[*] Flutter already installed at $FLUTTER_DIR"
    export PATH="$PATH:$FLUTTER_DIR/bin"
fi


####################################################
# install android sdk
####################################################
(
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
)

####################################################
# install node and firebase cli
####################################################
(
    sudo dnf install -y curl dnf-plugins-core nodejs npm &&
    sudo npm install -g firebase-tools &&
    dart pub global activate flutterfire_cli
)

####################################################
# install google chrome
####################################################
(
    sudo dnf install -y wget curl gnupg2 &&
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm -O /tmp/google-chrome-stable_current_x86_64.rpm &&
    sudo dnf install -y /tmp/google-chrome-stable_current_x86_64.rpm &&
    rm /tmp/google-chrome-stable_current_x86_64.rpm
)

####################################################
# install qemu
####################################################
(
    sudo dnf install -y qemu-kvm libvirt-daemon libvirt-client bridge-utils virt-install virt-manager &&
    sudo usermod -aG libvirt $USER &&
    sudo usermod -aG kvm $USER &&
    sudo systemctl enable --now libvirtd
)

####################################################
# setup Scripts from OsSetup repo
####################################################
(
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
)

####################################################
# install zed editor
####################################################
(
    curl -f https://zed.dev/install.sh | sh &&
    if ! printf '%s\n' "$PATH" | tr ':' '\n' | grep -qx "$HOME/.local/bin"; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi &&
    # apply for current shell
    export PATH="$HOME/.local/bin:$PATH"
)



####################################################
# install other common tools
####################################################
sudo dnf install -y vim
