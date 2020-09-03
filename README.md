#  MediaInfo - MacOS Finder sync extension

This extension display information about multimedia files (images, videos and sounds) in the Finder contextual menu.
Information is shown only for files within the monitored folders (and their subfolders).

The application can customize the properties to be shown inside the contextual menu and the monitored folders.

![Folder settings](settings_folder.png)

![Image settings](settings_image.png)

![Media settings](settings_media.png)

![Media settings](menu_image.png)

![Media settings](menu_video.png)

After downloading of the release App (or compiling it from source code), you need to launch it and set the monitored folders. So you need to enable the relative Finder Sync Extension on the System Preferences / Extensions.

## Images
Show these properties:
- size (in pixel)
- resolution (dpi)
- color mode (RGB, CMYK, GRAYSCALE)
- number of bit
- print size (you can also set custom dpi resolution)


Supported image formats:
- images handled by the OS via CoreGraphics
- pbm format
- ~~bpg format via `libbpg`~~ (libbpg use a customized libavcodec that conflict with standard ffmpeg library).
- webp with `libwebp`
- svg files
- images handled by `ffmpeg`

## Audio and Videos
Show these properties:
- info abour single stream (video, audio, subtitle)
- size (in pixel)
- codec
- bit rate
- duration
- number of frames

Not all properties are always available, depending on the type of file and the library used to decode it.


Supported audio/video format:
- audio and video handled by the OS via CoreMedia
- audio and video supported by `ffmpeg` library


FFMpeg and WebP libraries are linked inside the extension and do not require another dependency.


This extension is spired by the quicklook generator [qlImageSize](https://github.com/Nyx0uf/qlImageSize).


## Note about compiling ffmpeg
Download the source file of [ffmpeg](http://ffmpeg.org/download.html).
Inside the ffmpeg source folder do:
```
$  ./configure --enable-static --enable-gpl --enable-nonfree --prefix=/Users/Shared/ffmpeg --disable-asm --disable-programs --disable-ffprobe --disable-doc --disable-htmlpages --disable-manpages --disable-podpages --disable-txtpages  --enable-libx264 --enable-libx265
$ make
$ make install
```

On the Xcode project inport the include folder and link the libraries.

Arguments to pass to cc to link the ffmpeg library:

`-g -I/Users/Shared/ffmpeg/include -lz -lbz2 -L/Users/Shared/ffmpeg/lib -lavcodec -liconv -lm -L/usr/lib/ -llz  -ldl -lpthread -lavutil -framework AudioToolbox -framework VideoToolbox -framework CoreFoundation  -framework CoreMedia -framework CoreVideo -framework CoreServices -framework OpenGL  -framework CoreImage -framework AppKit -lavformat -framework Security -lavfilter -lswresample`

