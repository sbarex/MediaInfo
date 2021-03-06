Changelog
=======

### 1.5.4
- Add info about number of audio channels.
- Bugfix tracks (audio, video, subtitle) menu.
- Experimental support for macOS 10.14.

### 1.5.3
- Bugfix for chapters.

### 1.5.2
- Bugfix on ratio. 
- Bugfix of ffmpeg and metadata engine disabled.
- Bugfix for unhandled nil exception.

### 1.5.1
- Bugfix on image print size. 

### 1.5
- New user interface.
- Customization of all menu items.
- Support for PDF files.
- Support for Office files (`.docx`, `.xlsx`, `.pptx`, `.odt`, `.ods`, `.odp`).
- Choice of priority of multimedia engines.
- Support for monitored folders within external disks (disk images, external or network disks).
- Fixed Finder Extension caption.

### 1.0.0

- Universal binary support (_but `ffmpeg` for arm64 is compiled on intel platform without assembly optimizations_).
- Support for automatic Sparkle update.
- New app icon.
- Removed App Group capability to handle the settings (App Group _require_ code sign). Settings are now handled with an XPC service.

### 1.0.b11

- Video and images icon on the menu respect the orientation (landscape / portrait).
- Color menu icon for the different color space.
- Allow you to show an approximate ratio when the value is not optimal.   

### 1.0.b10

- Support for _ratio_, _resolution name_ and _file size_ menu item.
- Reorganized some settings UI.
- FFMpeg updated to release 4.4.
- Removed support of `libbpg`.

### 1.0.b9

- Bugfix on video menu.
- Removed unused image assets.

### 1.0.b8

- Support to view main info on the submenu title.
- Many bugfix.

### 1.0.b7

- Add info about image animation.

### 1.0.b6

- Fix compilation settings to handle Xcode archive build.

### 1.0.b5

- New code to handle settings.
- WARNING: require to reset the settings.

### 1.0.b4

- Integrated build of ffmpeg library.
- Integrated build of webp library.
- Fallback code to handle BPG image without decode the data but parsing only the header file.

### 1.0.b3

- Typo in readme.

### 1.0.b2

- Added the code to get the info from file metadata for system supported formats.
