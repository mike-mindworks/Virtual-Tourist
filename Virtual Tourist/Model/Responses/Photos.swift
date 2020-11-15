//
//  Photos.swift
//  Virtual Tourist
//
//  Created by Mike Allan on 2020-10-22.
//

import Foundation

struct Photos: Codable, Equatable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [Photo]
}
