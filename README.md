# gitlab-ci-react-native-android
This Docker image contains react-native and the Android SDK and most common packages necessary for building Android apps in a CI tool like GitLab CI.

Whenever a new commit is pushed, a new image is automatically built on docker hub as (branch develop):

simonsimya/gitlab-ci-react-native-android:latest

To debug this image locally, create and run a container like this:

docker run -i -t -v ~/.ssh/id_rsa:/root/.ssh/id_rsa simonsimya/gitlab-ci-react-native-android:latest /bin/bash

This will download the latest image from docker hub and lets you access it via bash.