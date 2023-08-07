//
//  FileInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 24/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Cocoa
import UniformTypeIdentifiers
import OSLog

// MARK: -
class FileInfo: BaseInfo {
    enum FileCodingKeys: String, CodingKey {
        case fileUrl
        case fileSize
        case fileSizeFull
        case filePath
        case fileName
        case fileExtension
        case fileCreationDate
        case fileModificationDate
        case fileAccessDate
        case fileMode
        case fileFormattedMode
        case fileAcl
        case uti
        case utiConforms
        case extAttrs
        case spotlight
    }
    
    struct ACLItem: Codable {
        enum FileCodingKeys: String, CodingKey {
            case name
            case id
            case uid
            case isUser
            case allow
            case attributes
        }
        let name: String
        let id: Int
        let uid: String
        let allow: Bool
        let isUser: Bool
        let attributes: [String]
        
        var title: String {
            let title = "\(self.isUser ? "user" : "group"):\(self.name) (\(self.id)) \(self.allow ? "allow" : "deny"): \(self.attributes.joined(separator: ", "))"
            return title
        }
        var image: String {
            if self.isUser {
                return self.allow ? "person_y" : "person_n"
            } else {
                return self.allow ? "group_y" : "group_n"
            }
        }
        
        init(isUser: Bool, uid: String, name: String, id: Int, allow: Bool, attributes: [String]) {
            self.isUser = isUser
            self.uid = uid
            self.name = name
            self.id = id
            self.allow = allow
            self.attributes = attributes
        }
        
        init?(from acl: String) {
            var s = acl
            if acl.hasPrefix("user:") {
                self.isUser = true
                s.removeFirst(5)
            } else if acl.hasPrefix("group:") {
                self.isUser = false
                s.removeFirst(6)
            } else {
                return nil
            }
            let p = s.split(separator: ":")
            guard p.count == 5 else {
                return nil
            }
            self.uid = String(p[0])
            self.name = String(p[1])
            guard let id = Int(p[2]) else {
                return nil
            }
            self.id = id
            if p[3] == "deny" {
                self.allow = false
            } else if p[3] == "allow" {
                self.allow = true
            } else {
                return nil
            }
            self.attributes = p[4].split(separator: ",").map({String($0)})
        }
    }
    
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        
        return formatter
    }
    
    static func getFileInfo(_ file: URL) -> (filesize: Int64, creation: Date, edit: Date, access: Date, mode: mode_t)? {
        var output: stat = stat()
        guard stat(file.path, &output) == 0 else {
            return nil
        }
        let fileSize: Int64 = output.st_size
        let c = Date(timeIntervalSince1970: TimeInterval(output.st_ctimespec.tv_sec))
        let m = Date(timeIntervalSince1970: TimeInterval(output.st_mtimespec.tv_sec))
        let a = Date(timeIntervalSince1970: TimeInterval(output.st_atimespec.tv_sec))
        
        return (filesize: fileSize, creation: c, edit: m, access: a, mode: output.st_mode)
    }
    
    static func getACL(_ file: URL) -> [ACLItem]? {
        guard let acl = acl_get_file(file.path.cString(using: .utf8), ACL_TYPE_EXTENDED) else {
            if errno == ENOENT {
                // Either file not found, or does not have ACL attached
                return []
            }
            return nil
        }
        var len: Int = 0
        let a = acl_to_text(acl, &len)
        defer {
            acl_free(a)
        }
        guard let s = String(cString: a)?.trimmingCharacters(in: .whitespaces).split(separator: "\n") else {
            return nil
        }
        var aclItems: [ACLItem] = []
        for access in s {
            guard !access.hasPrefix("!#acl") else {
                continue
            }
            if let item = ACLItem(from: String(access)) {
                aclItems.append(item)
            }
        }
        print(s)
        return aclItems
        
    }
    
    var file: URL
    var fileSize: Int64
    var fileSizeFull: Int64
    var fileCreationDate: Date?
    var fileModificationDate: Date?
    var fileAccessDate: Date?
    var mode: mode_t
    var acl: [ACLItem]
    var uti: String
    var utiConformsToType: [String]
    var extAttrs: [String: String]
    var spotlightMetadata: [String: AnyHashable]
    
    init(file: URL) {
        self.file = file
        let info = Self.getFileInfo(file)
        self.acl = Self.getACL(file) ?? []
        self.fileSize = info?.filesize ?? -1
        if let r = try? file.resourceValues(forKeys: [.totalFileAllocatedSizeKey]) {
            self.fileSizeFull = Int64(r.totalFileAllocatedSize ?? Int(info?.0 ?? -1))
        } else {
            self.fileSizeFull = self.fileSize
        }
        self.fileCreationDate = info?.creation
        self.fileModificationDate = info?.edit
        self.fileAccessDate = info?.access
        self.mode = info?.mode ?? 0
        
        self.spotlightMetadata = [:]
        
        if #available(macOS 11.0, *) {
            if let data = try? file.resourceValues(forKeys: [.contentTypeKey]), let u = data.contentType {
                self.uti = u.identifier
                self.utiConformsToType = u.supertypes.map({ $0.identifier })
            } else {
                self.uti = ""
                self.utiConformsToType = []
            }
        } else {
            if let uti = try? file.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                self.uti = uti
                if let unmanaged = UTTypeCopyDeclaration(uti as CFString), let dict = (unmanaged.takeRetainedValue() as NSDictionary) as? [String: AnyObject], let types = dict[kUTTypeConformsToKey as String] as? [String] {
                    self.utiConformsToType = types
                } else {
                    self.utiConformsToType = []
                }
            } else {
                self.uti = ""
                self.utiConformsToType = []
            }
        }
        
        var extAttrs: [String: String] = [:]
        for name in (try? file.listExtendedAttributes()) ?? [] {
            guard let data = try? file.extendedAttribute(forName: name) else {
                continue
            }
            // com.apple.metadata:_kMDItemUserTags: https://eclecticlight.co/2017/12/27/xattr-com-apple-metadata_kmditemusertags-finder-tags/
            if name == "com.apple.FinderInfo" {
                extAttrs[name] = "" // binary data not parsed, see https://eclecticlight.co/2017/12/19/xattr-com-apple-finderinfo-information-for-the-finder/
            } else if name == "com.apple.macl" {
                extAttrs[name] = "" // binary data not parsed, see https://mjtsai.com/blog/2019/12/18/persistent-file-access-via-com-apple-macl-xattr/
            } else if let p = try? PropertyListSerialization.propertyList(from: data, format: nil) {
                if let s = p as? String {
                    extAttrs[name] = s.replacingOccurrences(of: "\n", with: " ")
                } else if let s = p as? [String] {
                    extAttrs[name] = s.joined(separator: "; ").replacingOccurrences(of: "\n", with: " ")
                } else {
                    extAttrs[name] = ""
                }
            } else if let s = String(data: data, encoding: .utf8) {
                extAttrs[name] = s.replacingOccurrences(of: "\n", with: " ")
            } else {
                // FIXME: do not honor the useDecimalBytes settings.
                extAttrs[name] = Self.byteCountFormatter.string(fromByteCount: Int64(data.count))
            }
        }
        self.extAttrs = extAttrs
        
        super.init()
        
        if let metadata = MDItemCreateWithURL(nil, file as CFURL) {
            self.fetchMetadata(from: metadata)
            
            if let mdnames = MDItemCopyAttributeNames(metadata) {
                var attributes: [CFString] = []
                for name in mdnames as! [String] {
                    guard self.spotlightMetadata[name] == nil else {
                        continue
                    }
                    attributes.append(name as CFString)
                }
                if let mdattrs: [String: CFTypeRef] = MDItemCopyAttributes(metadata, attributes as CFArray) as? [String: CFTypeRef] {
                    for attr in mdattrs {
                        let type = CFGetTypeID(attr.value)
                        if type == CFArrayGetTypeID(), let v = attr.value as? [String] {
                            self.spotlightMetadata[attr.key] = v
                        } else if type == CFDateGetTypeID(), let v = attr.value as? Date {
                            self.spotlightMetadata[attr.key] = v
                        } else if type == CFNumberGetTypeID() {
                            if let n = attr.value as? Int64 {
                                self.spotlightMetadata[attr.key] = n
                            } else if let n = attr.value as? Int {
                                self.spotlightMetadata[attr.key] = n
                            } else if let n = attr.value as? Double {
                                self.spotlightMetadata[attr.key] = n
                            } else if let n = attr.value as? Float {
                                self.spotlightMetadata[attr.key] = n
                            } else {
                                self.spotlightMetadata[attr.key] = "\(attr.value)"
                            }
                        } else if type == CFBooleanGetTypeID() {
                            let b = CFBooleanGetValue((attr.value as! CFBoolean))
                            self.spotlightMetadata[attr.key] = NSLocalizedString(b ? "Yes" : "No", tableName: "LocalizableExt", comment: "")
                        } else if type == CFStringGetTypeID(), let v = attr.value as? String {
                            self.spotlightMetadata[attr.key] = v
                        } else {
                            self.spotlightMetadata[attr.key] = "\(attr.value)"
                        }
                    }
                }
            }
            
        } else {
            os_log("Unable to open fetch the spotlight metadata of %{private}@!", log: OSLog.infoExtraction, type: .error, file.path)
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FileCodingKeys.self)
        self.file = try container.decode(URL.self, forKey: .fileUrl)
        self.fileSize = try container.decode(Int64.self, forKey: .fileSize)
        self.fileSizeFull = try container.decode(Int64.self, forKey: .fileSizeFull)
        self.fileCreationDate = try container.decode(Date.self, forKey: .fileCreationDate)
        self.fileModificationDate = try container.decode(Date.self, forKey: .fileModificationDate)
        self.fileAccessDate = try container.decode(Date.self, forKey: .fileAccessDate)
        self.mode = try container.decode(mode_t.self, forKey: .fileMode)
        self.acl = try container.decode([ACLItem].self, forKey: .fileAcl)
        self.uti = try container.decode(String.self, forKey: .uti)
        self.utiConformsToType = try container.decode([String].self, forKey: .utiConforms)
        self.extAttrs = try container.decode([String: String].self, forKey: .extAttrs)
        self.spotlightMetadata = [:]
        let spotlight = try container.decode([String: AnyCodable].self, forKey: .spotlight)
        for info in spotlight {
            if let v = info.value.value as? AnyHashable {
                self.spotlightMetadata[info.key] = v
            } else if let v = info.value.value as? [AnyHashable] {
                self.spotlightMetadata[info.key] = v
            } else if let v = info.value.value as? [AnyHashable: AnyHashable] {
                self.spotlightMetadata[info.key] = v
            } else {
                continue
            }
        }
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FileCodingKeys.self)
        try container.encode(self.file, forKey: .fileUrl)
        try container.encode(self.fileSize, forKey: .fileSize)
        try container.encode(self.fileSizeFull, forKey: .fileSizeFull)
        
        try container.encode(self.fileCreationDate, forKey: .fileCreationDate)
        try container.encode(self.fileModificationDate, forKey: .fileModificationDate)
        try container.encode(self.fileAccessDate, forKey: .fileAccessDate)
        try container.encode(self.mode, forKey: .fileMode)
        try container.encode(self.acl, forKey: .fileAcl)
        
        try container.encode(self.uti, forKey: .uti)
        try container.encode(self.utiConformsToType, forKey: .utiConforms)
        try container.encode(self.extAttrs, forKey: .extAttrs)
        
        var spotlight: [String: AnyCodable] = [:]
        for info in self.spotlightMetadata {
            spotlight[info.key] = AnyCodable(value: info.value)
        }
        try container.encode(spotlight, forKey: .spotlight)
        
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.file.path, forKey: .filePath)
            try container.encode(self.file.lastPathComponent, forKey: .fileName)
            try container.encode(self.file.pathExtension, forKey: .fileExtension)
            try container.encode(self.getFormattedMode(withExtra: true, withACL: true), forKey: .fileFormattedMode)
        }
        
        try super.encode(to: encoder)
    }
    
    /*
    static func convertCFType<T>(_ ref: CFTypeRef)->T? {
        let type = CFGetTypeID(ref)
        if T.self == String.self, type == CFStringGetTypeID() {
            return ref as? T
        } else if T.self == Int.self, type == CFNumberGetTypeID() {
            //var n = 0
            //CFNumberGetValue((ref as! CFNumber), .intType, &n)
            return ref as? T
        } else if T.self == Double.self, type == CFNumberGetTypeID() {
            //var n = 0
            //CFNumberGetValue((ref as! CFNumber), .doubleType, &n)
            return ref as? T
        } else if T.self == Int64.self, type == CFNumberGetTypeID(), CFNumberGetType((ref as! CFNumber)) == .sInt64Type {
            var n = 0
            CFNumberGetValue((ref as! CFNumber), .doubleType, &n)
            return n
        }
        return nil
    }
    */
    
    func fetchMetadata(from metadata: MDItem) {
        if let m = MDItemCopyAttribute(metadata, kMDItemAttributeChangeDate) {
            self.spotlightMetadata[kMDItemAttributeChangeDate as String] = m as! Date
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAudiences), CFGetTypeID(m) == CFArrayGetTypeID() {
            //The audience for which the file is intended. The audience may be determined by the creator or the publisher or by a third party. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemAudiences as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAuthors), CFGetTypeID(m) == CFArrayGetTypeID() {
            // The author, or authors, of the contents of the file. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemAuthors as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAuthorAddresses), CFGetTypeID(m) == CFArrayGetTypeID() {
            //This attribute indicates the author addresses of the document. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemAuthorAddresses as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemCity), CFGetTypeID(m) == CFStringGetTypeID() {
            // Identifies city of origin according to guidelines established by the provider. A CFString.
            self.spotlightMetadata[kMDItemCity as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemComment), CFGetTypeID(m) == CFStringGetTypeID() {
            // A comment related to the file. This differs from the Finder comment, kMDItemFinderComment. A CFString.
            self.spotlightMetadata[kMDItemComment as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemContactKeywords), CFGetTypeID(m) == CFArrayGetTypeID() {
            // A list of contacts that are associated with this document, not including the authors. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemContactKeywords as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemContentCreationDate), CFGetTypeID(m) == CFDateGetTypeID() {
            // The creation date of an edited or optimized version of the song or composition.
            self.spotlightMetadata[kMDItemContentCreationDate as String] = m as! Date
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemContentModificationDate), CFGetTypeID(m) == CFDateGetTypeID() {
            // The date and time that the contents of the file were last modified. A CFDate.
            self.spotlightMetadata[kMDItemContentModificationDate as String] = m as! Date
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemContentType), CFGetTypeID(m) == CFStringGetTypeID() {
            // The UTI pedigree of a file. A CFString.
            self.spotlightMetadata[kMDItemContentType as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemContributors), CFGetTypeID(m) == CFArrayGetTypeID() {
            // The entities responsible for making contributions to the content of the resource. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemContributors as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemCopyright), CFGetTypeID(m) == CFStringGetTypeID() {
            // The copyright owner of the file contents. A CFString.
            self.spotlightMetadata[kMDItemCopyright as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemCountry), CFGetTypeID(m) == CFStringGetTypeID() {
            // The full, publishable name of the country or region where the intellectual property of the item was created, according to guidelines of the provider.
            self.spotlightMetadata[kMDItemCountry as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemCoverage), CFGetTypeID(m) == CFStringGetTypeID() {
            // The extent or scope of the content of the resource. A CFString.
            self.spotlightMetadata[kMDItemCoverage as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemCreator), CFGetTypeID(m) == CFStringGetTypeID() {
            // Application used to create the document content (for example “Word”, “Pages”, and so on). A CFString.
            self.spotlightMetadata[kMDItemCreator as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemDescription), CFGetTypeID(m) == CFStringGetTypeID() {
            // A description of the content of the resource. The description may include an abstract, table of contents, reference to a graphical representation of content or a free-text account of the content. A CFString.
            self.spotlightMetadata[kMDItemDescription as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemDueDate), CFGetTypeID(m) == CFDateGetTypeID() {
            // Date this item is due. A CFDate.
            self.spotlightMetadata[kMDItemDueDate as String] = m as! Date
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemDurationSeconds), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The duration, in seconds, of the content of file. A value of 10.5 represents media that is 10 and 1/2 seconds long. A CFNumber.
            var n: Double = 0
            CFNumberGetValue((m as! CFNumber), CFNumberType.doubleType, &n)
            self.spotlightMetadata[kMDItemDurationSeconds as String] = n
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemEmailAddresses), CFGetTypeID(m) == CFArrayGetTypeID() {
            // Email addresses related to this item. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemEmailAddresses as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemEncodingApplications), CFGetTypeID(m) == CFArrayGetTypeID() {
            // Application used to convert the original content into it's current form. For example, a PDF file might have an encoding application set to "Distiller". A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemEncodingApplications as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemFinderComment), CFGetTypeID(m) == CFStringGetTypeID() {
            // Finder comments for this file. A CFString.
            self.spotlightMetadata[kMDItemFinderComment as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemFonts), CFGetTypeID(m) == CFStringGetTypeID() {
            // Fonts used in this item. You should store the font's full name, the postscript name, or the font family name, based on the available information. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemFonts as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemHeadline), CFGetTypeID(m) == CFStringGetTypeID() {
            // A publishable entry providing a synopsis of the contents of the file. For example, "Apple Introduces the iPod Photo". A CFString.
            self.spotlightMetadata[kMDItemFonts as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemIdentifier), CFGetTypeID(m) == CFStringGetTypeID() {
            // A formal identifier used to reference the resource within a given context. A CFString.
            self.spotlightMetadata[kMDItemIdentifier as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemInstantMessageAddresses), CFGetTypeID(m) == CFArrayGetTypeID() {
            // Instant message addresses related to this item. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemInstantMessageAddresses as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemInstructions), CFGetTypeID(m) == CFStringGetTypeID() {
            // Editorial instructions concerning the use of the item, such as embargoes and warnings. For example, "Second of four stories". A CFString.
            self.spotlightMetadata[kMDItemInstructions as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemKeywords), CFGetTypeID(m) == CFArrayGetTypeID() {
            // Keywords associated with this file. For example, “Birthday”, “Important”, etc. An CFArray of CFStrings.
            self.spotlightMetadata[kMDItemKeywords as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemKind), CFGetTypeID(m) == CFStringGetTypeID() {
            // A description of the kind of item this file represents. A CFString.
            self.spotlightMetadata[kMDItemKind as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemLanguages), CFGetTypeID(m) == CFArrayGetTypeID() {
            // Indicates the languages of the intellectual content of the resource. Recommended best practice for the values of the Language element is defined by RFC 3066. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemLanguages as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemLastUsedDate), CFGetTypeID(m) == CFDateGetTypeID() {
            // The date and time that the file was last used. This value is updated automatically by LaunchServices everytime a file is opened by double clicking, or by asking LaunchServices to open a file. A CFDate.
            self.spotlightMetadata[kMDItemLastUsedDate as String] = m as! Date
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemNumberOfPages), CFGetTypeID(m) == CFNumberGetTypeID() {
            // Number of pages in the document. A CFNumber.
            var n: Int = 0
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &n)
            self.spotlightMetadata[kMDItemNumberOfPages as String] = n
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemOrganizations), CFGetTypeID(m) == CFArrayGetTypeID() {
            // The company or organization that created the document. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemOrganizations as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemPageHeight), CFGetTypeID(m) == CFNumberGetTypeID() {
            // Height of the document page, in points (72 points per inch). For PDF files this indicates the height of the first page only. A CFNumber.
            var n: Int = 0
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &n)
            self.spotlightMetadata[kMDItemPageHeight as String] = n
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemPageWidth), CFGetTypeID(m) == CFNumberGetTypeID() {
            // Width of the document page, in points (72 points per inch). For PDF files this indicates the width of the first page only. A CFNumber.
            var n: Int = 0
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &n)
            self.spotlightMetadata[kMDItemPageWidth as String] = n
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemParticipants), CFGetTypeID(m) == CFArrayGetTypeID() {
            // The list of people who are visible in an image or movie or written about in a document. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemParticipants as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemPhoneNumbers), CFGetTypeID(m) == CFArrayGetTypeID() {
            // Phone numbers related to this item. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemPhoneNumbers as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemProjects), CFGetTypeID(m) == CFArrayGetTypeID() {
            // The list of projects that this file is part of. For example, if you were working on a movie all of the files could be marked as belonging to the project “My Movie”. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemProjects as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemPublishers), CFGetTypeID(m) == CFArrayGetTypeID() {
            // The entity responsible for making the resource available. For example, a person, an organization, or a service. Typically, the name of a publisher should be used to indicate the entity. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemPublishers as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemRecipients), CFGetTypeID(m) == CFArrayGetTypeID() {
            // Recipients of this item. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemRecipients as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemRecipientAddresses), CFGetTypeID(m) == CFArrayGetTypeID() {
            // This attribute indicates the recipient addresses of the document. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemRecipientAddresses as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemRights), CFGetTypeID(m) == CFStringGetTypeID() {
            // Provides a link to information about rights held in and over the resource. A CFString.
            self.spotlightMetadata[kMDItemRights as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemSecurityMethod), CFGetTypeID(m) == CFNumberGetTypeID() {
            // The security or encryption method used for the file. A CFNumber.
            var n: Int = 0
            CFNumberGetValue((m as! CFNumber), CFNumberType.intType, &n)
            self.spotlightMetadata[kMDItemStarRating as String] = n
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemStarRating), CFGetTypeID(m) == CFNumberGetTypeID() {
            // User rating of this item. For example, the stars rating of an iTunes track. A CFNumber.
            var n: Double = 0
            CFNumberGetValue((m as! CFNumber), CFNumberType.doubleType, &n)
            self.spotlightMetadata[kMDItemStarRating as String] = n
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemStateOrProvince), CFGetTypeID(m) == CFStringGetTypeID() {
            // Identifies the province or state of origin according to guidelines established by the provider. For example, "CA", "Ontario", or "Sussex". A CFString.
            self.spotlightMetadata[kMDItemStateOrProvince as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemTextContent), CFGetTypeID(m) == CFStringGetTypeID() {
            // Contains a text representation of the content of the document. Data in multiple fields should be combined using a whitespace character as a separator. A CFString.
            self.spotlightMetadata[kMDItemTextContent as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemTitle), CFGetTypeID(m) == CFStringGetTypeID() {
            // The title of the file. For example, this could be the title of a document, the name of a song, or the subject of an email message. A CFString.
            self.spotlightMetadata[kMDItemTitle as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemVersion), CFGetTypeID(m) == CFStringGetTypeID() {
            // The version number of this file. A CFString
            self.spotlightMetadata[kMDItemVersion as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemWhereFroms), CFGetTypeID(m) == CFArrayGetTypeID() {
            // Describes where the file was obtained from. A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemWhereFroms as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemAuthorEmailAddresses), CFGetTypeID(m) == CFArrayGetTypeID() {
            // This attribute indicates the author of the emails message addresses. (This is always the email address, and not the human readable version). A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemAuthorEmailAddresses as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemRecipientEmailAddresses), CFGetTypeID(m) == CFArrayGetTypeID() {
            // This attribute indicates the recipients email addresses. (This is always the email address, and not the human readable version). A CFArray of CFStrings.
            self.spotlightMetadata[kMDItemRecipientEmailAddresses as String] = m as! [String]
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemTheme), CFGetTypeID(m) == CFStringGetTypeID() {
            // Theme of the this item. A CFString.
            self.spotlightMetadata[kMDItemTheme as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemSubject), CFGetTypeID(m) == CFStringGetTypeID() {
            // Subject of the this item. Type is a CFString.
            self.spotlightMetadata[kMDItemSubject as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemCFBundleIdentifier), CFGetTypeID(m) == CFStringGetTypeID() {
            // if this item is a bundle, then this is the CFBundleIdentifier. A CFString.
            self.spotlightMetadata[kMDItemCFBundleIdentifier as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemFSHasCustomIcon), CFGetTypeID(m) == CFBooleanGetTypeID() {
            // Boolean indicating if this file has a custom icon. Type is a CFBoolean.
            let b = CFBooleanGetValue((m as! CFBoolean))
            self.spotlightMetadata[kMDItemFSHasCustomIcon as String] = NSLocalizedString(b ? "Yes" : "No", tableName: "LocalizableExt", comment: "")
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemFSIsStationery), CFGetTypeID(m) == CFBooleanGetTypeID() {
            // Boolean indicating if this file is stationery. Type is a CFBoolean.
            let b = CFBooleanGetValue((m as! CFBoolean))
            self.spotlightMetadata[kMDItemFSIsStationery as String] = NSLocalizedString(b ? "Yes" : "No", tableName: "LocalizableExt", comment: "")
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemInformation), CFGetTypeID(m) == CFStringGetTypeID() {
            // Information about the item. A CFString.
            self.spotlightMetadata[kMDItemInformation as String] = (m as! String)
        }
        if let m = MDItemCopyAttribute(metadata, kMDItemURL), CFGetTypeID(m) == CFStringGetTypeID() {
            // Url of the item. A CFString.
            self.spotlightMetadata[kMDItemURL as String] = (m as! String)
        }
    }
    
    func getFormattedMode(withExtra: Bool, withACL: Bool)-> String {
        let r = ["r", "-"] // ["ⓡ", "○"] // ["🆁", "⬜︎"]
        let w = ["w", "-"] // ["ⓦ", "○"] // "🆆"
        let x = ["x", "-"] // ["ⓧ", "○"] // "🆇"
        
        var modes = ""
        
        modes += self.mode & S_IFDIR == S_IFDIR ? "d" : "-"
        modes += " "
        modes += r[self.mode & S_IRUSR == S_IRUSR ? 0 : 1]
        modes += w[self.mode & S_IWUSR == S_IWUSR ? 0 : 1]
        modes += x[self.mode & S_IXUSR == S_IXUSR ? 0 : 1]
        modes += " "
        
        modes += r[self.mode & S_IRGRP == S_IRGRP ? 0 : 1]
        modes += w[self.mode & S_IWGRP == S_IWGRP ? 0 : 1]
        modes += x[self.mode & S_IXGRP == S_IXGRP ? 0 : 1]
        modes += " "
        
        modes += r[self.mode & S_IROTH == S_IROTH ? 0 : 1]
        modes += w[self.mode & S_IWOTH == S_IWOTH ? 0 : 1]
        modes += x[self.mode & S_IXOTH == S_IXOTH ? 0 : 1]
        modes += " "
        
        if withACL && !self.extAttrs.isEmpty {
            modes += "@"
        }
        if withExtra && !self.acl.isEmpty {
            modes += "+"
        }
        return modes
    }
    
    override func getImage(for name: String) -> NSImage? {
        if name == "target-icon" {
            return NSWorkspace.shared.icon(forFile: self.file.path).resized(to: NSSize(width: 16, height: 16))
        } else {
            return super.getImage(for: name)
        }
    }
    
    override func placeholderAllowCapitalize(_ placeholder: String) -> Bool {
        switch placeholder {
        case "[[file-name]]", "[[file-ext]]": return false
        default:
            return super.placeholderAllowCapitalize(placeholder)
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
        
        switch placeholder {
        case "[[filesize]]", "[[file-size]]":
            isFilled = self.fileSize > 0
            Self.byteCountFormatter.countStyle = (self.globalSettings?.bytesFormat ?? .standard).countStyle
            return self.fileSize >= 0 ? Self.byteCountFormatter.string(fromByteCount: fileSize) : self.formatND(useEmptyData: useEmptyData)
        case "[[filesize-full]]", "[[file-size-full]]":
            isFilled = self.fileSizeFull > 0
            Self.byteCountFormatter.countStyle = (self.globalSettings?.bytesFormat ?? .standard).countStyle
            return self.fileSizeFull >= 0 ? Self.byteCountFormatter.string(fromByteCount: fileSizeFull) : self.formatND(useEmptyData: useEmptyData)
        case "[[file-name]]":
            isFilled = true
            return self.file.lastPathComponent
        case "[[file-ext]]":
            isFilled = true
            return self.file.pathExtension
        case "[[file-cdate]]":
            isFilled = self.fileCreationDate != nil
            return self.fileCreationDate == nil ? self.formatND(useEmptyData: useEmptyData) : Self.dateFormatter.string(from: self.fileCreationDate!)
        case "[[file-mdate]]":
            isFilled = self.fileModificationDate != nil
            return self.fileModificationDate == nil ? self.formatND(useEmptyData: useEmptyData) : Self.dateFormatter.string(from: self.fileModificationDate!)
        case "[[file-adate]]":
            isFilled = self.fileAccessDate != nil
            return self.fileAccessDate == nil ? self.formatND(useEmptyData: useEmptyData) : Self.dateFormatter.string(from: self.fileAccessDate!)
        case "[[file-modes]]":
            guard self.mode != 0 else {
                isFilled = false
                return self.formatND(useEmptyData: useEmptyData)
            }
            isFilled = true
            return self.getFormattedMode(withExtra: true, withACL: true)
        case "[[uti]]":
            isFilled = !self.uti.isEmpty
            if isFilled {
                let dyn: Bool
                if #available(macOS 11.0, *) {
                    if let b = UTType(uti)?.isDynamic {
                        dyn = b
                    } else {
                        dyn = false
                    }
                } else {
                    dyn = UTTypeIsDynamic(uti as CFString)
                }
                return self.uti + (dyn ? " ("+NSLocalizedString("dynamic", tableName: "LocalizableExt", comment: "")+")" : "")
            } else {
                return self.formatND(useEmptyData: useEmptyData)
            }
        case "[[uti-desc]]":
            isFilled = !self.uti.isEmpty
            guard isFilled else {
                return self.formatND(useEmptyData: useEmptyData)
            }
            if #available(macOS 11.0, *) {
                if let desc = UTType(uti)?.localizedDescription {
                    return desc
                }
            } else {
                if let desc = UTTypeCopyDescription(uti as CFString)?.takeRetainedValue() as? String {
                    return desc
                }
            }
            isFilled = false
            return self.formatND(useEmptyData: useEmptyData)
        default:
            return super.processPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
        }
    }
    
    override internal func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu) -> Bool {
        switch item.menuItem.template {
        case "[[open]]", "[[open-with-default]]":
            let title: String
            let path: String
            if let url = NSWorkspace.shared.urlForApplication(toOpen: self.file) {
                path = url.path
                title = String(format: NSLocalizedString("Open with %@…", tableName: "LocalizableExt", comment: ""), FileManager.default.displayName(atPath: path))
            } else {
                title = NSLocalizedString("Open…", tableName: "LocalizableExt", comment: "")
                path = ""
            }
            let mnu = self.createMenuItem(title: title, image: item.menuItem.image, representedObject: item)
            if let info = mnu.representedObject as? MenuItemInfo {
                var info2 = info
                info2.action = .open
                mnu.representedObject = info2
            }
            if !(self.globalSettings?.isIconHidden ?? true) && item.menuItem.image.isEmpty && !path.isEmpty {
                let img = NSWorkspace.shared.icon(forFile: path).resized(to: NSSize(width: 16, height: 16))
                mnu.image = img
            }
            mnu.toolTip = path
            destination_sub_menu.addItem(mnu)
            return true
        case "[[clipboard]]":
            let mnu = self.createMenuItem(title: NSLocalizedString("Copy path to the clipboard", tableName: "LocalizableExt", comment: ""), image: item.menuItem.image, representedObject: item)
            if let info = mnu.representedObject as? MenuItemInfo {
                var info2 = info
                info2.action = .clipboard
                mnu.representedObject = info2
            }
            destination_sub_menu.addItem(mnu)
            return true
        case "[[export]]":
            let mnu = self.createMenuItem(title: NSLocalizedString("Export info to the clipboard…", tableName: "LocalizableExt", comment: ""), image: item.menuItem.image, representedObject: item)
            if let info = mnu.representedObject as? MenuItemInfo {
                var info2 = info
                info2.action = .export
                mnu.representedObject = info2
            }
            destination_sub_menu.addItem(mnu)
            return true
        case "[[uti-conforms]]":
            if !self.utiConformsToType.isEmpty {
                let mnu = self.createMenuItem(title: self.uti, image: item.menuItem.image, representedObject: item)
                let sub_menu = NSMenu()
                for uti in self.utiConformsToType {
                    var uti_item = item
                    uti_item.userInfo["uti"] = uti
                    sub_menu.addItem(self.createMenuItem(title: uti, image: "no-space", representedObject: uti_item))
                }
                mnu.submenu = sub_menu
                destination_sub_menu.addItem(mnu)
            }
            return true
        case "[[acl]]":
            let mnu = self.createMenuItem(title: self.getFormattedMode(withExtra: true, withACL: false), image: item.menuItem.image, representedObject: item)
            let sub_menu = NSMenu()
            if !self.acl.isEmpty {
                for acl in self.acl {
                    var acl_item = item
                    acl_item.userInfo["acl"] = acl.title
                    let mnu_acl = self.createMenuItem(title: acl.title, image: acl.image, representedObject: acl_item)
                    sub_menu.addItem(mnu_acl)
                }
                mnu.submenu = sub_menu
            }
            destination_sub_menu.addItem(mnu)
            return true
        case "[[spotlight]]":
            guard !self.spotlightMetadata.isEmpty else {
               return false
            }
            let metadata_submenu = NSMenu(title: "Spotilight")
               
            var subItemInfo = item
            subItemInfo.userInfo["metadata_key"] = "Spotlight"
            
            let formatKey: (String)->String = { key in
                if key.hasPrefix("kMDItem") {
                    return String(key.dropFirst(7)).camelCaseToWords()
                } else if key.hasPrefix("_kMDItem") {
                    return String(key.dropFirst(8)).camelCaseToWords()
                } else if key.hasPrefix("kMD") {
                    return String(key.dropFirst(3)).camelCaseToWords()
                } else if key.hasPrefix("_kMD") {
                    return String(key.dropFirst(4)).camelCaseToWords()
                } else {
                    return key
                }
            }
            
            var sort: [(key: String, title: String, index: Int)] = []
            for (i, k) in self.spotlightMetadata.keys.enumerated() {
                sort.append((key: k, title: formatKey(k), index: i))
            }
            sort.sort(by: { a, b in
                return a.title < b.title
            })
            
            let iconHidden = self.globalSettings?.isIconHidden ?? false
            self.globalSettings?.isIconHidden = true
               
            for k in sort {
                let i = k.index
                let item = self.spotlightMetadata[k.key]!
                
                var subItemInfo2 = subItemInfo
                subItemInfo2.userInfo["spotlight_key_index"] = i
               
                let mnu_tag: NSMenuItem
                if let v = item as? [String] {
                    mnu_tag = self.createMenuItem(title: k.title, image: nil, representedObject: subItemInfo2)
                    let submenu = NSMenu()
                    for s in v {
                        submenu.addItem(withTitle: s, action: nil, keyEquivalent: "")
                    }
                    mnu_tag.submenu = submenu
                } else {
                    let label: String
                    if let d = item as? Date {
                        label = Self.dateFormatter.string(from: d)
                    } else if let n = item as? Int {
                        label = Self.numberFormatter.string(from: NSNumber(value: n)) ?? "\(n)"
                    } else if let n = item as? Int64 {
                        label = Self.numberFormatter.string(from: NSNumber(value: n)) ?? "\(n)"
                    } else if let n = item as? Float {
                        label = Self.numberFormatter.string(from: NSNumber(value: n)) ?? "\(n)"
                    } else if let n = item as? Double {
                        label = Self.numberFormatter.string(from: NSNumber(value: n)) ?? "\(n)"
                    } else {
                        label = "\(item)"
                    }
                    
                    if self.globalSettings?.isMetadataExpanded ?? true {
                        mnu_tag = self.createMenuItem(title: k.title, image: nil, representedObject: subItemInfo2)
                        mnu_tag.submenu = NSMenu()
                        mnu_tag.submenu!.addItem(self.createMenuItem(title: label, image: nil, representedObject: subItemInfo2))
                    } else {
                        mnu_tag = self.createMenuItem(title: "\(k.title): \(label)", image: nil, representedObject: subItemInfo2)
                    }
                }
                metadata_submenu.addItem(mnu_tag)
            }
            
            self.globalSettings?.isIconHidden = iconHidden
            
            let metadata_mnu = self.createMenuItem(title: NSLocalizedString("Spotlight", tableName: "LocalizableExt", comment: ""), image: item.menuItem.image, representedObject: item)
            metadata_mnu.submenu = metadata_submenu
            destination_sub_menu.addItem(metadata_mnu)
           
            return true
        case item.menuItem.template where item.menuItem.template.hasPrefix("[[file-modes:"):
            if self.mode == 0 && self.acl.isEmpty && self.extAttrs.isEmpty {
                return true
            }
            let t = item.menuItem.template.dropFirst(2).dropLast(2).split(separator: ":")
            let mnu = self.createMenuItem(title: self.getFormattedMode(withExtra: !t.contains("ext-attrs"), withACL: !t.contains("acl")), image: item.menuItem.image, representedObject: item)
            let sub_menu = NSMenu()
            if t.contains("acl") && !self.acl.isEmpty {
                let menu = NSMenu()
                let item2 = MenuItemInfo(fileType: item.fileType, index: item.index, item: Settings.MenuItem(image: "", template: "[[acl]]"), action: item.action, tag: item.tag, userInfo: item.userInfo)
                if self.processSpecialMenuItem(item2, inMenu: menu), let m = menu.items.first?.copy() as? NSMenuItem {
                    m.title = NSLocalizedString("Access Control List", tableName: "LocalizableExt", comment: "")
                    m.image = nil
                    sub_menu.addItem(m)
                }
            }
            if t.contains("ext-attrs") && !self.extAttrs.isEmpty {
                let menu = NSMenu()
                let item2 = MenuItemInfo(fileType: item.fileType, index: item.index, item: Settings.MenuItem(image: "", template: "[[ext-attributes]]"), action: item.action, tag: item.tag, userInfo: item.userInfo)
                if self.processSpecialMenuItem(item2, inMenu: menu), let m = menu.items.first?.copy() as? NSMenuItem {
                    m.image = nil
                    sub_menu.addItem(m)
                }
            }
            if !sub_menu.items.isEmpty {
                mnu.submenu = sub_menu
            }
            destination_sub_menu.addItem(mnu)
            return true
        case "[[ext-attributes]]":
            guard !self.extAttrs.isEmpty else {
                return true
            }
            let mnu = self.createMenuItem(title: NSLocalizedString("Extended Attributes", tableName: "LocalizableExt", comment: ""), image: item.menuItem.image, representedObject: item)
            let sub_menu = NSMenu()
            let names = self.extAttrs.keys.sorted(by: { $0.lowercased() < $1.lowercased() })
            for name in names {
                let attr = self.extAttrs[name]!
                var attr_item = item
                attr_item.userInfo["ext-attribute-name"] = name
                attr_item.userInfo["ext-attribute-value"] = attr
                let mnu_attr = self.createMenuItem(title: name, image: "no-space", representedObject: attr_item)
                if !attr.isEmpty {
                    mnu_attr.submenu = NSMenu()
                    mnu_attr.submenu?.addItem(self.createMenuItem(title: attr, image: "no-space", representedObject: attr_item))
                }
                sub_menu.addItem(mnu_attr)
            }
            mnu.submenu = sub_menu
            destination_sub_menu.addItem(mnu)
            return true
        default:
            if item.menuItem.template.hasPrefix("[[open-with:") {
                guard let path = String(item.menuItem.template.dropFirst(12).dropLast(2)).fromBase64(), !path.isEmpty else {
                    return true
                }
                let title = String(format: NSLocalizedString("Open with %@…", tableName: "LocalizableExt", comment: ""), FileManager.default.displayName(atPath: path))
                let mnu = self.createMenuItem(title: title, image: item.menuItem.image, representedObject: item)
                if let info = mnu.representedObject as? MenuItemInfo {
                    var info2 = info
                    info2.action = .openWith
                    info2.userInfo["application"] = path
                    mnu.representedObject = info2
                }
                if !(self.globalSettings?.isIconHidden ?? false) && item.menuItem.image.isEmpty {
                    let img = NSWorkspace.shared.icon(forFile: path).resized(to: NSSize(width: 16, height: 16))
                    mnu.image = img
                }
                mnu.toolTip = path
                destination_sub_menu.addItem(mnu)
                return true
            }
        }
        return super.processSpecialMenuItem(item, inMenu: destination_sub_menu)
    }
}
