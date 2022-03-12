//
//  HelperWrapper.swift
//  MediaInfo
//
//  Created by Sbarex on 06/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import os.log

class HelperWrapper: SettingsService {
    static let XPCProtocol: Protocol = MediaInfoHelperXPCProtocol.self
    static let serviceName = "org.sbarex.MediaInfoHelperXPC"
    static let connection: NSXPCConnection = HelperWrapper.initConnection()
    
    static func initSettings(connection: NSXPCConnection) -> MediaInfoSettingsXPCProtocol? {
        let service = connection.synchronousRemoteObjectProxyWithErrorHandler { error in
            os_log("MediaInfo Helper - Error: %{public}@", log: OSLog.helperXPC, type: .error, error.localizedDescription)
        } as? MediaInfoHelperXPCProtocol
        return service
    }
    
    static let service: MediaInfoSettingsXPCProtocol? = HelperWrapper.initSettings(connection: HelperWrapper.connection)
    
    static func getPDFInfo(for url: URL) -> PDFInfo? {
        let pdfInfo: PDFInfo? = Self.getInfoFromService(for: url, type: "pdf")
        return pdfInfo
    }
    
    static func getImageInfo(for url: URL) -> ImageInfo? {
        let image: ImageInfo? = Self.getInfoFromService(for: url, type: "image")
        return image
    }
    
    static func getAudioInfo(for url: URL) -> AudioInfo? {
        let audio: AudioInfo? = Self.getInfoFromService(for: url, type: "audio")
        return audio
    }

    static func getVideoInfo(for url: URL) -> VideoInfo? {
        let video: VideoInfo? = Self.getInfoFromService(for: url, type: "video")
        return video
    }
    
    static func getWordInfo(for url: URL) -> WordInfo? {
        let doc: WordInfo? = Self.getInfoFromService(for: url, type: "doc")
        return doc
    }
    
    static func getExcelInfo(for url: URL) -> ExcelInfo? {
        let xls: ExcelInfo? = Self.getInfoFromService(for: url, type: "xls")
        return xls
    }

    static func getPowerpointInfo(for url: URL) -> PowerpointInfo? {
        let ppt: PowerpointInfo? = Self.getInfoFromService(for: url, type: "ppt")
        return ppt
    }
    
    static func getOpenDocumentInfo(for url: URL) -> WordInfo? {
        let odt: WordInfo? = Self.getInfoFromService(for: url, type: "odt")
        return odt
    }
    
    static func getOpenSpreadsheetInfo(for url: URL) -> ExcelInfo? {
        let ods: ExcelInfo? = Self.getInfoFromService(for: url, type: "ods")
        return ods
    }

    static func getOpenPresentationInfo(for url: URL) -> PowerpointInfo? {
        let odp: PowerpointInfo? = Self.getInfoFromService(for: url, type: "odp")
        return odp
    }
    
    static func getModelInfo(for url: URL) -> ModelInfo? {
        let modelInfo: ModelInfo? = Self.getInfoFromService(for: url, type: "3d")
        return modelInfo
    }
    
    static func getArchiveInfo(for url: URL) -> ArchiveInfo? {
        let archiveInfo: ArchiveInfo? = Self.getInfoFromService(for: url, type: "archive")
        return archiveInfo
    }
    
    static func getFolderInfo(for url: URL) -> FolderInfo? {
        if #available(macOSApplicationExtension 11.0, *) {
            Logger.finderExtension.debug("MediaInfo FinderSync - Fetching folder info…")
        } else {
            os_log("MediaInfo FinderSync - Fetching folder info…", log: OSLog.finderExtension, type: .debug)
        }
        
        let info: FolderInfo? = Self.getInfoFromService(for: url, type: "folder")
        return info
    }
    
    static internal func getInfoFromService<T: BaseInfo>(for url: URL, type: String) -> T? {
        guard let service = Self.service as? MediaInfoHelperXPCProtocol else {
            return nil
        }
        
        let inflightSemaphore = DispatchSemaphore(value: 0)

        var info: T? = nil
        service.getInfo(for: url, type: type) { data in
            defer {
                inflightSemaphore.signal()
            }
            guard let d = data else {
                return
            }
            let data = Data(referencing: d)
            let decoder = JSONDecoder()
            do {
                info = try decoder.decode(T.self, from: data)
            } catch {
                let e = error
                os_log("MediaInfo Helper - Error: %{public}@", log: OSLog.helperXPC, type: .error, e.localizedDescription)
            }
        }
        
        if !Thread.isMainThread {
            let _ = inflightSemaphore.wait(timeout: .distantFuture)
            // print(r)
        } else {
            while inflightSemaphore.wait(timeout: .now()) == .timedOut {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0))
            }
        }
        
        return info
    }
    
    static func openFile(url: URL, reply: @escaping ((Bool) -> Void)) {
        guard let service = Self.service as? MediaInfoHelperXPCProtocol else {
            return
        }
        service.openFile(url: url, reply: reply)
    }
    
    static func openFile(url: URL, withApp path: String, reply: @escaping ((Bool, String?) -> Void)) {
        guard let service = Self.service as? MediaInfoHelperXPCProtocol else {
            return
        }
        service.openFile(url: url, withApp: path, reply: reply)
    }
    
    static func openApplication(at url: URL, reply: @escaping ((Bool, String?) -> Void)) {
        guard let service = Self.service as? MediaInfoHelperXPCProtocol else {
            return
        }
        service.openApplication(at: url, reply: reply)
    }
    
    static func systemExec(command: String, arguments: [String], reply: @escaping ((Int32, String) -> Void)) {
        guard let service = Self.service as? MediaInfoHelperXPCProtocol else {
            reply(-1, "No MediaInfo Helper XPC process available.")
            return
        }
        service.systemExec(command: command, arguments: arguments, reply: reply)
    }
}
