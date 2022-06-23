//
//  AlchemyApi.swift
//  BoredExplorer
//
//  Created by Aiden Petersen on 28/04/22.
//

import Foundation
import UIKit

// TODO: move these somewhere else
let alchemyApiKey = ""
let boredApeContractAddress = "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D"
let mutantApeContractAddress = "0x60E4d786628Fea6478F785A6d7e704777c86a7c6"

struct GetTokenMetadataForCollectionResponse: Codable {
    struct Token: Codable {
        struct Id: Codable {
            let tokenId: String
        }
        struct Media: Codable {
            let gateway: String
            let thumbnail: String?
        }
        struct Metadata: Codable {
            struct Attribute: Codable {
                let value: String
                let trait_type: String
            }
            let attributes: [Attribute]
        }
        let id: Id
        let media: [Media]
        let metadata: Metadata
    }
    let nfts: [Token]
    let nextToken: String?
    
    init(nfts: [Token], nextToken: String? = nil){
        self.nfts = nfts
        self.nextToken = nextToken
    }
}


func getTokenMetadataForCollection(_ startToken: String? = nil) async -> GetTokenMetadataForCollectionResponse {
    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    urlComponents.host = "eth-mainnet.alchemyapi.io"
    urlComponents.path = "/v2/\(alchemyApiKey)/getNFTsForCollection"
    urlComponents.queryItems = [
        URLQueryItem(name: "contractAddress", value: boredApeContractAddress),
        URLQueryItem(name: "withMetadata", value: "true")
    ]
    if startToken != nil {
        urlComponents.queryItems?.append(URLQueryItem(name: "startToken", value: startToken))
    }
    
    guard let url = urlComponents.url else {
        return GetTokenMetadataForCollectionResponse(nfts: [])
    }
    
    if let (data, _) = try? await URLSession.shared.data(from: url){
        if let responseObj = try? JSONDecoder().decode(GetTokenMetadataForCollectionResponse.self, from: data){
            return GetTokenMetadataForCollectionResponse(nfts: responseObj.nfts, nextToken: responseObj.nextToken)
        }
    }
    return GetTokenMetadataForCollectionResponse(nfts: [])
}


struct Nft: Hashable {
    let tokenId: Int
    let imageUrl: String
    var imageData: Data?
    let attributes: Dictionary<String, String>
}

enum GetNftError: Error {
    case UrlComponentError
    case RetrievalError
}

func getNft(tokenId: Int) async throws -> Nft {
    struct GetNftResponse: Codable {
        struct Metadata: Codable {
            struct Attribute: Codable {
                let value, trait_type: String
            }
            let image: String
            let attributes: [Attribute]
        }
        
        struct Media: Codable {
            let raw, gateway: String
        }
        let metadata: Metadata
        let media: [Media]


        init(metadata: Metadata, media: [Media]) {
            self.metadata = metadata
            self.media = media
        }
    }
    
    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    urlComponents.host = "eth-mainnet.alchemyapi.io"
    urlComponents.path = "/v2/\(alchemyApiKey)/getNFTMetadata"
    urlComponents.queryItems = [
        URLQueryItem(name: "contractAddress", value: boredApeContractAddress),
        URLQueryItem(name: "tokenId", value: String(tokenId))
    ]

    
    guard let url = urlComponents.url else {
        throw GetNftError.UrlComponentError
    }
    
    if let (data, _) = try? await URLSession.shared.data(from: url){
        if let responseObj = try? JSONDecoder().decode(GetNftResponse.self, from: data){
            var attributes = Dictionary<String, String>()
            responseObj.metadata.attributes.forEach { attribute in
                attributes[attribute.trait_type] = attribute.value
            }
            
            return Nft(tokenId: tokenId, imageUrl: responseObj.media[0].gateway, attributes: attributes)
        }
    }
    throw GetNftError.RetrievalError
}


enum GetOwnerError: Error {
    case UrlComponentError
    case RetrievalError
}

func getOwner(tokenId: Int) async throws -> String {
    struct GetOwnersResponse: Codable {
        let owners: [String]
    }
    
    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    urlComponents.host = "eth-mainnet.alchemyapi.io"
    urlComponents.path = "/v2/\(alchemyApiKey)/getOwnersForToken"
    urlComponents.queryItems = [
        URLQueryItem(name: "contractAddress", value: boredApeContractAddress),
        URLQueryItem(name: "tokenId", value: String(tokenId))
    ]

    guard let url = urlComponents.url else {
        throw GetOwnerError.UrlComponentError
    }
    
    if let (data, _) = try? await URLSession.shared.data(from: url){
        if let responseObj = try? JSONDecoder().decode(GetOwnersResponse.self, from: data){
            return responseObj.owners[0]
        }
    }
    throw GetOwnerError.RetrievalError
}

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}
