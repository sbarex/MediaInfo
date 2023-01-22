Changelog
=======


### 1.7.1 (21)
New features:
- Audio sample rate.
- Dependencies updated:
    - ffmpeg from 4.4 to 5.1.2
    - libwebp from 1.2.1 to 1.3.0
    - libarchive from 3.5.2 to 3.6.2
    - libpng from 1.6.38 to 1.6.40
    - libjpeg-turbo from 2.1.3 to 2.1.5
    - lz4 from 1.9.3 to 1.9.4
    - xz from 5.3.2alpha to 5.4.1
    - zstd from 1.5.2 to 1.5.3

Bugfix:
- Support for Xcode 14 
- Fixed some tags not displaying


### 1.7.0 (20)
New features:
- Support for folders and bundles.
- Support for handle custom file types.
- Ability to execute an external command while generating the menu. 
- Support for these properties:
  - Allocated file size (with medatata and resource fork).
  - UTI, UTI description and UTI conforms to Type.
  - File modes and ACL.
  - Extended attributes.
  - Archive compression summary and ratio.
  - Responsive status per svg files.
  - Total number of pixel (for images and videos).
- Option for format bytes and bits in decimal format (power of 1000).
- Custom action to reveal file in the Finder.
- New images: folder, info, exclamationmark, person_n, person_y, group_n, group_y, people.
- Changed the convention to enable access to the metadata from a script.
- New settings format.
- Minimun system requirements: macOS 10.15.

Bugfix:
- Better support for archive files.
- Fixed the size for files smaller than one Kb. 
- Fixed external disk support.
- Fixed the bps formatting.


### 1.6.1 (19)
New features:
- Support for these properties:
  - file creation date
  - file modification date
  - file last access date 
- New special menu items:
  - Open with the default app
  - Open with a specific app
  - Copy path to the clipboard
  - Open the MediaInfo app to change the settings
  - About MediaInfo
- Option to genarate menu items from code that execute custom actions.
- Option to define a script to handle the menu action.
- New images: calendar, flag, gear, script, clipboard and option to use the current file icon.

Bugfix:
- Better UI and code cleanup.
- Fixed bug on the FFMpeg duration extraction.


### 1.6.0 (18)
New features:
- New supported files:
  - Compressed archive files
  - Adobe Illustrator `.ai` files (as _PDF_)
  - Video `.trec` files (Camtasia recording)
- New image properties:
  - Profile name
  - Alpha channel
  - Metadata from Exif
- Support to customize the menu items with a javascript code.
- Support for auto monitor external disk.
- Sparkle updated to release 2.0.

Bugfix:
- Bugfix on menu sanification.
- Bugfix for open selected file.


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
