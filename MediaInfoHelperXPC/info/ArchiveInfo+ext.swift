//
//  ModelInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 03/06/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import os.log

extension ArchivedFile {
    convenience init?(entry: OpaquePointer, format: String) {
        guard let f = String(cString: archive_entry_pathname_utf8(entry)) else {
            return nil
        }
        // print(f)
        
        // let e_stat = archive_entry_stat(entry)
        
        let filetype = archive_entry_filetype(entry)
        
        let url = URL(fileURLWithPath: f, isDirectory: filetype == FORMAT_AE_IFDIR, relativeTo: URL(fileURLWithPath: "/"))
        if url.lastPathComponent == ".DS_Store" {
            return nil
        }
        
        let type: ArchivedFileTypeEnum
        if filetype == FORMAT_AE_IFREG {
            type = .regular
        } else if filetype == FORMAT_AE_IFLNK {
            type = .symblink
        } else if filetype == FORMAT_AE_IFSOCK {
            type = .socket
        } else if filetype == FORMAT_AE_IFCHR {
            type = .characterDevice
        } else if filetype == FORMAT_AE_IFBLK {
            type = .blockDevice
        } else if filetype == FORMAT_AE_IFDIR {
            type = .directory
        } else if filetype == FORMAT_AE_IFIFO {
            type = .namedPipe
        } else {
            type = .unknown
        }
        
        let hasSize = archive_entry_size_is_set(entry) != 0
        let size = hasSize ? archive_entry_size(entry) : -1
        let isEncrypted = archive_entry_is_encrypted(entry) != 0
        self.init(
            fullpath: f,
            type: type,
            size: size >= 0 ? Int(size) : nil,
            encrypted: isEncrypted,
            format: format
        )
    }
}

enum ArchiveInfoError: Error {
    case open_error(message: String?, url: URL)
}

extension ArchiveInfo {
    convenience init(file: URL, limit: Int = 0) throws {
        let time = CFAbsoluteTimeGetCurrent()
        let timeoutLimit: CFAbsoluteTime = time + Settings.infoExtractionTimeout
        
        os_log("Fetch info for archive %{private}@ with LibArchive…", log: OSLog.infoExtraction, type: .debug, file.path)
        
        let a = archive_read_new()
        defer {
            archive_read_free(a)
        }
        archive_read_support_filter_all(a)
        archive_read_support_format_all(a)
        archive_read_support_format_empty(a)
        archive_read_support_format_raw(a)
        
        let r = archive_read_open_filename(a, file.path, 10240)
        guard r == ARCHIVE_OK else {
            let s = String(cString: archive_error_string(a))
            os_log("Archive error: %{public}@", log: OSLog.infoExtraction, type: .error, s ?? "")
            throw ArchiveInfoError.open_error(message: s, url: file)
        }
        
        let entry = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 1)
        defer {
            entry.deallocate()
        }

        var flatten_files: [ArchivedFile] = []
        var n_files = 0
        var files_size: Int64 = 0
        var totalSizeIsLimited = false
        var totalFileIsLimited = false
        var limited = false
        var hasSize = false
        
        while archive_read_next_header(a, &entry.pointee) == ARCHIVE_OK {
            guard let entry = entry.pointee else {
                continue
            }
            
            if limit == 0 || n_files < limit {
                if let file = ArchivedFile(entry: entry, format: String(cString: archive_format_name(a)) ?? "") {
                    flatten_files.append(file)
                }
            } else {
                limited = true
            }
            
            archive_read_data_skip(a) // Not required: libarchive will invoke it automatically if you request the next header without reading the data for the last entry
            
            n_files += 1
            if archive_entry_size_is_set(entry) != 0 {
                files_size += archive_entry_size(entry)
                hasSize = true
            } else {
                totalSizeIsLimited = true
            }
            
            let t = CFAbsoluteTimeGetCurrent()
            guard t < timeoutLimit else {
                os_log("Archive parsing was aborted due to a timeout!", log: OSLog.infoExtraction, type: .error)
                
                totalSizeIsLimited = true
                totalFileIsLimited = true
                break
            }
        }

        flatten_files.sort { (a, b) -> Bool in
            return a.fullPath < b.fullPath
        }
        
        // let compressionCode = archive_filter_code(a, 0)
        var compressionNames: [String] = []
        for i in Int32(0) ..< archive_filter_count(a) {
            if let s = String(cString: archive_filter_name(a, i)), s != "none" {
                compressionNames.append(s)
            }
        }
        let compressionName = compressionNames.joined(separator: " / ")
        
        if compressionName == "gzip" && flatten_files.count==1 && flatten_files.first!.name == "data" {
            flatten_files.first!.url = flatten_files.first!.url.deletingLastPathComponent().appendingPathComponent(file.deletingPathExtension().lastPathComponent)
        }
        
        let organized_files = ArchivedFile.reorganize(files: flatten_files)
        
        let archive = ArchivedFile(fullpath: file.path, type: .regular, size: 0, encrypted: false)
        archive.files = organized_files
        
        os_log("Archive info fetched with LibArchive in %{public}lf seconds.", log: OSLog.infoExtraction, type: .info, CFAbsoluteTimeGetCurrent() - time)
        self.init(
            file: file,
            compressionName: compressionName,
            archive: archive,
            unlimitedFileCount: n_files,
            unlimitedFileSize: hasSize ? Int(files_size) : -1,
            isTotalSizePartial: totalSizeIsLimited,
            isTotalFilePartial: totalFileIsLimited,
            isPartial: limited
        )
    }
}
