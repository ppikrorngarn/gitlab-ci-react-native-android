#!/bin/bash

# Before running the script you must 
# 1. install sudo as root: apt-get install sudo
# 2. update as root: apt-get update
# 3. create gitlab-runner user: useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
# 4. make gitlab-runner a sudoer: usermod -aG sudo gitlab-runner
# 5. set password for gitlab-runner: passwd gitlab-runner
# 6. make gitlab-runner require no password for sudo: echo "gitlab-runner     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# 7. run: su - gitlab-runner
# 8. copy this script and packages.txt to home directory of gitlab-runner
# 9. run the script

sudo apt-get -qq update && \
    sudo apt-get install -qqy --no-install-recommends \
      apt-utils \
      bzip2 \
      curl \
      git-core \
      html2text \
      openjdk-8-jdk \
      libc6-i386 \
      lib32stdc++6 \
      lib32gcc1 \
      lib32ncurses5 \
      lib32z1 \
      unzip \
      gnupg \
      openssh-server \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

echo "Android SDK 28.0.3"
export VERSION_SDK_TOOLS="4333796"
export BUILD_TOOLS="26.0.0"
export ANDROID_PLATFORM="android-28"

export USER_HOME="/home/gitlab-runner" # If use ~ copy and move command will not work
echo "ANDROID_HOME: $USER_HOME/sdk"
export ANDROID_HOME=$USER_HOME/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH="$PATH:${ANDROID_HOME}/tools"
export DEBIAN_FRONTEND=noninteractive

export NVM_DIR=/usr/local/nvm
export NVM_VERSION=v0.33.11
export NODE_VERSION=v8.12.0

export GRADLE_HOME=/opt/gradle
export GRADLE_VERSION=4.6

export BASH_PROFILE=$USER_HOME/.profile

sudo rm -f /etc/ssl/certs/java/cacerts; \
    sudo /var/lib/dpkg/info/ca-certificates-java.postinst configure

echo "Installing inotify" && \
  sudo apt-get update && \
  sudo apt-get install -y inotify-tools

curl -s https://dl.google.com/android/repository/sdk-tools-linux-${VERSION_SDK_TOOLS}.zip > $USER_HOME/sdk.zip && \
    unzip $USER_HOME/sdk.zip -d $USER_HOME/sdk && \
    rm -v $USER_HOME/sdk.zip

mkdir -p $ANDROID_HOME/licenses/ \
  && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_HOME/licenses/android-sdk-license \
  && echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license

mv packages.txt $USER_HOME/sdk

mkdir -p $USER_HOME/.android && \
  touch $USER_HOME/.android/repositories.cfg && \
  ${ANDROID_HOME}/tools/bin/sdkmanager --update

while read -r package; do PACKAGES="${PACKAGES}${package} "; done < $USER_HOME/sdk/packages.txt && \
    ${ANDROID_HOME}/tools/bin/sdkmanager ${PACKAGES}

echo no | ${ANDROID_HOME}/tools/bin/avdmanager create avd -n "Android28" -k "system-images;${ANDROID_PLATFORM};google_apis;x86_64" \
  && sudo ln -s ${ANDROID_HOME}/tools/emulator /usr/bin \
  && sudo ln -s ${ANDROID_HOME}/platform-tools/adb /usr/bin

echo "Installing Yarn Deb Source" \
	&& curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
	&& echo "deb http://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo mkdir $NVM_DIR

echo "Installing NVM" \
	&& curl -o- https://raw.githubusercontent.com/creationix/nvm/$NVM_VERSION/install.sh | sudo bash

source $BASH_PROFILE

export NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules
export PATH=$NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH

echo "source $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default" | sudo bash

export BUILD_PACKAGES="git yarn build-essential imagemagick librsvg2-bin ruby ruby-dev wget libcurl4-openssl-dev"

echo "Installing Additional Libraries" \
	 && sudo rm -rf /var/lib/gems \
	 && sudo apt-get update && sudo apt-get install $BUILD_PACKAGES -qqy --no-install-recommends

echo "Downloading Gradle" \
	&& wget --no-verbose --output-document=gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

echo "Installing Gradle" \
	&& unzip gradle.zip \
	&& rm gradle.zip \
	&& sudo mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
	&& sudo ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle

echo "Installing Fastlane 2.61.0" \
	&& sudo gem install fastlane badge -N \
	&& sudo gem cleanup

echo "Install RVM and Ruby 2.6.3" && \
  sudo gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
  sudo apt-get install -y software-properties-common && \
  sudo apt-add-repository -y ppa:rael-gc/rvm && \
  sudo apt-get update && \
  sudo apt-get install -y rvm && \
  echo 'source "/etc/profile.d/rvm.sh"' >> $BASH_PROFILE && \
  source $BASH_PROFILE && \
  sudo chown -R $USER:$(id -gn $USER) /home/gitlab-runner/.config && \
  rvmsudo rvm get stable --auto-dotfiles && \
  rvm fix-permissions system && \
  rvm reload && \
  sudo chown -R gitlab-runner:rvm /usr/share/rvm/* && \
  rvm install 2.6.3 && \
  rvm use 2.6.3

echo "Installing Bundler 2.0.1" \
	&& gem install bundler -v 2.0.1

echo "Install zlib1g-dev for Bundler" && \
  sudo apt-get update && sudo apt-get install -qqy --no-install-recommends \
  zlib1g-dev

export WATCHMAN_VERSION=4.9.0

echo "Install Watchman" && \
  sudo apt-get update && sudo apt-get install -qqy --no-install-recommends libssl-dev pkg-config libtool curl ca-certificates build-essential autoconf python-dev libpython-dev autotools-dev automake && \
  curl -LO https://github.com/facebook/watchman/archive/v${WATCHMAN_VERSION}.tar.gz && \
  tar xzf v${WATCHMAN_VERSION}.tar.gz && rm v${WATCHMAN_VERSION}.tar.gz && \
  cd watchman-${WATCHMAN_VERSION} && ./autogen.sh && ./configure && make && sudo make install && \
  sudo -s && cd /tmp && rm -rf watchman-${WATCHMAN_VERSION} && exit

cd $USER_HOME

echo "Install Git LFS" && \
  curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh && \
  sudo apt-get update && \
  sudo apt-get install -qqy git-lfs

#Clone via ssh instead of http
#This is used for libraries that we clone from a private gitlab repo.
#Setup see here https://divan.github.io/posts/go_get_private/
echo "[url \"git@gitlab.com:\"]\\n\\tinsteadOf = https://gitlab.com/" >> $USER_HOME/.gitconfig
mkdir $USER_HOME/.ssh && echo "StrictHostKeyChecking no " > $USER_HOME/.ssh/config

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && sudo apt-get update -y && sudo apt-get install google-cloud-sdk -y

# Docs see here: https://www.tecmint.com/install-imagemagick-on-debian-ubuntu/
# zlib1g-dev is already installed with Bundler installation
# libpng12-dev is only available on Ubuntu 16, so replaced it with libpng16-16
echo "Install ImageMagick" && \
  sudo apt-get update && \
  sudo apt-get install -qqy build-essential \
    checkinstall \
    libx11-dev \
    libxext-dev \
    libpng16-16 \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev && \
  wget https://www.imagemagick.org/download/ImageMagick.tar.gz && \
  tar xvzf ImageMagick.tar.gz && \
  cd $(find . -maxdepth 1 -type d -name "ImageMagick*") && \
  ./configure && \
  make && \
  sudo make install && \
  sudo ldconfig /usr/local/lib && \
  cd $USER_HOME && \
  rm ImageMagick.tar.gz

# Must start emulator created by avdmanager to auto internally linking avd path
sudo chown gitlab-runner -R /dev/kvm &&
($ANDROID_HOME/emulator/emulator @Android28 -no-audio -no-window) & \
  echo "Starting emulator for the first time." && \
  sleep 30 && \
  adb kill-server && \
  adb devices | grep "emulator-" | while read -r emulator device; do adb -s $emulator emu kill; done && \
  echo "Emulator stopped."

echo "Download and install Android28 and SixPointFive emulators" && \
  wget -O avd.tar.gz "https://firebasestorage.googleapis.com/v0/b/storage-353d1.appspot.com/o/avd.tar.gz?alt=media&token=ebdd3e59-927c-4940-9549-7551337b2c83" && \
  tar -zxf avd.tar.gz && \
  rm -rf .android/avd && \
  mv avd .android/

echo "Increase Watchman inotify" && \
  echo 999999 | sudo tee -a /proc/sys/fs/inotify/max_user_watches && \
  echo 999999 | sudo tee -a /proc/sys/fs/inotify/max_queued_events && \
  echo 999999 | sudo tee -a /proc/sys/fs/inotify/max_user_instances && \
  watchman shutdown-server

echo "Export PATH in .profile" && \
    echo 'export USER_HOME="/root"' >> $BASH_PROFILE && \
    echo 'export ANDROID_HOME=$USER_HOME/sdk' >> $BASH_PROFILE && \
    echo 'export ANDROID_SDK_ROOT=$ANDROID_HOME' >> $BASH_PROFILE && \
    echo 'export PATH=$PATH:$ANDROID_HOME/emulator' >> $BASH_PROFILE && \
    echo 'export PATH=$PATH:$ANDROID_HOME/tools' >> $BASH_PROFILE && \
    echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> $BASH_PROFILE

source $BASH_PROFILE
