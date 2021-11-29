//
//  HelperWrapper.swift
//  MediaInfo
//
//  Created by Sbarex on 06/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa


class HelperWrapper: SettingsService {
    static let XPCProtocol: Protocol = MediaInfoHelperXPCProtocol.self
    static let serviceName = "org.sbarex.MediaInfoHelperXPC"
    static let connection: NSXPCConnection = HelperWrapper.initConnection()
    
    static func initSettings(connection: NSXPCConnection) -> MediaInfoSettingsXPCProtocol? {
        let service = connection.synchronousRemoteObjectProxyWithErrorHandler { error in
            NSLog("\(HelperWrapper.serviceName) error: %@", error.localizedDescription)
            print("Received error:", error)
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
            let u: NSKeyedUnarchiver
            do {
                u = try NSKeyedUnarchiver(forReadingFrom: data)
            } catch {
                return
            }
            info = T(coder: u)
        }
        
        if !Thread.isMainThread {
            let r = inflightSemaphore.wait(timeout: .distantFuture)
            print(r)
        } else {
            while inflightSemaphore.wait(timeout: .now()) == .timedOut {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0))
            }
        }
        
        return info
    }
    
    static func openFile(url: URL) {
        guard let service = Self.service as? MediaInfoHelperXPCProtocol else {
            return
        }
        service.openFile(url: url)
    }
}
