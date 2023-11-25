//
//  FlowerDetails.swift
//  WhatFlower
//
//  Created by Shay Dubrovsky on 25/11/2023.
//

import Foundation

struct FlowerDetails: Codable {
    let query: Query
}

//MARK: - Query
struct Query: Codable {
    let pageids: [String]
    let pages: [String: Pages]
}

//MARK: - Pages
struct Pages: Codable {
    let extract: String
    let thumbnail: Thumbnail
}

//MARK: - Thumbnail
struct Thumbnail: Codable {
    let source: String
}
