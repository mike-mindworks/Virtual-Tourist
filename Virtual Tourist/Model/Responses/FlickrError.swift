//
//  FlickrError.swift
//  Virtual Tourist
//
//  Created by Mike Allan on 2020-10-22.
//

import Foundation

struct FlickrError: Codable {
    let stat: String
    let code: Int
    let message: String
}
extension FlickrError: LocalizedError {
    var errorDescription: String? {
        return message
    }
}
