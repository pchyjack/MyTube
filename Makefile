export ARCHS = arm64
export TARGET = iphone:clang:latest:15.0
# Dopamine is rootless: files install under /var/jb
export THEOS_PACKAGE_SCHEME = rootless

INSTALL_TARGET_PROCESSES = MyTube

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MyTube

MyTube_FILES = main.m AppDelegate.m Theme.m Library.m Controllers.m
MyTube_FRAMEWORKS = UIKit Foundation CoreGraphics CoreMedia AVFoundation AVKit MediaPlayer
MyTube_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
