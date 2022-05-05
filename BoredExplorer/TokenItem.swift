//
//  NftItem.swift
//  BoredExplorer
//
//  Created by Aiden Petersen on 1/05/22.
//

import UIKit

enum Section: Int, CaseIterable {
    case all
}

class TokenItem: Hashable {
    var tokenImage: UIImage?
    let id: Int
    let identifier = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    static func == (lhs: TokenItem, rhs: TokenItem) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    init( id: Int, tokenImage: UIImage? = nil) {
        self.tokenImage = tokenImage
        self.id = id
    }

}
