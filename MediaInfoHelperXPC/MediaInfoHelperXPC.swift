//
//  MediaInfoHelperXPC.swift
//  MediaInfoHelperXPC
//
//  Created by Sbarex on 25/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

class MediaInfoHelperXPC: MediaInfoSettingsXPC, MediaInfoHelperXPCProtocol {
    func getInfo(for item: URL, type: String, withReply reply: @escaping (NSData?)->Void) {
        switch type {
        case "image":
            getImageInfo(for: item, withReply: reply)
        case "video":
            getVideoInfo(for: item, withReply: reply)
        case "audio":
            getAudioInfo(for: item, withReply: reply)
        
        case "pdf":
            getPDFInfo(for: item, withReply: reply)
        
        case "doc":
            getWordInfo(for: item, withReply: reply)
        case "xls":
            getExcelInfo(for: item, withReply: reply)
        case "ppt":
            getPowerpointInfo(for: item, withReply: reply)
        
        case "odt":
            getOpenDocumentInfo(for: item, withReply: reply)
        case "ods":
            getOpenSpreadsheetInfo(for: item, withReply: reply)
        case "odp":
            getOpenPresentationInfo(for: item, withReply: reply)
        
        case "3d":
            getModelInfo(for: item, withReply: reply)
        
        case "archive":
            getArchiveInfo(for: item, withReply: reply)
            
        case "folder":
            getFolderInfo(for: item, withReply: reply)
            
        default:
            reply(nil)
        }
    }
    
    func getImageInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let image_info: ImageInfo
        let settings = self.settings ?? self.getSettings()
        
        if let info = getCGImageInfo(forFile: item, processMetadata: settings.extractImageMetadata) {
            image_info = info
        } else {
            guard let uti = try? item.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
                reply(nil)
                return
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
                reply(nil)
                return
            }
        }
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(image_info)
        reply(data as NSData?)
    }
    
    func getVideoInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
    
        var video: VideoInfo?
        for engine in settings.engines {
            switch engine {
            case .coremedia:
                if let v = getCMVideoInfo(forFile: item) {
                    video = v
                }
            case .ffmpeg:
                if let v = getFFMpegVideoInfo(forFile: item) {
                    video = v
                }
            case .metadata:
                if let v = getMetadataVideoInfo(forFile: item) {
                    video = v
                }
            }
            if video != nil {
                break
            }
        }
        
        guard let video = video else {
            reply(nil)
            return
        }
        let encoder = JSONEncoder()
        let data = try? encoder.encode(video)
        reply(data as NSData?)
    }
    
    func getAudioInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        
        var audio: AudioInfo?
        for engine in settings.engines {
            switch engine {
            case .coremedia:
                if let a = getCMAudioInfo(forFile: item) {
                    audio = a
                }
            case .ffmpeg:
                if let a = getFFMpegAudioInfo(forFile: item) {
                    audio = a
                }
            case .metadata:
                if let a = getMetadataAudioInfo(forFile: item) {
                    audio = a
                }
            }
            if audio != nil {
                break
            }
        }
        
        guard let audio = audio else {
            reply(nil)
            return
        }
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(audio)
        reply(data as NSData?)
    }
    
    func getPDFInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        guard let pdf = CGPDFDocument(item as CFURL) else {
            reply(nil)
            return
        }
        let pdf_info = PDFInfo(file: item, pdf: pdf)
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(pdf_info)
        reply(data as NSData?)
    }
    
    func getWordInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        guard let doc_info = WordInfo(docx: item, deepScan: settings.isOfficeDeepScan) else {
            reply(nil)
            return
        }
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(doc_info)
        reply(data as NSData?)
    }
    
    func getExcelInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        guard let xls_info = ExcelInfo(xlsx: item, deepScan: settings.isOfficeDeepScan) else {
            reply(nil)
            return
        }
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(xls_info)
        reply(data as NSData?)
    }
    
    func getPowerpointInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        guard let xppt_info = PowerpointInfo(pptx: item, deepScan: settings.isOfficeDeepScan) else {
            reply(nil)
            return
        }
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(xppt_info)
        reply(data as NSData?)
    }
    
    func getOpenDocumentInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        guard let odt_info = WordInfo(odt: item, deepScan: settings.isOfficeDeepScan) else {
            reply(nil)
            return
        }
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(odt_info)
        reply(data as NSData?)
    }
    
    func getOpenSpreadsheetInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        guard let ods_info = ExcelInfo(ods: item, deepScan: settings.isOfficeDeepScan) else {
            reply(nil)
            return
        }
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(ods_info)
        reply(data as NSData?)
    }
    
    func getOpenPresentationInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let settings = self.settings ?? self.getSettings()
        guard let odp_info = PowerpointInfo(odp: item, deepScan: settings.isOfficeDeepScan) else {
            reply(nil)
            return
        }
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(odp_info)
        reply(data as NSData?)
    }
    
    func getModelInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        if #available(macOS 11.0, *) {
            guard let model_info = ModelInfo(parseModel: item) else {
                reply(nil)
                return
            }
            
            let encoder = JSONEncoder()
            let data = try? encoder.encode(model_info)
            reply(data as NSData?)
        } else {
            reply(nil)
        }
    }
    
    func getArchiveInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        guard let archive_info = try? ArchiveInfo(file: item, limit: self.settings?.archiveMaxFiles ?? 0) else {
            reply(nil)
            return
        }
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(archive_info)
        reply(data as NSData?)
    }
    
    func getFolderInfo(for item: URL, withReply reply: @escaping (NSData?)->Void) {
        let info = FolderInfo(
            folder: item,
            maxFiles: self.settings?.folderMaxFiles ?? 200,
            maxDepth: self.settings?.folderMaxDepth ?? 10,
            maxFilesInDepth: self.settings?.folderMaxFilesInDepth ?? 50,
            skipHidden: self.settings?.folderSkipHiddenFiles ?? true,
            skipBundle: !(self.settings?.isBundleHandled ?? false),
            useGenericIcon: self.settings?.folderUsesGenericIcon ?? true,
            sizeMode: self.settings?.folderSizeMethod ?? .fast
        )
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(info)
        reply(data as NSData?)
    }
    
    
    func openFile(url: URL, reply: ((Bool)->Void)) {
        let r = NSWorkspace.shared.open(url)
        reply(r)
    }
    
    func openFile(url: URL, withApp path: String, reply: @escaping ((Bool, String?)->Void)) {
        guard !path.isEmpty else {
            reply(false, nil)
            return
        }
        if #available(macOS 10.15, *) {
            let conf = NSWorkspace.OpenConfiguration()
            conf.activates = true
            NSWorkspace.shared.open([url], withApplicationAt: URL(fileURLWithPath: path), configuration: conf) { app, error in
                reply(app != nil, error?.localizedDescription)
            }
        } else {
            systemExec(command: "/usr/bin/open", arguments: ["-a", path, url.path]) { status, output in
                reply(status == 0, status != 0 ? output : nil)
            }
        }
    }
    
    func openApplication(at url: URL, reply: @escaping ((Bool, String?)->Void)) {
        if #available(macOS 10.15, *) {
            let conf = NSWorkspace.OpenConfiguration()
            conf.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: conf) { app, error in
                reply(app != nil, error?.localizedDescription)
            }
        } else {
            systemExec(command: "/usr/bin/open", arguments: ["-a", url.path]) { status, output in
                reply(status == 0, status != 0 ? output : nil)
            }
        }
    }
    
    func systemExec(command: String, arguments: [String], reply: @escaping ((Int32, String)->Void)) {
        let task = Process()
        let pipe = Pipe()
        
        task.terminationHandler = { _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)!
            let status = task.terminationStatus
            reply(status, output)
        }
        
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.arguments = arguments
        task.launchPath = command
        do {
            try task.run()
        } catch {
            reply(-1, error.localizedDescription)
        }
    }
    
    func getWebPVersion(reply: @escaping (String)->Void) {
        let v = WebPGetDecoderVersion()
        reply(String(format:"%02X", v))
    }
}
