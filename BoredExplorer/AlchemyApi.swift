//
//  AlchemyApi.swift
//  BoredExplorer
//
//  Created by Aiden Petersen on 28/04/22.
//

import Foundation

// TODO: would be cool to build these views in ios and expose them to react native, create UI components for react native to consume.
// ok yeah lets do an animation, have the project
// ok lets implement a start up animation
// lets have that page where we click on an item, then navigate to a detailed view of it. Should we be doing this in react native? Nah lets do native for now, should be able to get it done in 2 weeks, then can finish it. Ok next step is to improve the views and loading of them. Lets do that thing where we load 30 of them at a time
// TODO: move these somewhere else
let alchemyApiKey = ""
let boredApeContractAddress = "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D"
let mutantApeContractAddress = "0x60E4d786628Fea6478F785A6d7e704777c86a7c6"

struct GetNftsForCollectionResponse: Codable {
    struct Nft: Codable {
        struct Id: Codable {
            let tokenId: String
        }
        let id: Id
    }
    let nfts: [Nft]
    let nextToken: String?
    
    init(nfts: [Nft], nextToken: String?){
        self.nfts = nfts
        self.nextToken = nextToken
    }
}


func getNftIdsForCollection(_ startToken: String? = nil) async -> [Int] {
    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    urlComponents.host = "eth-mainnet.alchemyapi.io"
    urlComponents.path = "/v2/\(alchemyApiKey)/getNFTsForCollection"
    urlComponents.queryItems = [
        URLQueryItem(name: "contractAddress", value: boredApeContractAddress)
    ]
    if startToken != nil {
        urlComponents.queryItems?.append(URLQueryItem(name: "startToken", value: startToken))
    }
    
    guard let url = urlComponents.url else {
        return []
    }
    
    if let (data, _) = try? await URLSession.shared.data(from: url){
        if let responseObj = try? JSONDecoder().decode(GetNftsForCollectionResponse.self, from: data){
            var mappedNfts = responseObj.nfts.map { nft in
                return Int(nft.id.tokenId.dropFirst(2), radix: 16) ?? 0
            }
//            if (responseObj.nextToken != nil){
//                await mappedNfts.append(contentsOf: getNftIdsForCollection(responseObj.nextToken))
//            }
            return mappedNfts.dropLast(0)
        }
    }
    return []
}


struct Nft: Hashable {
    struct Attribute: Hashable {
        let value, traitType: String
    }
    let tokenId: Int
    let imageUrl: String
    let attributes: [Attribute]
    var imageData: Data? = nil
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
            return Nft(tokenId: tokenId, imageUrl: responseObj.media[0].gateway, attributes:  responseObj.metadata.attributes.map { attribute in Nft.Attribute(value: attribute.value, traitType: attribute.trait_type)})
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



func getNftsHelper() async throws -> [Nft] {
    let ids = await getNftIdsForCollection();
    return try await ids.asyncMap { id in
        print("getting nft: \(id)")
        return try await getNft(tokenId: id)
    }
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
