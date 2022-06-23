//
//  TokenMetadata.swift
//  BoredExplorer
//
//  Created by Aiden Petersen on 1/05/22.
//

import UIKit

enum Section: Int, CaseIterable {
    case all
}

class TokenMetadata: Hashable {
    let id: Int
    let attributes: Dictionary<String, String>
    let thumbnailUrl: String?
    let imageUrl: String?
    let owner: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: TokenMetadata, rhs: TokenMetadata) -> Bool {
        return lhs.id == rhs.id
    }
    
    init( id: Int, thumbnailUrl: String? = nil, attributes: Dictionary<String, String>, imageUrl: String? = nil, owner: String? = nil) {
        self.thumbnailUrl = thumbnailUrl
        self.imageUrl = imageUrl
        self.id = id
        self.attributes = attributes
        self.owner = owner
    }
}
