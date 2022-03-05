//
//  AnyCodable.swift
//  MediaInfo
//
//  Created by Sbarex on 02/03/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation

struct AnyCodable: Decodable {
  var value: Any

  struct CodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    init?(intValue: Int) {
      self.stringValue = "\(intValue)"
      self.intValue = intValue
    }
    init?(stringValue: String) { self.stringValue = stringValue }
  }

  init(value: Any) {
    self.value = value
  }

  init(from decoder: Decoder) throws {
    if let container = try? decoder.container(keyedBy: CodingKeys.self) {
      var result = [String: Any]()
      try container.allKeys.forEach { (key) throws in
        result[key.stringValue] = try container.decode(AnyCodable.self, forKey: key).value
      }
      value = result
    } else if var container = try? decoder.unkeyedContainer() {
      var result = [Any]()
      while !container.isAtEnd {
        result.append(try container.decode(AnyCodable.self).value)
      }
      value = result
    } else if let container = try? decoder.singleValueContainer() {
      if let intVal = try? container.decode(Int.self) {
        value = intVal
      } else if let doubleVal = try? container.decode(Double.self) {
        value = doubleVal
      } else if let boolVal = try? container.decode(Bool.self) {
        value = boolVal
      } else if let stringVal = try? container.decode(String.self) {
        value = stringVal
      } else {
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "the container contains nothing serialisable")
      }
    } else {
      throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not serialise"))
    }
  }
}

extension AnyCodable: Encodable {
  func encode(to encoder: Encoder) throws {
    if let array = value as? [Any] {
      var container = encoder.unkeyedContainer()
      for value in array {
        let decodable = AnyCodable(value: value)
        try container.encode(decodable)
      }
    } else if let dictionary = value as? [String: Any] {
      var container = encoder.container(keyedBy: CodingKeys.self)
      for (key, value) in dictionary {
        let codingKey = CodingKeys(stringValue: key)!
        let decodable = AnyCodable(value: value)
        try container.encode(decodable, forKey: codingKey)
      }
    } else {
      var container = encoder.singleValueContainer()
      if let intVal = value as? Int {
        try container.encode(intVal)
      } else if let doubleVal = value as? Double {
        try container.encode(doubleVal)
      } else if let boolVal = value as? Bool {
        try container.encode(boolVal)
      } else if let stringVal = value as? String {
        try container.encode(stringVal)
      } else {
        throw EncodingError.invalidValue(value, EncodingError.Context.init(codingPath: [], debugDescription: "The value is not encodable"))
      }

    }
  }
}
