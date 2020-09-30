#
# GitLab CI react-native-android v0.1
#
# https://hub.docker.com/r/webcuisine/gitlab-ci-react-native-android/
# https://github.com/cuisines/gitlab-ci-react-native-android
#

FROM ubuntu:18.04

RUN apt-get -qq update && \
    apt-get install -qqy --no-install-recommends \
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
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "Android SDK 28.0.3"
ENV VERSION_SDK_TOOLS "4333796"
ENV BUILD_TOOLS="26.0.0"
ENV ANDROID_PLATFORM="android-25"

ENV USER_HOME "/root"
RUN echo "ANDROID_HOME: $USER_HOME/sdk"
ENV ANDROID_HOME $USER_HOME/sdk
ENV PATH "$PATH:${ANDROID_HOME}/tools"
ENV DEBIAN_FRONTEND noninteractive

ENV NVM_DIR /usr/local/nvm
ENV NVM_VERSION v0.33.11
ENV NODE_VERSION v10.18.1

ENV GRADLE_HOME /opt/gradle
ENV GRADLE_VERSION 4.6

RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure

RUN echo "Installing Sudo" \
  && apt-get update && apt-get install sudo

RUN echo "Installing inotify" \
  && sudo apt-get install -y inotify-tools

RUN curl -s https://dl.google.com/android/repository/sdk-tools-linux-${VERSION_SDK_TOOLS}.zip > $USER_HOME/sdk.zip && \
    unzip $USER_HOME/sdk.zip -d $USER_HOME/sdk && \
    rm -v $USER_HOME/sdk.zip

RUN mkdir -p $ANDROID_HOME/licenses/ \
  && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_HOME/licenses/android-sdk-license \
  && echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license

ADD packages.txt $USER_HOME/sdk
RUN mkdir -p $USER_HOME/.android && \
  touch $USER_HOME/.android/repositories.cfg && \
  ${ANDROID_HOME}/tools/bin/sdkmanager --update

RUN while read -r package; do PACKAGES="${PACKAGES}${package} "; done < $USER_HOME/sdk/packages.txt && \
    ${ANDROID_HOME}/tools/bin/sdkmanager ${PACKAGES}

RUN ${ANDROID_HOME}/tools/bin/sdkmanager "emulator" "build-tools;${BUILD_TOOLS}" "platforms;${ANDROID_PLATFORM}" "system-images;${ANDROID_PLATFORM};google_apis;x86_64"

RUN echo no | ${ANDROID_HOME}/tools/bin/avdmanager create avd -n "Android" -k "system-images;${ANDROID_PLATFORM};google_apis;x86_64" \
  && ln -s ${ANDROID_HOME}/tools/emulator /usr/bin \
  && ln -s ${ANDROID_HOME}/platform-tools/adb /usr/bin

RUN echo "Installing Yarn Deb Source" \
	&& curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
	&& echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN mkdir $NVM_DIR

RUN echo "Installing NVM" \
	&& curl -o- https://raw.githubusercontent.com/creationix/nvm/$NVM_VERSION/install.sh | bash

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH

RUN echo "source $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default" | bash

ENV BUILD_PACKAGES git yarn build-essential imagemagick librsvg2-bin ruby ruby-dev wget libcurl4-openssl-dev
RUN echo "Installing Additional Libraries" \
	 && rm -rf /var/lib/gems \
	 && apt-get update && apt-get install $BUILD_PACKAGES -qqy --no-install-recommends

RUN echo "Installing Fastlane 2.61.0" \
	&& gem install fastlane badge -N \
	&& gem cleanup

RUN echo "Downloading Gradle" \
	&& wget --no-verbose --output-document=gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

RUN echo "Installing Gradle" \
	&& unzip gradle.zip \
	&& rm gradle.zip \
	&& mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
	&& ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle

# Install specific bundler version as we use fastlane and specify the bundler version in the Gemfile.lock in multiple projects
RUN echo "Installing Bundler 2.0.1" \
	&& gem install bundler -v 2.0.1

RUN echo "Install zlib1g-dev for Bundler" \
  && apt-get install -qqy --no-install-recommends \
  zlib1g-dev

# Install firebase-tools
ENV FIREBASE_CLI_PATH /usr/local/bin/firebase
RUN echo "Install firebase-tools" \
  && curl -sL https://firebase.tools | bash

# Install Watchman
ENV WATCHMAN_VERSION=4.9.0
RUN echo "Install Watchman" && \
  apt-get update && apt-get install -qqy --no-install-recommends libssl-dev pkg-config libtool curl ca-certificates build-essential autoconf python-dev libpython-dev autotools-dev automake && \
  curl -LO https://github.com/facebook/watchman/archive/v${WATCHMAN_VERSION}.tar.gz && \
  tar xzf v${WATCHMAN_VERSION}.tar.gz && rm v${WATCHMAN_VERSION}.tar.gz && \
  cd watchman-${WATCHMAN_VERSION} && ./autogen.sh && ./configure && make && make install && \
  cd /tmp && rm -rf watchman-${WATCHMAN_VERSION}

RUN echo "Install Git LFS" && \
  curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh && \
  apt-get update && apt-get install git-lfs

#Clone via ssh instead of http
#This is used for libraries that we clone from a private gitlab repo.
#Setup see here https://divan.github.io/posts/go_get_private/
RUN echo "[url \"git@gitlab.com:\"]\n\tinsteadOf = https://gitlab.com/" >> $USER_HOME/.gitconfig
RUN mkdir /root/.ssh && echo "StrictHostKeyChecking no " > $USER_HOME/.ssh/config

#Add user into Git Config
RUN git config --global user.email server@simyasolutions.com
RUN git config --global user.name "CI Server"

#Install gcloud for Firebase Testlab
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y

RUN npm install -g eslint

#Install Node Firestore-import-export for Courtly
RUN yarn global add node-firestore-import-export

#Install Ionic dependencies
RUN npm install -g @ionic/cli
RUN npm install -g cordova
RUN npm install -g @angular/cli
