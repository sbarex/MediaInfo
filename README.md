#  MediaInfo - MacOS Finder Sync Extension

Extension to display information about multimedia files (images, videos and audio) in the Finder contextual menu.

> **MediaInfo is distributed in the hope that it will be useful but WITHOUT ANY WARRANTY.**

![contextual menu](menu.png)

## Installation

Head over to the [releases](https://github.com/sbarex/MediaInfo/releases) page to view the latest version. 

Move the downloaded app on your Applications folder and launch it to set the monitored folders and the other settings. Then you need to enable the associated Finder Sync Extension on the System Preferences / Extensions.

![System preferences/Extensions](extensions.png)

Now right click (or `control` click) on an image or video within a monitored folder to see the contextual menu with the media information.

| Image menu | Video Menu |
|:---------|:--------- |
| ![Image settings](menu_image.png) | ![Media settings](menu_video.png) |


**The precompiled app is not notarized or signed.**

When you download the precompiled app directly you must strip quarantine flag.

You can launch the app with right click (or ctrl click) on the app icon and choosing the open action.

Also you can execute this command from the terminal:

```
$ xattr -r -d com.apple.quarantine "FULL PATH OF THE MediaInfo .app (you can drag the file to get the pull path)"
```

Alternatively you can open System Preferences > Security & Privacy > General (tab) then clicking the `Open Anyway` button.

This will resolve the error of an unsigned application when launching the app.


## Settings

With the Application you can customize the monitored folders and the properties to be shown inside the contextual menu.

**Information about media files is shown only for files within the monitored folders (and their subfolders).**

![Folder settings](settings_folder.png)

The _General_ tab allow to set some common options:

![General settings](settings_general.png)


### Images

![Image settings](settings_image.png)

Available information:
- size (in pixel)
- aspect ratio
- resolution (dpi)
- resolution name (as _VGA_, _FullHD_, …)
- color mode (_RGB_, _CMYK_, _GRAYSCALE_, …)
- number of bit
- animation
- printed size (you can also set custom dpi resolution)


Supported image formats:
- images handled by the MacOS via CoreGraphics
- `.webp` with `libwebp`
- `.svg` files
- images handled by `ffmpeg`
- `.pbm` formats
- `.bpg` format (parsing the file header).


### Video and Audio files

![Media settings](settings_media.png)

Available information:
- info about single stream (video, audio, subtitle)
- size (in pixel)
- aspect ratio
- resolution name (as _VGA_, _FullHD_, …)
- codec
- bit rate
- duration
- number of frames

Not all properties are always available, depending on the type of file and the library used to decode it.

Supported audio/video format:
- audio and video handled by the MacOS via CoreMedia
- audio and video supported by `ffmpeg` library.


## Build from source

Clone the repository (do not download the source code because break the required git submodule):

```sh
git clone https://github.com/sbarex/MediaInfo.git 
```

then open the Xcode project, change the signing team and build. First time the build process can be slow due to the compilation of `ffmpeg`.

The required `FFMpeg` and `WebP` libraries are linked inside the extension and compiled within Xcode, so no others external dependency are required.


## Credits

Developed by [sbarex](https://github.com/sbarex) with :heart:.

This application uses these libraries: 
- [FFMpeg](https://www.ffmpeg.org/)
- [WebP](https://developers.google.com/speed/webp/)

This application was inspired by the Quick Look Generator [qlImageSize](https://github.com/Nyx0uf/qlImageSize).
