FROM ubuntu:18.04

SHELL ["/bin/bash", "-c"] 

ENV USER_HOME='/root'

ENV ANDROID_HOME='/opt/android-sdk'
ENV ANDROID_NDK='/opt/android-ndk'
ENV ANDROID_SDK_TOOLS_VERSION='3859397'
ENV ANDROID_NDK_VERSION='15c'

ENV DEBIAN_FRONTEND='noninteractive'
ENV ANDROID_SDK_HOME="$ANDROID_HOME"
ENV ANDROID_NDK_HOME="$ANDROID_NDK/android-ndk-r${ANDROID_NDK_VERSION}"
ENV PATH="$PATH:$ANDROID_SDK_HOME/tools:$ANDROID_SDK_HOME/platform-tools:$ANDROID_NDK"
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
ENV TERM=dumb 

RUN apt-get update -y && \
  apt-get install -y software-properties-common && \
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

RUN mkdir ~/.gnupg
RUN echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf
RUN touch $USER_HOME/.profile

RUN echo "Install RVM and Ruby 2.6.3"
RUN gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN apt-get install -y software-properties-common
RUN apt-add-repository -y ppa:rael-gc/rvm
RUN apt-get update
RUN apt-get install -y rvm
RUN echo 'source "/etc/profile.d/rvm.sh"' >> $USER_HOME/.profile
RUN source $USER_HOME/.profile
RUN rvm install 2.6.3
RUN rvm use 2.6.3

RUN gem install bundler -v 2.0.1

RUN wget --quiet --output-document=sdk-tools.zip \
  "https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip" && \
  mkdir --parents "$ANDROID_HOME" && \
  unzip -q sdk-tools.zip -d "$ANDROID_HOME" && \
  rm --force sdk-tools.zip && \
  echo "installing ndk" && \
  wget --quiet --output-document=android-ndk.zip \
  "http://dl.google.com/android/repository/android-ndk-r${ANDROID_NDK_VERSION}-linux-x86_64.zip" && \
  mkdir --parents "$ANDROID_NDK/android-ndk-r${ANDROID_NDK_VERSION}" && \
  unzip -q android-ndk.zip -d "$ANDROID_NDK" && \
  rm --force android-ndk.zip

RUN mkdir --parents "$HOME/.android/" 
RUN echo '### User Sources for Android SDK Manager' > "$HOME/.android/repositories.cfg" 
RUN yes | "$ANDROID_HOME"/tools/bin/sdkmanager --licenses > /dev/null
RUN yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
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
RUN yes | "$ANDROID_HOME"/tools/bin/sdkmanager "platform-tools"
RUN yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
  "build-tools;24.0.0" "build-tools;24.0.1" \
  "build-tools;24.0.2" "build-tools;24.0.3" \
  "build-tools;25.0.0" "build-tools;25.0.1" "build-tools;25.0.2" "build-tools;25.0.3" \
  "build-tools;26.0.0" "build-tools;26.0.1" "build-tools;26.0.2" 
RUN yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
  "build-tools;17.0.0" \
  "build-tools;18.1.1" \
  "build-tools;19.1.0" \
  "build-tools;20.0.0" \
  "build-tools;21.1.2" \
  "build-tools;22.0.1" \
  "build-tools;23.0.1" "build-tools;23.0.2" "build-tools;23.0.3"
RUN yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
  "extras;android;m2repository" \
  "extras;google;m2repository"
RUN yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
  "extras;google;google_play_services" \
  "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.1" \
  "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2"
RUN  yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
  "add-ons;addon-google_apis-google-16" \
  "add-ons;addon-google_apis-google-17" \
  "add-ons;addon-google_apis-google-18" \
  "add-ons;addon-google_apis-google-19" \
  "add-ons;addon-google_apis-google-21" \
  "add-ons;addon-google_apis-google-22" \
  "add-ons;addon-google_apis-google-23" \
  "add-ons;addon-google_apis-google-24" 

RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh && \
  apt-get update && apt-get install git-lfs

RUN echo "[url \"git@gitlab.com:\"]\n\tinsteadOf = https://gitlab.com/" >> $USER_HOME/.gitconfig
RUN mkdir $USER_HOME/.ssh && echo "StrictHostKeyChecking no " > $USER_HOME/.ssh/config

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
  && apt-get update -y && apt-get install google-cloud-sdk -y
