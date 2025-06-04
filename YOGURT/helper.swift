//
//  helper.swift
//  YOGURT
//
//  Created by Влад Соколов on 02.05.2025.
//

import Foundation

func encodeToJSON<T: Encodable>(_ value: T) -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(value) {
        return String(data: data, encoding: .utf8)
    }
    return nil
}
