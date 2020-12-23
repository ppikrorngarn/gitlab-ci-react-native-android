#!/bin/bash
export USER_HOME='/root'
export ANDROID_HOME='/opt/android-sdk'
export ANDROID_NDK='/opt/android-ndk'
export ANDROID_SDK_TOOLS_VERSION='3859397'
export ANDROID_NDK_VERSION='15c'

export DEBIAN_FRONTEND='noninteractive'
export ANDROID_SDK_HOME="$ANDROID_HOME"
export ANDROID_NDK_HOME="$ANDROID_NDK/android-ndk-r${ANDROID_NDK_VERSION}"
export PATH="$PATH:$ANDROID_SDK_HOME/tools:$ANDROID_SDK_HOME/platform-tools:$ANDROID_NDK"
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
export TERM=dumb

export RUBY_VERSION='2.6.3'
export BUNDLER_VERSION='2.0.1'

apt-get update -y
apt-get install -y software-properties-common
apt-get install -y \
    apt-utils \
    build-essential \
    autoconf \
    curl \
    git \
    lib32stdc++6 \
    lib32z1 \
    lib32z1-dev \
    lib32ncurses5 \
    libc6-dev \
    libgmp-dev \
    libmpc-dev \
    libmpfr-dev \
    libxslt-dev \
    libxml2-dev \
    m4 \
    ncurses-dev \
    ocaml \
    openjdk-8-jdk \
    openssh-client \
    pkg-config \
    software-properties-common \
    ruby-full \
    unzip \
    wget \
    zip \
    zlib1g-dev \
    libcurl4-openssl-dev \
    gnupg2

wget --quiet --output-document=sdk-tools.zip \
    "https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip" &&
    mkdir --parents "$ANDROID_HOME" &&
    unzip -q sdk-tools.zip -d "$ANDROID_HOME" &&
    rm --force sdk-tools.zip &&
    echo "installing ndk" &&
    wget --quiet --output-document=android-ndk.zip \
        "http://dl.google.com/android/repository/android-ndk-r${ANDROID_NDK_VERSION}-linux-x86_64.zip" &&
    mkdir --parents "$ANDROID_NDK/android-ndk-r${ANDROID_NDK_VERSION}" &&
    unzip -q android-ndk.zip -d "$ANDROID_NDK" &&
    rm --force android-ndk.zip

mkdir --parents "$USER_HOME/.android/"
echo '### User Sources for Android SDK Manager' >"$USER_HOME/.android/repositories.cfg"
yes | "$ANDROID_HOME"/tools/bin/sdkmanager --licenses >/dev/null
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "platforms;android-16" \
    "platforms;android-17" \
    "platforms;android-18" \
    "platforms;android-19" \
    "platforms;android-20" \
    "platforms;android-21" \
    "platforms;android-22" \
    "platforms;android-23" \
    "platforms;android-24" \
    "platforms;android-25" \
    "platforms;android-26"
yes | "$ANDROID_HOME"/tools/bin/sdkmanager "platform-tools"
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "build-tools;24.0.0" "build-tools;24.0.1" \
    "build-tools;24.0.2" "build-tools;24.0.3" \
    "build-tools;25.0.0" "build-tools;25.0.1" "build-tools;25.0.2" "build-tools;25.0.3" \
    "build-tools;26.0.0" "build-tools;26.0.1" "build-tools;26.0.2"
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "build-tools;17.0.0" \
    "build-tools;18.1.1" \
    "build-tools;19.1.0" \
    "build-tools;20.0.0" \
    "build-tools;21.1.2" \
    "build-tools;22.0.1" \
    "build-tools;23.0.1" "build-tools;23.0.2" "build-tools;23.0.3"
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "extras;android;m2repository" \
    "extras;google;m2repository"
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "extras;google;google_play_services" \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.1" \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2"
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "add-ons;addon-google_apis-google-16" \
    "add-ons;addon-google_apis-google-17" \
    "add-ons;addon-google_apis-google-18" \
    "add-ons;addon-google_apis-google-19" \
    "add-ons;addon-google_apis-google-21" \
    "add-ons;addon-google_apis-google-22" \
    "add-ons;addon-google_apis-google-23" \
    "add-ons;addon-google_apis-google-24"

curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh &&
    apt-get update && apt-get install git-lfs

echo "[url \"git@gitlab.com:\"]\n\tinsteadOf = https://gitlab.com/" >>$USER_HOME/.gitconfig
mkdir $USER_HOME/.ssh && echo "StrictHostKeyChecking no " >$USER_HOME/.ssh/config

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list &&
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - &&
    apt-get update -y && apt-get install google-cloud-sdk -y

mkdir ~/.gnupg && echo "disable-ipv6" >>~/.gnupg/dirmngr.conf
gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
echo 409B6B1796C275462A1703113804BB82D39DC0E3:6: | gpg2 --import-ownertrust && \ 
echo 7D2BAF1CF37B13E2069D6956105BD0E739499BDB:6: | gpg2 --import-ownertrust
\curl -sSL https://get.rvm.io | bash -s stable &&
    source /etc/profile.d/rvm.sh &&
    rvm install $RUBY_VERSION &&
    rvm --default use $RUBY_VERSION &&
    gem install bundler -v $BUNDLER_VERSION &&
    bundle config build.nokogiri --use-system-libraries

echo 'source /etc/profile.d/rvm.sh' >> $USER_HOME/.bashrc

curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64 &&
    chmod +x /usr/local/bin/gitlab-runner &&
    gitlab-runner install --user=root --working-directory=/root/gitlab-runner &&
    gitlab-runner start &&
    echo "Please follow the instructions on https://docs.gitlab.com/runner/register/index.html to register your runner!"
