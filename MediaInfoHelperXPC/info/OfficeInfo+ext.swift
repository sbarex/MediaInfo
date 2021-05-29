//
//  OpenOfficeInfo+ext.swift
//  MediaInfo Helper XPC
//
//  Created by Sbarex on 25/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation
import ZIPFoundation
import Kanna

extension BaseOfficeInfo {
    static let officeNamespaces: [String: String] = [
        "dc":  "http://purl.org/dc/elements/1.1/",
        "cp": "http://schemas.openxmlformats.org/package/2006/metadata/core-properties",
        "dcterms": "http://purl.org/dc/terms/",
        
        "ns": "http://schemas.openxmlformats.org/officeDocument/2006/extended-properties",
        "xls": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
        "w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
    ]
    
    static func parseOfficeCoreXML(archive: Archive) throws -> [String: AnyHashable?] {
        // core.xml
        // cp:lastPrinted: 2021-03-24T13:34:00Z
        // cp:revision: 12
        
        guard let entry = archive["docProps/core.xml"] else {
            return [:]
        }
        var result: [String: AnyHashable?] = [:]
        var s = ""
        _ = try archive.extract(entry, skipCRC32: true) { data in
            s += String(data: data, encoding: .utf8) ?? ""
        }
        
        let core = try Kanna.XML(xml: s, encoding: .utf8)
            
        result["creator"] = core.at_xpath("//dc:creator", namespaces: Self.officeNamespaces)?.text
        result["title"] = core.at_xpath("//dc:title", namespaces: Self.officeNamespaces)?.text
        result["subject"] = core.at_xpath("//dc:subject", namespaces: Self.officeNamespaces)?.text
        result["description"] = core.at_xpath("//dc:description", namespaces: Self.officeNamespaces)?.text
        result["keywords"] = core.at_xpath("//cp:keywords", namespaces: Self.officeNamespaces)?.text?.split(separator: ",").map({ String($0).trimmingCharacters(in: .whitespaces) }).filter({!$0.isEmpty})
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let d = core.at_xpath("//dcterms:created", namespaces: Self.officeNamespaces)?.text {
            result["creationDate"] = dateFormatter.date(from:d)
        }
        if let d = core.at_xpath("//dcterms:modified", namespaces: Self.officeNamespaces)?.text {
            result["modifiedDate"] = dateFormatter.date(from:d)
        }
        
        if let lastModifiedBy = core.at_xpath("//cp:lastModifiedBy", namespaces: Self.officeNamespaces)?.text {
            result["lastModifiedBy"] = lastModifiedBy
        }
        
        return result
    }
    
    static func parseXMLText<T:LosslessStringConvertible>(doc: Kanna.XMLDocument, query: String) -> T? {
        if let i = doc.at_xpath(query, namespaces: Self.officeNamespaces)?.text, let n = T(i) {
            return n
        } else {
            return nil
        }
    }
    static func parseXMLText<T:LosslessStringConvertible>(t: String?) -> T? {
        if let i = t, let n = T(i) {
            return n
        } else {
            return nil
        }
    }
}

// MARK: - WordInfo
extension WordInfo {
    convenience init?(docx url: URL, deepScan: Bool) {
        // App.xml
        // Template: Normal.dotm
        // TotalTime: 178
        // DocSecurity: 0
        // Lines: 6
        // Paragraphs: 1
        // ScaleCrop: false
        // Company: string
        // LinksUpToDate: false
        // SharedDoc: false
        // HyperlinksChanged: false
        // AppVersion: false
        //
        
        guard let archive = Archive(url: url, accessMode: .read) else  {
            return nil
        }
        
        guard var properties = try? Self.parseOfficeCoreXML(archive: archive) else {
            return nil
        }
        
        guard let entryApp = archive["docProps/app.xml"] else {
            return nil
        }
        
        var s = ""
        _ = try? archive.extract(entryApp, skipCRC32: true) { data in
            s += String(data: data, encoding: .utf8) ?? ""
        }
        if !s.isEmpty, let app = try? Kanna.XML(xml: s, encoding: .utf8) {
            var i: Int? = Self.parseXMLText(doc: app, query: "//ns:Pages")
            properties["pages"] = i
            i = Self.parseXMLText(doc: app, query: "//ns:Words")
            properties["words"] = i
            i = Self.parseXMLText(doc: app, query: "//ns:Characters")
            properties["characters"] = i
            i = Self.parseXMLText(doc: app, query: "//ns:CharactersWithSpaces")
            properties["charactersWithSpaces"] = i
            
            properties["application"] = app.at_xpath("//ns:Application")?.text
        }
        
        let pages = properties["pages"] as? Int ?? 0
        let words = properties["words"] as? Int ?? 0
        let characters = properties["characters"] as? Int ?? 0
        let charactersWithSpaces = properties["charactersWithSpaces"] as? Int ?? 0
        
        let creator = properties["creator"] as? String ?? ""
        let title = properties["title"] as? String ?? ""
        let subject = properties["subject"] as? String ?? ""
        let keywords = properties["keywords"] as? [String] ?? []
        let description = properties["description"] as? String ?? ""
        let creationDate = properties["creationDate"] as? Date
        let modifiedDate = properties["modifiedDate"] as? Date
        
        let lastModifiedBy = properties["lastModifiedBy"] as? String ?? ""

        let application = properties["application"] as? String ?? ""
        
        var width: Double = 0
        var height: Double = 0
        if deepScan, let entry = archive["word/document.xml"] {
            var s = ""
            _ = try? archive.extract(entry, skipCRC32: true) { data in
                s += String(data: data, encoding: .utf8) ?? ""
            }
            // https://docs.microsoft.com/en-us/dotnet/api/documentformat.openxml.wordprocessing.pagesize?view=openxml-2.8.1
            if !s.isEmpty, let document = try? Kanna.XML(xml: s, encoding: .utf8), let element = document.xpath("//w:pgSz", namespaces: Self.officeNamespaces).first {
                width = (Self.parseXMLText(t: element["w"]) ?? 0) / 20 / 72
                height = (Self.parseXMLText(t: element["h"]) ?? 0) / 20 / 72
            }
        }
        
        self.init(file: url, charactersCount: characters, charactersWithSpacesCount: charactersWithSpaces, wordsCount: words, pagesCount: pages, creator: creator, creationDate: creationDate, modified: lastModifiedBy, modificationDate: modifiedDate, title: title, subject: subject, keywords: keywords, description: description, application: application, width: width, height: height)
    }
}

// MARK: - ExcelInfo
extension ExcelInfo {
    convenience init?(xlsx url: URL, deepScan: Bool) {
        guard let archive = Archive(url: url, accessMode: .read) else {
            return nil
        }
        
        guard var properties = try? Self.parseOfficeCoreXML(archive: archive) else {
            return nil
        }
        
        guard let entryApp = archive["docProps/app.xml"] else {
            return nil
        }
        
        var s = ""
        _ = try? archive.extract(entryApp, skipCRC32: true) { data in
            s += String(data: data, encoding: .utf8) ?? ""
        }
        if !s.isEmpty, let app = try? Kanna.XML(xml: s, encoding: .utf8) {
            properties["application"] = app.at_xpath("//ns:Application")?.text
        }
        
        let creator = properties["creator"] as? String ?? ""
        let title = properties["title"] as? String ?? ""
        let subject = properties["subject"] as? String ?? ""
        let keywords = properties["keywords"] as? [String] ?? []
        let description = properties["description"] as? String ?? ""
        
        let creationDate = properties["creationDate"] as? Date
        let modifiedDate = properties["modifiedDate"] as? Date
        
        let lastModifiedBy = properties["lastModifiedBy"] as? String ?? ""
        
        let application = properties["application"] as? String ?? ""
        
        var sheets: [String] = []
        
        if deepScan, let entry = archive["xl/workbook.xml"] {
            do {
                var s = ""
                _ = try archive.extract(entry, skipCRC32: true) { data in
                    s += String(data: data, encoding: .utf8) ?? ""
                }
                if !s.isEmpty, let workbook = try? Kanna.XML(xml: s, encoding: .utf8) {
                    for n in workbook.xpath("//xls:sheets/xls:sheet", namespaces: Self.officeNamespaces) {
                        if let name = n["name"] {
                            sheets.append(name)
                        }
                    }
                }
            } catch {
                print(error)
            }
        }
        
        self.init(file: url, creator: creator, creationDate: creationDate, modified: lastModifiedBy, modificationDate: modifiedDate, title: title, subject: subject, keywords: keywords, description: description, application: application, sheets: sheets)
    }
}

// MARK: - PowerpointInfo
extension PowerpointInfo {
    convenience init?(pptx url: URL, deepScan: Bool) {
        guard let archive = Archive(url: url, accessMode: .read) else  {
            return nil
        }
        guard let entryApp = archive["docProps/app.xml"] else {
            return nil
        }
        guard var properties: [String: AnyHashable?] = try? Self.parseOfficeCoreXML(archive: archive) else {
            return nil
        }
        var s = ""
        _ = try? archive.extract(entryApp, skipCRC32: true) { data in
            s += String(data: data, encoding: .utf8) ?? ""
        }
        if !s.isEmpty, let app = try? Kanna.XML(xml: s, encoding: .utf8) {
            properties["application"] = app.at_xpath("//ns:Application")?.text
            properties["presentationFormat"] = app.at_xpath("//ns:PresentationFormat", namespaces: Self.officeNamespaces)?.text
            let i: Int = Self.parseXMLText(doc: app, query: "//ns:Slides") ?? 0
            properties["slides"] = i
        }
        
        let creator = properties["creator"] as? String ?? ""
        let title = properties["title"] as? String ?? ""
        let subject = properties["subject"] as? String ?? ""
        let keywords = properties["keywords"] as? [String] ?? []
        let description = properties["description"] as? String ?? ""
        
        let creationDate = properties["creationDate"] as? Date
        let modifiedDate = properties["modifiedDate"] as? Date
        
        let lastModifiedBy = properties["lastModifiedBy"] as? String ?? ""
        let application = properties["application"] as? String ?? ""
        
        let presentationFormat = properties["presentationFormat"] as? String ?? ""
        let slidesCount = properties["slides"] as? Int ?? 0

        self.init(file: url, creator: creator, creationDate: creationDate, modified: lastModifiedBy, modificationDate: modifiedDate, title: title, subject: subject, keywords: keywords, description: description, application: application, slidesCount: slidesCount, presentationFormat: presentationFormat)
    }
}
