//
//  MoodSessionFull.swift
//  YOGURT
//
//  Created by Влад Соколов on 02.05.2025.
//

import Foundation

struct MoodSessionFull: Codable {
    let start: String
    let end: String
    let valence: Double
    public let valenceDescription: String
    let kind: String
    let labels: [String]
    let associations: [String]
    let shortDescription: String?
    let longDescription: String?
    let rawMetadata: [String: String]
}
