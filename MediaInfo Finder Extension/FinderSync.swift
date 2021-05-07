//
//  FinderSync.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 21/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    let numberFormatter = NumberFormatter()
    let byteCountFormatter = ByteCountFormatter()

    var settings: Settings = Settings(fromDict: [:])
    
    override init() {
        super.init()
        
        NSLog("MediaInfo FinderSync launched from %@", Bundle.main.bundlePath as NSString)
        
        refreshSettings()
        
        numberFormatter.allowsFloats = true
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
        
        // Set up images for our badge identifiers. For demonstration purposes, this uses off-the-shelf images.
        // FIFinderSyncController.default().setBadgeImage(NSImage(named: NSImage.colorPanelName)!, label: "Status One" , forBadgeIdentifier: "One")
        // FIFinderSyncController.default().setBadgeImage(NSImage(named: NSImage.cautionName)!, label: "Status Two", forBadgeIdentifier: "Two")
        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.handleSettingsChanged(_:)), name: .MediaInfoSettingsChanged, object: nil)
    }
    
    deinit {
        DistributedNotificationCenter.default().removeObserver(self, name: .MediaInfoSettingsChanged, object: nil)
    }
    
    func refreshSettings() {
        SettingsWrapper.getSettings() { settings in
            self.settings = settings
            
            NSLog("MediaInfo FinderSync watching folders:\n %@", settings.folders.map({ $0.path }).joined(separator: "\n"))
            // Set up the directory we are syncing.
            FIFinderSyncController.default().directoryURLs = Set(settings.folders)
        }
    }
    
    @objc func handleSettingsChanged(_ notification: Notification) {
        refreshSettings()
    }
    
    // MARK: - Primary Finder Sync protocol methods
    
    override func beginObservingDirectory(at url: URL) {
        // The user is now seeing the container's contents.
        // If they see it in more than one view at a time, we're only told once.
        NSLog("beginObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    
    override func endObservingDirectory(at url: URL) {
        // The user is no longer seeing the container's contents.
        NSLog("endObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    /*
    override func requestBadgeIdentifier(for url: URL) {
        NSLog("requestBadgeIdentifierForURL: %@", url.path as NSString)
        
        // For demonstration purposes, this picks one of our two badges, or no badge at all, based on the filename.
        let whichBadge = abs(url.path.hash) % 3
        let badgeIdentifier = ["", "One", "Two"][whichBadge]
        FIFinderSyncController.default().setBadgeIdentifier(badgeIdentifier, for: url)
    }
    */
    
    // MARK: - Menu and toolbar item support
    
    /*
    override var toolbarItemName: String {
        return "FinderSy"
    }
    
    override var toolbarItemToolTip: String {
        return "FinderSy: Click the toolbar item for a menu."
    }
    
    override var toolbarItemImage: NSImage {
        return NSImage(named: NSImage.cautionName)!
    }
    */
    
    func formatTime(_ time: TimeInterval) -> String {
        var m = Int(time / 60)
        let h = Int(TimeInterval(m) / 60)
        m -= h * 60
        let s = Int(time) - (m * 60) - (h * 3600)
        // let ms = time - TimeInterval(s + m * 60 + h * 3600)
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        if menuKind == .contextualMenuForItems {
            if let items = FIFinderSyncController.default().selectedItemURLs(), items.count == 1, let item = items.first, let uti = try? item.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                
                if settings.isImagesHandled && UTTypeConformsTo(uti as CFString, kUTTypeImage), let menu = getMenuForImage(atURL: item) {
                    return menu
                } else if settings.isMediaHandled && UTTypeConformsTo(uti as CFString, kUTTypeMovie), let menu = getMenuForVideo(atURL: item) {
                    return menu
                } else if settings.isMediaHandled && UTTypeConformsTo(uti as CFString, kUTTypeAudio), let menu = getMenuForAudio(atURL: item) {
                    return menu
                }
            }
        }
        
        return nil
    }
    
    internal func image(for mode: String) -> NSImage? {
        var img: NSImage?
        var isColor = false
        switch mode {
        case "image":
            /*
            if #available(macOSApplicationExtension 11.0, *) {
                img = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
            } else {
                img = NSImage(named: "image")
            }
 */
            img = NSImage(named: "image")
        case "image_v":
            img = NSImage(named: "image_v")
        case "color":
            img = NSImage(named: "color")
        case "color_rgb":
            img = NSImage(named: "color_rgb")
            isColor = true
        case "color_cmyk":
            img = NSImage(named: "color_cmyk")
            isColor = true
        case "color_gray":
            img = NSImage(named: "color_gray")
            isColor = true
        case "color_lab":
            img = NSImage(named: "color_lab")
            isColor = true
        case "color_bw":
            img = NSImage(named: "color_bw")
            isColor = true
        case "print":
            /*
            if #available(macOSApplicationExtension 11.0, *) {
                img = NSImage(systemSymbolName: "printer", accessibilityDescription: nil)
            } else {
                img = NSImage(named: "print")
            }
 */
            img = NSImage(named: "print")
        case "video":
            /*
            if #available(macOSApplicationExtension 11.0, *) {
                img = NSImage(systemSymbolName: "video", accessibilityDescription: nil)
            } else {
                img = NSImage(named: "video")
            }*/
            img = NSImage(named: "video")
        case "video_v":
            img = NSImage(named: "video_v")
        case "audio":
            /*
            if #available(macOSApplicationExtension 11.0, *) {
                img = NSImage(systemSymbolName: "speaker.wave.1", accessibilityDescription: nil)
            } else {
                img = NSImage(named: "audio")
            }
            */
            img = NSImage(named: "audio")
        case "text":
            /*
            if #available(macOSApplicationExtension 11.0, *) {
                img = NSImage(systemSymbolName: "captions.bubble", accessibilityDescription: nil)
            } else {
                img = NSImage(named: "txt")
            }*/
            img = NSImage(named: "txt")
        case "ratio":
            img = NSImage(named: "aspectratio")
        case "ratio_v":
            img = NSImage(named: "aspectratio_v")
        default:
            return nil
        }
        
        if !isColor {
            img?.isTemplate = true
            
            return img?.image(withTintColor: NSColor.labelColor)
        } else {
            return img
        }
    }

    internal func createMenuItem(title: String, image: String?) -> NSMenuItem {
        let mnu = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        mnu.isEnabled = true
        mnu.image = image == nil || settings.isIconHidden ? nil : self.image(for: image!)
        return mnu
    }
    
    internal func getFileSizeMenuItem(for item: URL)->NSMenuItem? {
        guard !settings.isFileSizeHidden, let attr = try? FileManager.default.attributesOfItem(atPath: item.path), let fileSize = attr[FileAttributeKey.size] as? Int64 else {
            return nil
        }
            
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB]
        bcf.countStyle = .file
        let title = bcf.string(fromByteCount: fileSize)
        return createMenuItem(title: title, image: nil)
    }
    
    internal func getRatioMenuItem(width: Int, height: Int)->NSMenuItem? {
        guard !settings.isRatioHidden else {
            return nil
        }
        var gcd = self.gcd(width, height)
        guard gcd != 1 else {
            return nil
        }
        
        var circa = false
        if !settings.isRatioPrecise, gcd < 8, let gcd1 = [self.gcd(width+1, height), self.gcd(width-1, height), self.gcd(width, height+1), self.gcd(width, height-1)].max(), gcd1 > gcd {
            gcd = gcd1 * self.gcd(width/gcd1, height / gcd1)
            circa = true
        }
        let w = width / gcd
        let h = height / gcd
        
        return createMenuItem(title: "\(circa ? "~ " : "")\(w) : \(h)", image: "ratio"+(h>w ? "_v" : ""))
    }
    
    internal func gcd(_ a: Int, _ b: Int) -> Int {
        let remainder = abs(a) % abs(b)
        if remainder != 0 {
            return gcd(abs(b), remainder)
        } else {
            return abs(b)
        }
    }
    
    internal func getResolutioNameMenuItem(width: Int, height: Int)->NSMenuItem? {
        guard !settings.isResolutionNameHidden, let res = getResolutioName(width: width, height: height) else {
            return nil
        }
        
        return createMenuItem(title: res, image: nil)
    }
        
    internal func getResolutioName(width: Int, height: Int)->String? {
        let resolutions = [
            // Narrowscreen 4:3 computer display resolutions
            "MCGA": [320, 200],
            "QVGA" : [320, 240],
            "VGA" : [640, 480],
            "Super VGA" : [800, 600],
            "XGA" : [1024, 768],
            "SXGA" : [1280, 1024],
            "UXGA" : [1600, 1200],
            
            // Analog
            "CRT monitors": [320, 200],
            "Video CD": [352, 240],
            "VHS": [333, 480],
            "Betamax": [350, 480],
            "Super Betamax": [420, 480],
            "Betacam SP": [460, 480],
            "Super VHS": [580, 480],
            "Enhanced Definition Betamax": [700, 480],
            
            // Digital
            "Digital8": [500, 480],
            "NTSC DV": [720, 480],
            "NTSC D1": [720, 486],
            "NTSC D1 Square pixel": [720, 543],
            "NTSC D1 Widescreen Square Pixel": [782, 486],
            
            "EDTV (Enhanced Definition Television)": [854, 480],
            "D-VHS, DVD, miniDV, Digital8, Digital Betacam (PAL/SECAM)": [720, 576],
            "PAL D1/DV": [720, 576],
            "PAL D1/DV Square pixel": [788, 576],
            "PAL D1/DV Widescreen Square pixel": [1050, 576],
            
            
            "HDV/HDTV 720": [1280, 720],
            "HDTV 1080": [1440, 1080],
            "DVCPRO HD 720": [960, 720],
            "DVCPRO HD 1080": [1440, 1080],
            
            "HDTV 1080 (FullHD)": [1920, 1080],
            
            // "HDV (miniDV), AVCHD, HD DVD, Blu-ray, HDCAM SR": [1920, 1080],
            "2K Flat (1.85:1)": [1998, 1080],
            "UHD 4K": [3840, 2160],
            "UHD 8K": [7680, 4320],
            "Cineon Half": [1828, 1332],
            "Cineon Full": [3656, 2664],
            "Film (2K)": [2048, 1556],
            "Film (4K)": [4096, 3112],
            "Digital Cinema (2K)": [2048, 1080],
            "Digital Cinema (4K)": [4096, 2160],
            "Digital Cinema (16K)": [15360, 8640],
            "Digital Cinema (64K)": [61440, 34560],
        ]
        return resolutions.first(where: { $1[0] == width && $1[1] == height })?.key
    }
    
    func getMenuForImage(atURL item: URL) -> NSMenu? {
        let image_info: ImageInfo
        if let info = getCGImageInfo(forFile: item) {
            image_info = info
        } else {
            guard let uti = try? item.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
                return nil
            }
            
            if UTTypeConformsTo(uti as CFString, "public.pbm" as CFString), let info = getNetPBMImageInfo(forFile: item) {
                image_info = info
            } else if UTTypeConformsTo(uti as CFString, "public.webp" as CFString), let info = getWebPImageInfo(forFile: item) {
                image_info = info
            } /*else if UTTypeConformsTo(uti as CFString, "fr.whine.bpg" as CFString) || item.pathExtension == "bpg", let info = getBPGImageInfo(forFile: item) {
                image_info = info
            } */else if UTTypeConformsTo(uti as CFString, "public.svg-image" as CFString), let info = getSVGImageInfo(forFile: item) {
                image_info = info
            } else if let info = getFFMpegImageInfo(forFile: item) {
                image_info = info
            } else if let info = getMetadataImageInfo(forFile: item) {
                image_info = info
            } else {
                return nil
            }
        }
        
        guard image_info.width > 0 || image_info.height > 0 else {
            return nil
        }
        
        let menu = NSMenu(title: "")
        menu.autoenablesItems = false
        
        let use_submenu  = settings.isInfoOnSubMenu
        let print_hidden = settings.isPrintHidden
        
        // FIXME: NSImage named with a pdf image don't respect dark theme!
        // FIXME: NSMenuItem in the extension do not preserve the image template rendering mode, delegate, attributedTitle (rendered as simple string), isAlternate, separator (render as a menu item with an empty title).
        
        let info_sub_menu = NSMenu(title: "MediaInfo")
        if use_submenu {
            let info_mnu = menu.addItem(withTitle: "MediaInfo", action: #selector(sampleAction(_:)), keyEquivalent: "")
            info_mnu.image = image(for: "image"+(image_info.height>image_info.width ? "_v" : ""))
            
            menu.setSubmenu(info_sub_menu, for: info_mnu)
        }
        var colors: [String] = []
        if !settings.isColorHidden && !image_info.colorMode.isEmpty {
            colors.append(image_info.formattedColorMode)
        }
        if !settings.isDepthHidden && image_info.depth > 0 {
            colors.append("\(image_info.depth) bit")
        }
        
        var title = "\(image_info.width) × \(image_info.height) px"
        if let animated = image_info.animated, animated {
            title += " [" + NSLocalizedString("animated", comment: "") + "]"
        }
        
        if !use_submenu && !colors.isEmpty {
            title += " " + colors.joined(separator: " ")
        }
        if print_hidden && image_info.dpi > 0 {
            title += " (\(image_info.dpi) dpi)"
        }
        let mnu = createMenuItem(title: title, image: "image"+(image_info.height>image_info.width ? "_v" : ""))
        (use_submenu ? info_sub_menu : menu).addItem(mnu)
        
        if use_submenu && settings.isInfoOnMainItem {
            menu.items.first!.title = title
        }
        
        if let mnu = getRatioMenuItem(width: image_info.width, height: image_info.height) {
            (use_submenu ? info_sub_menu : menu).addItem(mnu)
        }
        if let mnu = getResolutioNameMenuItem(width: image_info.width, height: image_info.height) {
            (use_submenu ? info_sub_menu : menu).addItem(mnu)
        }
        
        if use_submenu && !colors.isEmpty {
            let mnu = createMenuItem(title: colors.joined(separator: " "), image: image_info.color_image_name)
            info_sub_menu.addItem(mnu)
            
            if use_submenu && settings.isInfoOnMainItem {
                menu.items.first!.title += ", " + colors.joined(separator: " ")
            }
        }
        
        let unit = settings.unit
        
        let scale: Double
        let unit_label: String
        switch unit {
        case .cm:
            scale = 2.54 // cm
            unit_label = NSLocalizedString(" cm", comment: "")
        case .mm:
            scale = 25.4 // mm
            unit_label = NSLocalizedString(" mm", comment: "")
        case .inch:
            scale = 1 // inch
            unit_label = NSLocalizedString(" inch", comment: "")
        }
        
        if !print_hidden && image_info.dpi != 0, let w_cm = numberFormatter.string(from: NSNumber(value: Double(image_info.width) / Double(image_info.dpi) * scale)), let h_cm = numberFormatter.string(from: NSNumber(value: Double(image_info.height) / Double(image_info.dpi) * scale)) {
            
            let mnu = createMenuItem(title: "\(w_cm) × \(h_cm)\(unit_label) (\(image_info.dpi) dpi)", image: "print")
            (use_submenu ? info_sub_menu : menu).addItem(mnu)
        }
        
        if !settings.isCustomPrintHidden, settings.customDPI > 0 && (image_info.dpi != settings.customDPI || print_hidden), let w_cm = numberFormatter.string(from: NSNumber(value:Double(image_info.width) / Double(settings.customDPI) * scale)), let h_cm = numberFormatter.string(from: NSNumber(value:Double(image_info.height) / Double(settings.customDPI) * scale)) {
            let mnu = createMenuItem(title: "\(w_cm) × \(h_cm)\(unit_label) (\(settings.customDPI) dpi)", image: "print")
            (use_submenu ? info_sub_menu : menu).addItem(mnu)
        }
        if let mnu = getFileSizeMenuItem(for: item) {
            (use_submenu ? info_sub_menu : menu).addItem(mnu)
        }
        /*
        if use_submenu {
            info_sub_menu.addItem(NSMenuItem.separator())
            info_sub_menu.addItem(NSMenuItem(title: "Settings…", action: #selector(self.openSettings(_:)), keyEquivalent: ""))
        }
         */
        return menu
    }
    
    func getMenuForVideo(atURL item: URL) -> NSMenu? {
        var streams: [StreamType] = getCMVideoInfo(forFile: item)
        if streams.isEmpty {
            streams = getFFMpegInfo(forFile: item)
        }
        if streams.isEmpty {
            streams = getMetadataVideoInfo(forFile: item)
        }
        guard !streams.isEmpty else {
            return nil
        }
        
        let use_submenu   = settings.isInfoOnSubMenu
        let group_tracks  = settings.isTracksGrouped
        let codec_hidden  = settings.isCodecHidden
        let frames_hidden = settings.isFramesHidden
        let bps_hidden    = settings.isBPSHidden
        
        if !group_tracks {
            streams.sort(by: {$0.index < $1.index})
        }
        
        let menu = NSMenu(title: "")
        menu.autoenablesItems = false
        
        let info_sub_menu = NSMenu(title: "MediaInfo")
        if use_submenu {
            let info_mnu = menu.addItem(withTitle: "MediaInfo", action: nil, keyEquivalent: "")
            info_mnu.image = image(for: "video")
            menu.setSubmenu(info_sub_menu, for: info_mnu)
        }
        
        let mnu_video = NSMenu(title: "Video")
        let mnu_audio = NSMenu(title: "Audio")
        let mnu_text  = NSMenu(title: "Subtitle")
        
        var mainTitle = ""
        
        for stream in streams {
            switch stream {
            case .video(let width, let height, let duration, let codec, _, let lang, let bit_rate, let frames):
                var extra: [String] = []
                if !codec.isEmpty && !codec_hidden {
                    extra.append(codec)
                }
                if let lang = lang, !lang.isEmpty {
                    extra.append(lang.uppercased())
                }
                let t = formatTime(duration)
                var title = "\(width) × \(height), \(t)"
                if frames > 0 && !frames_hidden {
                    title += " (\(frames) frames)"
                }
                if bit_rate > 0 && !bps_hidden {
                    title += ", " + byteCountFormatter.string(fromByteCount: bit_rate) + "/s"
                }
                if !extra.isEmpty {
                    title += " (" + extra.joined(separator: ", ") + ")"
                }
                let mnu = createMenuItem(title: title, image: "video"+(height>width ? "_v" : ""))
                (group_tracks ? mnu_video : (use_submenu ? info_sub_menu : menu)).addItem(mnu)
                if mainTitle.isEmpty {
                    mainTitle = title
                }
                
                if let mnu = getRatioMenuItem(width: width, height: height) {
                    (group_tracks ? mnu_video : (use_submenu ? info_sub_menu : menu)).addItem(mnu)
                }
                if let mnu = getResolutioNameMenuItem(width: width, height: height) {
                    (group_tracks ? mnu_video : (use_submenu ? info_sub_menu : menu)).addItem(mnu)
                }
                
            case .audio(let duration, let codec, let lang, let bit_rate):
                var extra: [String] = []
                if !codec.isEmpty && !codec_hidden {
                    extra.append(codec)
                }
                if let lang = lang, !lang.isEmpty {
                    extra.append(lang.uppercased())
                }
                let t = formatTime(duration)
                var title = "\(t)"
                if !bps_hidden && bit_rate > 0 {
                    title += ", " + byteCountFormatter.string(fromByteCount: bit_rate) + "/s"
                }
                if !extra.isEmpty {
                    title += " (" + extra.joined(separator: ", ") + ")"
                }
                
                let mnu = createMenuItem(title:title, image: "audio")
                (group_tracks ? mnu_audio : (use_submenu ? info_sub_menu : menu)).addItem(mnu)
                
            case .subtitle(let t, let lang):
                var title = ""
                if let t = t {
                    title += t
                }
                if let lang = lang, !lang.isEmpty {
                    title += title.isEmpty ? "(\(lang.uppercased()))" : " " + lang.uppercased()
                }
                if !title.isEmpty {
                    let mnu = createMenuItem(title: title, image: "text")
                    (group_tracks ? mnu_text : (use_submenu ? info_sub_menu : menu)).addItem(mnu)
                }
                break
            default:
                break
            }
        }
        if use_submenu && settings.isInfoOnMainItem && !mainTitle.isEmpty {
            menu.items.first!.title = mainTitle
        }
        if mnu_video.items.count > 0 {
            let m = NSMenuItem(title: NSLocalizedString("Video", comment: ""), action: nil, keyEquivalent: "")
            m.image = image(for: "video")
            (use_submenu ? info_sub_menu : menu).addItem(m)
            (use_submenu ? info_sub_menu : menu).setSubmenu(mnu_video, for: m)
        }
        if mnu_audio.items.count > 0 {
            let m = NSMenuItem(title: NSLocalizedString("Audio", comment: ""), action: nil, keyEquivalent: "")
            m.image = image(for: "audio")
            (use_submenu ? info_sub_menu : menu).addItem(m)
            (use_submenu ? info_sub_menu : menu).setSubmenu(mnu_audio, for: m)
        }
        if mnu_text.items.count > 0 {
            let m = NSMenuItem(title: NSLocalizedString("Subtitle", comment: ""), action: nil, keyEquivalent: "")
            m.image = image(for: "text")
            (use_submenu ? info_sub_menu : menu).addItem(m)
            (use_submenu ? info_sub_menu : menu).setSubmenu(mnu_text, for: m)
        }
        
        if let mnu = getFileSizeMenuItem(for: item) {
            (use_submenu ? info_sub_menu : menu).addItem(mnu)
        }
        return menu
    }
    
    func getMenuForAudio(atURL item: URL) -> NSMenu? {
        var streams: [StreamType] = getCMVideoInfo(forFile: item)
        if streams.isEmpty {
            streams = getFFMpegInfo(forFile: item)
        }
        if streams.isEmpty {
            streams = getMetadataVideoInfo(forFile: item)
        }
        guard !streams.isEmpty else {
            return nil
        }
        
        let use_submenu   = settings.isInfoOnSubMenu
        let codec_hidden  = settings.isCodecHidden
        let bps_hidden    = settings.isBPSHidden
        
        let menu = NSMenu(title: "")
        menu.autoenablesItems = false
        
        let info_sub_menu = NSMenu(title: "MediaInfo")
        if use_submenu {
            let info_mnu = menu.addItem(withTitle: "MediaInfo", action: nil, keyEquivalent: "")
            info_mnu.image = image(for: "audio")
            menu.setSubmenu(info_sub_menu, for: info_mnu)
        }
        
        for stream in streams {
            switch stream {
            case .audio(let duration, let codec, let lang, let bit_rate):
                var extra: [String] = []
                if !codec.isEmpty && !codec_hidden {
                    extra.append(codec)
                }
                if let lang = lang, !lang.isEmpty {
                    extra.append(lang.uppercased())
                }
                let t = formatTime(duration)
                var title = "\(t)"
                if !bps_hidden && bit_rate > 0 {
                    title += ", " + byteCountFormatter.string(fromByteCount: bit_rate) + "/s"
                }
                if !extra.isEmpty {
                    title += " (" + extra.joined(separator: ", ") + ")"
                }
                
                let mnu = createMenuItem(title:title, image: "audio")
                (use_submenu ? info_sub_menu : menu).addItem(mnu)
            default:
                break
            }
        }
        
        if use_submenu && settings.isInfoOnMainItem, info_sub_menu.items.count > 0 {
            menu.items.first!.title = info_sub_menu.items.first!.title
            if info_sub_menu.items.count == 1 {
                menu.setSubmenu(nil, for: menu.items.first!)
            }
        }
        
        if let mnu = getFileSizeMenuItem(for: item) {
            (use_submenu ? info_sub_menu : menu).addItem(mnu)
        }
        
        return menu
    }
    
    @IBAction func openSettings(_ sender: AnyObject?) {
        FIFinderSyncController.showExtensionManagementInterface()
    }
    
    @IBAction func sampleAction(_ sender: AnyObject?) {
        /*
        let target = FIFinderSyncController.default().targetedURL()
        let items = FIFinderSyncController.default().selectedItemURLs()
        
        let item = sender as! NSMenuItem
        NSLog("sampleAction: menu item: %@, target = %@, items = ", item.title as NSString, target!.path as NSString)
        for obj in items! {
            NSLog("    %@", obj.path as NSString)
        }
        */
    }
}

extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension NSImage {
   func image(withTintColor tintColor: NSColor) -> NSImage {
       guard isTemplate else { return self }
       guard let copiedImage = self.copy() as? NSImage else { return self }
       copiedImage.lockFocus()
       tintColor.set()
       let imageBounds = NSMakeRect(0, 0, copiedImage.size.width, copiedImage.size.height)
       imageBounds.fill(using: .sourceAtop)
       copiedImage.unlockFocus()
       copiedImage.isTemplate = false
       return copiedImage
   }
}
