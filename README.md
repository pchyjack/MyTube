# MyTube

An iOS 6-styled, YouTube-client-style app that lists and plays the videos stored on your device
(the ones in the Videos / TV app). Built for rootless jailbreaks (Dopamine) on iOS 15.x. It never
touches the network.

Tabs: Featured (newest first), Most Viewed, Search, Bookmarks, More.
Video page: poster frame, title, channel (the file's Artist), views, description (the file's Comments
field), bookmark button and "More from <channel>".

## Getting the .deb

I could not compile this in the sandbox it was written in, so the .deb has to be built from this source.

### Option A: GitHub Actions (no local setup)
1. Create a GitHub repo and push this folder to it.
2. Open the Actions tab, run "Build MyTube .deb".
3. Download the `MyTube-deb` artifact: it contains `com.local.mytube_1.0.0_iphoneos-arm64.deb`.

### Option B: Theos on a Mac / Linux / WSL
1. Install Theos (https://theos.dev/docs/installation) and put an iOS 15 SDK in `$THEOS/sdks`.
2. In this folder run: `make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless`
3. The .deb appears in `packages/`.

## Installing on the iPod
Copy the .deb over (Filza, SSH/scp, AirDrop) and install it with Sileo/Zebra, or over SSH:

    dpkg -i com.local.mytube_1.0.0_iphoneos-arm64.deb
    uicache -p /var/jb/Applications/MyTube.app

Open MyTube and allow access to Media & Apple Music when asked.

## Notes
- Only videos with a local file are shown. DRM-protected purchases have no playable file URL and are skipped.
- If your videos don't appear, check they show up in the Videos app and tap More > Rescan Library.
- Bundle id: `com.local.mytube`. Change it in `control` and `Resources/Info.plist` if you like.
- `tools/make_icon.py` regenerates the icon.
