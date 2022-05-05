//
//  ViewController.swift
//  BoredExplorer
//
//  Created by Aiden Petersen on 23/04/22.
//


import UIKit

class ViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        print("prefetching for items at \(indexPaths)")
        indexPaths.forEach { indexPath in
            let tokenId = self.nftItems[indexPath.row].id
            TokenCache.publicCache.prefetch(tokenId: tokenId)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        print("cancel prefetching for items at \(indexPaths)")
    }
    
    var dataSource: UICollectionViewDiffableDataSource<Section, TokenItem>! = nil
    
    private var nftItems = [TokenItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, TokenItem> { (cell, indexPath, item) in
            var content = UIListContentConfiguration.cell()
            content.directionalLayoutMargins = .zero
            content.axesPreservingSuperviewLayoutMargins = []
            content.image = item.tokenImage
            content.text = "BAYC"
            content.secondaryText = "#\(item.id)"
            content.textProperties.alignment = .center
            content.secondaryTextProperties.alignment = .center
            
            Task {
                let image = try await TokenCache.publicCache.load(tokenId: item.id)
                if image != item.tokenImage {
                    var updatedSnapshot = self.dataSource.snapshot()
                    if let datasourceIndex = updatedSnapshot.indexOfItem(item) {
                        let newItem = self.nftItems[datasourceIndex]
                        newItem.tokenImage = image
                        updatedSnapshot.reloadItems([newItem])
                        await self.dataSource.apply(updatedSnapshot, animatingDifferences: true)
                    }
                }
            }
            cell.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource<Section, TokenItem>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: TokenItem) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        collectionView.prefetchDataSource = self
        
        Task {
            if nftItems.isEmpty {
                let nftIds = await getNftIdsForCollection()
                for tokenId in nftIds {
                    self.nftItems.append(TokenItem(id: tokenId))
                }
                var initialSnapshot = NSDiffableDataSourceSnapshot<Section, TokenItem>()
                initialSnapshot.appendSections(Section.allCases)
                initialSnapshot.appendItems(self.nftItems, toSection: Section.all)
                await self.dataSource.apply(initialSnapshot, animatingDifferences: true)
            }
        }
    }
}
