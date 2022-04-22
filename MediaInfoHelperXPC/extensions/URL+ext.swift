//
//  URL+ext.swift
//  MediaInfo
//
//  Created by Sbarex on 22/03/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation

// https://stackoverflow.com/questions/38343186/write-extend-file-attributes-swift-example/38343753#38343753

extension URL {
    /// Get extended attribute.
    func extendedAttribute(forName name: String) throws -> Data  {

        let data = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> Data in

            // Determine attribute size:
            let length = getxattr(fileSystemPath, name, nil, 0, 0, 0)
            guard length >= 0 else { throw URL.posixError(errno) }

            // Create buffer with required size:
            var data = Data(count: length)

            // Retrieve attribute:
            let result =  data.withUnsafeMutableBytes { [count = data.count] in
                getxattr(fileSystemPath, name, $0.baseAddress, count, 0, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
            return data
        }
        return data
    }

    /// Set extended attribute.
    func setExtendedAttribute(data: Data, forName name: String) throws {

        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = data.withUnsafeBytes {
                setxattr(fileSystemPath, name, $0.baseAddress, data.count, 0, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }

    /// Remove extended attribute.
    func removeExtendedAttribute(forName name: String) throws {

        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = removexattr(fileSystemPath, name, 0)
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }

    /// Get list of all extended attributes.
    func listExtendedAttributes() throws -> [String] {

        let list = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> [String] in
            let length = listxattr(fileSystemPath, nil, 0, 0)
            guard length >= 0 else { throw URL.posixError(errno) }

            // Create buffer with required size:
            var namebuf = Array<CChar>(repeating: 0, count: length)

            // Retrieve attribute list:
            let result = listxattr(fileSystemPath, &namebuf, namebuf.count, 0)
            guard result >= 0 else { throw URL.posixError(errno) }

            // Extract attribute names:
            let list = namebuf.split(separator: 0).compactMap {
                $0.withUnsafeBufferPointer {
                    $0.withMemoryRebound(to: UInt8.self) {
                        String(bytes: $0, encoding: .utf8)
                    }
                }
            }
            return list
        }
        return list
    }

    /// Helper function to create an NSError from a Unix errno.
    private static func posixError(_ err: Int32) -> NSError {
        let s: String
        if let e = strerror(err) {
            s = String(cString: e)
        } else {
            s = "Error \(err)"
        }
        
        return NSError(domain: NSPOSIXErrorDomain, code: Int(err),
                       userInfo: [NSLocalizedDescriptionKey: s])
    }
}
