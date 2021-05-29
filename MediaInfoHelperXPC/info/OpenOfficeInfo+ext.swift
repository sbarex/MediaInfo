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
    static let openOfficeNamespaces: [String: String] = [
        "dc":  "http://purl.org/dc/elements/1.1/",
        "meta": "urn:oasis:names:tc:opendocument:xmlns:meta:1.0",
        "office": "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
        "table": "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
        "draw": "urn:oasis:names:tc:opendocument:xmlns:drawing:1.0",
        "fo": "urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0",
        "style": "urn:oasis:names:tc:opendocument:xmlns:style:1.0",
    ]
    
    static func parseOpenOfficeXML(archive: Archive, extraMeta: (Kanna.XMLDocument, inout [String: AnyHashable?])->Void = { _, _ in }) throws -> [String: AnyHashable?] {
        // meta:initial-creator
        // meta:template: Normal.dotm
        // meta:editing-cycles: 2
        // meta:editing-duration: PT0S
        
        guard let entryMeta = archive["meta.xml"] else {
            return [:]
        }
        
        var result: [String: AnyHashable?] = [:]
        var s = ""
        _ = try archive.extract(entryMeta, skipCRC32: true) { data in
            s += String(data: data, encoding: .utf8) ?? ""
        }
        
        let meta = try Kanna.XML(xml: s, encoding: .utf8)
        result["creator"] = meta.at_xpath("//dc:creator", namespaces: Self.openOfficeNamespaces)?.text
        result["title"] = meta.at_xpath("//dc:title", namespaces: Self.openOfficeNamespaces)?.text
        result["subject"] = meta.at_xpath("//dc:subject", namespaces: Self.openOfficeNamespaces)?.text
        result["description"] = meta.at_xpath("//dc:description", namespaces: Self.openOfficeNamespaces)?.text
        result["application"] = meta.at_xpath("//meta:generator", namespaces: Self.openOfficeNamespaces)?.text
        
        var keywords: [String] = []
        for k in meta.xpath("//meta:keyword", namespaces: Self.openOfficeNamespaces) {
            if let t = k.text {
                keywords.append(t)
            }
        }
        result["keywords"] = keywords
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let d = meta.at_xpath("//meta:creation-date", namespaces: Self.openOfficeNamespaces)?.text {
            result["creationDate"] = dateFormatter.date(from:d)
        }
        if let d = meta.at_xpath("//dc:date", namespaces: Self.openOfficeNamespaces)?.text {
            result["modifiedDate"] = dateFormatter.date(from:d)
        }
        extraMeta(meta, &result)

        return result
    }
}

// MARK: - WordInfo
extension WordInfo {
    convenience init?(odt url: URL, deepScan: Bool) {
        guard let archive = Archive(url: url, accessMode: .read) else  {
            return nil
        }
        
        var pages: Int = 0
        var words: Int = 0
        var characters: Int = 0
        var charactersWithSpaces: Int = 0
        
        guard let properties = try? Self.parseOpenOfficeXML(archive: archive, extraMeta: { meta, result in
            if let stat = meta.xpath("//meta:document-statistic", namespaces: Self.openOfficeNamespaces).first {
                pages = Self.parseXMLText(t: stat["page-count"]) ?? 0
                words = Self.parseXMLText(t: stat["word-count"]) ?? 0
                characters = Self.parseXMLText(t: stat["character-count"]) ?? 0
                charactersWithSpaces = Self.parseXMLText(t: stat["non-whitespace-character-count"]) ?? 0
            }
        }) else {
            return nil
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
        
        var width: Double = 0
        var height: Double = 0
        
        let convertLength: (String?)->Double? = { s in
            guard var t = s else {
                return nil
            }
            let unit = t.suffix(2)
            t.removeLast(2)
            
            guard var m = Double(t) else {
                return nil
            }
            
            switch unit {
            case "cm":
                m /= 2.54
            case "mm":
                m /= 25.4
            case "pt":
                m /= 72
            case "pc":
                m = (m * 12) / 72
            case "px":
                m /= 72 // use 72 dpi
            case "em":
                return nil
            case "in":
                break
            default:
                return nil
            }
            
            return m
        }
        
        if let styleMeta = archive["styles.xml"] {
            var s = ""
            _ = try? archive.extract(styleMeta, skipCRC32: true) { data in
                s += String(data: data, encoding: .utf8) ?? ""
            }
            if !s.isEmpty, let styles = try? Kanna.XML(xml: s, encoding: .utf8), let node = styles.xpath("//office:automatic-styles/style:page-layout/style:page-layout-properties", namespaces: Self.openOfficeNamespaces).first {
                width = convertLength(node["page-width"]) ?? 0
                height = convertLength(node["page-height"]) ?? 0
            }
        }
        
        self.init(file: url, charactersCount: characters, charactersWithSpacesCount: charactersWithSpaces, wordsCount: words, pagesCount: pages, creator: creator, creationDate: creationDate, modified: lastModifiedBy, modificationDate: modifiedDate, title: title, subject: subject, keywords: keywords, description: description, application: application, width: width, height: height)
    }
}

// MARK: - ExcelInfo
extension ExcelInfo {
    convenience init?(ods url: URL, deepScan: Bool) {
        guard let archive = Archive(url: url, accessMode: .read) else  {
            return nil
        }
        
        guard let properties = try? Self.parseOpenOfficeXML(archive: archive) else {
            return nil
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
        
        if deepScan, let entryContent = archive["content.xml"] {
            var s = ""
            _ = try? archive.extract(entryContent, skipCRC32: true) { data in
                s += String(data: data, encoding: .utf8) ?? ""
            }
            if !s.isEmpty, let content = try? Kanna.XML(xml: s, encoding: .utf8) {
                let tables = content.xpath("//office:body/office:spreadsheet/table:table", namespaces: Self.openOfficeNamespaces)
                for n in tables {
                    if let name = n["name"] {
                        sheets.append(name)
                    }
                }
            }
        }
            
        self.init(file: url, creator: creator, creationDate: creationDate, modified: lastModifiedBy, modificationDate: modifiedDate, title: title, subject: subject, keywords: keywords, description: description, application: application, sheets: sheets)
    }
}

// MARK: - PowerpointInfo
extension PowerpointInfo {
    convenience init?(odp url: URL, deepScan: Bool) {
        guard let archive = Archive(url: url, accessMode: .read) else  {
            return nil
        }
        
        guard let properties = try? Self.parseOpenOfficeXML(archive: archive) else {
            return nil
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
        
        var slidesCount = 0
        
        if deepScan, let entryContent = archive["content.xml"] {
            var s = ""
            _ = try? archive.extract(entryContent, skipCRC32: true) { data in
                s += String(data: data, encoding: .utf8) ?? ""
            }
            if !s.isEmpty, let content = try? Kanna.XML(xml: s, encoding: .utf8) {
                slidesCount = content.xpath("//draw:page", namespaces: Self.openOfficeNamespaces).count
            }
        }
        
        self.init(file: url, creator: creator, creationDate: creationDate, modified: lastModifiedBy, modificationDate: modifiedDate, title: title, subject: subject, keywords: keywords, description: description, application: application, slidesCount: slidesCount, presentationFormat: "")
    }
}
