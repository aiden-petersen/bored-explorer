//
//  TokenCollectionViewController.swift
//  BoredExplorer
//
//  Created by Aiden Petersen on 29/05/22.
//

import Foundation
import UIKit

class TokenCollectionViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching, UICollectionViewDelegateFlowLayout {
    let numColumns = 2.0
    let cardSpacing = 16.0;
    let cardBorderWidth = 1.0
    let radius = 16.0
    let thumbnailCache = TokenThumbnailCache()
    let ownerCache = TokenOwnerCache()
    let tokenVC = TokenViewController()
    
    var dataSource: UICollectionViewDiffableDataSource<Section, TokenMetadata>! = nil

    private var tokenMetadata = [TokenMetadata]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.navigationBar.prefersLargeTitles = true
        self.title = "Bored Explorer"
    
        let cellRegistration = UICollectionView.CellRegistration<TokenCell, TokenMetadata> { (cell, indexPath, tokenMetadata) in
            cell.tokenIdView.text = "\(tokenMetadata.id)"
            if let tokenImage = self.thumbnailCache.token(id: tokenMetadata.id as NSNumber) {
                cell.imageView.image = tokenImage
            } else {
                cell.imageView.image = nil
                Task {
                    let cachedImage = try await self.thumbnailCache.load(tokenMetadata: tokenMetadata)
                    var updatedSnapshot = self.dataSource.snapshot()
                    updatedSnapshot.reloadItems([tokenMetadata])
                    await self.dataSource.apply(updatedSnapshot, animatingDifferences: true)
                }
            }
            
            if let tokenOwner = self.ownerCache.owner(id: tokenMetadata.id as NSNumber) {
                cell.ownerView.text = tokenOwner
            } else {
                cell.ownerView.text = "loading..."
                Task {
                    let cachedOwner = try await self.ownerCache.load(tokenId: tokenMetadata.id )
                    var updatedSnapshot = self.dataSource.snapshot()
                    updatedSnapshot.reloadItems([tokenMetadata])
                    await self.dataSource.apply(updatedSnapshot, animatingDifferences: true)
                }
            }
        }

        dataSource = UICollectionViewDiffableDataSource<Section, TokenMetadata>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, tokenMetadata: TokenMetadata) -> TokenCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: tokenMetadata)
        }
        collectionView.prefetchDataSource = self

        Task {
            if tokenMetadata.isEmpty {
                let response = await getTokenMetadataForCollection()
                self.tokenMetadata = response.nfts.map { nft in
                    // Remove hex prefix to get ID
                    let id = Int(nft.id.tokenId.dropFirst(2), radix: 16) ?? 0
                    let thumbnailUrl = nft.media[0].thumbnail
                    let imageUrl = nft.media[0].gateway
                    var attributes = Dictionary<String, String>()
                    nft.metadata.attributes.forEach { attribute in
                        attributes[attribute.trait_type] = attribute.value
                    }
                    return TokenMetadata(id: id, thumbnailUrl: thumbnailUrl, attributes: attributes, imageUrl: imageUrl)
                }

                var initialSnapshot = NSDiffableDataSourceSnapshot<Section, TokenMetadata>()
                initialSnapshot.appendSections(Section.allCases)
                initialSnapshot.appendItems(self.tokenMetadata, toSection: Section.all)
                await self.dataSource.apply(initialSnapshot, animatingDifferences: false)
            }
        }
    }
    
    // FlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing = (numColumns + 1) * cardSpacing
        let itemWidth = (self.view.frame.width - spacing) / numColumns
        let itemHeight = 230.0 // TODO: need to calc this
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                          layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cardSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                          layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: cardSpacing, left: cardSpacing, bottom: cardSpacing, right: cardSpacing)
    }
    
    // DataSourcePrefetching
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
//        print("cancel prefetching for items at \(indexPaths)")
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        print("prefetching for items at \(indexPaths)")
        indexPaths.forEach { indexPath in
            thumbnailCache.prefetch(tokenMetadata: self.tokenMetadata[indexPath.row])
            ownerCache.prefetch(tokenId: self.tokenMetadata[indexPath.row].id)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let tokenMetadata = dataSource.itemIdentifier(for: indexPath), let image = thumbnailCache.token(id: tokenMetadata.id as NSNumber) else {
            return;
        }
        
        navigationController?.pushViewController(tokenVC, animated: true)
        tokenVC.setTokenAttributes(tokenMetadata, image)
    }
}
