#!/bin/bash
export PATH="$HOME/BlueBubbles-Alpha-Build/toolchain/flutter/bin:$HOME/BlueBubbles-Alpha-Build/toolchain/jdk21/Contents/Home/bin:$HOME/BlueBubbles-Alpha-Build/toolchain/gradle-8.14/bin:$PATH"
export JAVA_HOME="$HOME/BlueBubbles-Alpha-Build/toolchain/jdk21/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"; export ANDROID_SDK_ROOT="$ANDROID_HOME"
cd "$HOME/BlueBubbles-Alpha-Build/readrace-test"
echo "start $(date -u +%H:%M:%S)"
flutter build apk --flavor alpha --release --build-name=2.1.1-daily.26 --build-number=40004117
RC=$?
echo "exit=$RC end $(date -u +%H:%M:%S)"
if [ $RC = 0 ]; then mkdir -p "$HOME/BlueBubbles-Alpha-Build/artifacts/daily.26" && cp build/app/outputs/flutter-apk/app-alpha-release.apk "$HOME/BlueBubbles-Alpha-Build/artifacts/daily.26/BlueBubbles-alpha-2.1.1-daily.26.apk"; fi
echo DONE
