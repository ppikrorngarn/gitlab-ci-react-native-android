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
    "platforms;android-18" \
    "platforms;android-28" \
    "platforms;android-29"
yes | "$ANDROID_HOME"/tools/bin/sdkmanager "platform-tools"
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "build-tools;28.0.3"
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "extras;android;m2repository" \
    "extras;google;m2repository"

curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh &&
    apt-get update && apt-get install git-lfs

echo -e "[url \"git@gitlab.com:\"]\n\tinsteadOf = https://gitlab.com/" >>$USER_HOME/.gitconfig
mkdir $USER_HOME/.ssh && echo "StrictHostKeyChecking no " >$USER_HOME/.ssh/config

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list &&
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - &&
    apt-get update -y && apt-get install google-cloud-sdk -y

mkdir ~/.gnupg && echo "disable-ipv6" >>~/.gnupg/dirmngr.conf
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
echo 409B6B1796C275462A1703113804BB82D39DC0E3:6: | gpg2 --import-ownertrust
echo 7D2BAF1CF37B13E2069D6956105BD0E739499BDB:6: | gpg2 --import-ownertrust
\curl -sSL https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
rvm install $RUBY_VERSION
rvm --default use $RUBY_VERSION
gem install bundler -v $BUNDLER_VERSION
bundle config build.nokogiri --use-system-libraries

echo 'source /etc/profile.d/rvm.sh' >> $USER_HOME/.bashrc

curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64 &&
    chmod +x /usr/local/bin/gitlab-runner &&
    gitlab-runner install --user=root --working-directory=/root/gitlab-runner &&
    gitlab-runner start &&
    echo "Please follow the instructions on https://docs.gitlab.com/runner/register/index.html to register your runner!"
