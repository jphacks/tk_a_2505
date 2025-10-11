//
//  ProfileModel.swift
//  escape
//
//  Created by Thanasan Kumdee on 8/10/2568 BE.
//

import Foundation

struct Profile: Decodable {
    let username: String?

    enum CodingKeys: String, CodingKey {
        case username
    }
}

struct UpdateProfileParams: Encodable {
    let username: String

    enum CodingKeys: String, CodingKey {
        case username
    }
}
