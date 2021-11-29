//
//  MediaInfoHelperXPCProtocol.swift
//  MediaInfoHelperXPC
//
//  Created by Sbarex on 25/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

@objc public protocol MediaInfoHelperXPCProtocol: MediaInfoSettingsXPCProtocol {
    func getInfo(for item: URL, type: String, withReply reply: @escaping (NSData?)->Void)
    
    func getImageInfo(for item: URL, withReply reply: @escaping (NSData?)->Void)
    func getAudioInfo(for item: URL, withReply reply: @escaping (NSData?)->Void)
    func getVideoInfo(for item: URL, withReply reply: @escaping (NSData?)->Void)
    
    func getPDFInfo(for item: URL, withReply reply: @escaping (NSData?)->Void)
    
    func getWordInfo(for item: URL, withReply reply: @escaping (NSData?)->Void)
    func getExcelInfo(for item: URL, withReply reply: @escaping (NSData?)->Void)
    func getPowerpointInfo(for item: URL, withReply reply: @escaping (NSData?)->Void)
    
    func getOpenDocumentInfo(for item: URL, withReply reply: @escaping (NSData?)->Void)
    func getOpenSpreadsheetInfo(for item: URL, withReply reply: @escaping (NSData?)->Void)
    func getOpenPresentationInfo(for item: URL, withReply reply: @escaping (NSData?)->Void)
    
    func getModelInfo(for item: URL, withReply reply: @escaping (NSData?)->Void)
    
    func openFile(url: URL)
}
