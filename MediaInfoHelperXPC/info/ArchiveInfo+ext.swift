//
//  ModelInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 03/06/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

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
        
        var link: String? = nil
        let type: ArchivedFileTypeEnum
        if filetype == FORMAT_AE_IFREG {
            type = .regular
            if let s = String(cString: archive_entry_hardlink(entry)) {
                link = s
            }
        } else if filetype == FORMAT_AE_IFLNK {
            type = .symblink
            if let s = String(cString: archive_entry_symlink(entry)) {
                link = s
            }
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
        
        self.init(
            fullpath: f,
            mode: String(cString: archive_entry_strmode(entry)) ?? "",
            cDate: archive_entry_ctime_is_set(entry) != 0 ? archive_entry_ctime(entry) : (archive_entry_birthtime_is_set(entry) != 0 ? archive_entry_birthtime(entry) : 0),
            mDate: archive_entry_mtime_is_set(entry) != 0 ? archive_entry_mtime(entry) : 0,
            aDate: archive_entry_atime_is_set(entry) != 0 ? archive_entry_atime(entry) : 0,
            type: type,
            size: (archive_entry_size_is_set(entry) != 0) ? archive_entry_size(entry) : 0,
            format: format,
            uid: archive_entry_uid(entry),
            uidName: String(cString: archive_entry_uname_utf8(entry)),
            gid: archive_entry_gid(entry),
            gidName: String(cString: archive_entry_gname_utf8(entry)),
            acl: String(cString: archive_entry_acl_to_text(entry, nil, 0)),
            flags: String(cString: archive_entry_fflags_text(entry)) ?? "",
            link: link,
            encrypted: archive_entry_is_encrypted(entry) != 0
        )
    }
}

enum ArchiveInfoError: Error {
    case open_error(message: String?, url: URL)
}

extension ArchiveInfo {
    convenience init(file: URL, limit: Int = 0) throws {
        let a = archive_read_new()
        defer {
            archive_read_free(a)
        }
        archive_read_support_filter_all(a)
        archive_read_support_format_all(a)
        
        let r = archive_read_open_filename(a, file.path, 10240)
        guard r == ARCHIVE_OK else {
            let s = String(cString: archive_error_string(a))
            print("ARCHIVE ERROR: \(s ?? "")")
            throw ArchiveInfoError.open_error(message: s, url: file)
        }
        
        let entry = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 1)
        defer {
            entry.deallocate()
        }

        var flatten_files: [ArchivedFile] = []
        var n_files = 0
        var files_size: Int64 = 0
        while archive_read_next_header(a, &entry.pointee) == ARCHIVE_OK {
            guard let entry = entry.pointee else {
                continue
            }
            
            if limit == 0 || n_files < limit {
                if let file = ArchivedFile(entry: entry, format: String(cString: archive_format_name(a)) ?? "") {
                    flatten_files.append(file)
                }
            }
            
            archive_read_data_skip(a) // Not required: libarchive will invoke it automatically if you request the next header without reading the data for the last entry
            
            n_files += 1
            files_size += (archive_entry_size_is_set(entry) != 0) ? archive_entry_size(entry) : 0
        }

        flatten_files.sort { (a, b) -> Bool in
            return a.fullPath < b.fullPath
        }
        
        // let compressionCode = archive_filter_code(a, 0)
        let compressionName = String(cString: archive_filter_name(a, 0)) ?? ""
        
        let organized_files = ArchivedFile.reorganize(files: flatten_files)
        
        self.init(file: file, compressionName: compressionName, files: organized_files, unlimitedFileCount: n_files, unlimitedFileSize: files_size)
    }
}
