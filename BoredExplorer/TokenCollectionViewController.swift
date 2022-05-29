//
//  TokenCollectionViewController.swift
//  BoredExplorer
//
//  Created by Aiden Petersen on 29/05/22.
//

import Foundation
import UIKit

// We should initialize a cache with the desired image size
class TokenCollectionViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching, UICollectionViewDelegateFlowLayout {
    
    let numColumns = 2.0
    let cardSpacing = 16.0;
    let cardBorderWidth = 1.0
    let radius = 16.0
    // Todo: 135 needs to be calculated dynamically
    let tokenCache = TokenCache(imageSize: CGSize(width: UIScreen.main.scale * 150, height: UIScreen.main.scale * 150))
    
    var dataSource: UICollectionViewDiffableDataSource<Section, TokenItem>! = nil

    private var nftItems = [TokenItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, TokenItem> { (cell, indexPath, item) in
            let imageTag = 1;
            let ownerTag = 2
            
            var imageView: UIImageView?
            var ownerView: UILabel?
            
            if cell.contentView.subviews.count == 0 {
                let newCellView = UIView(frame: cell.bounds);
                newCellView.layer.cornerRadius = self.radius
                newCellView.layer.borderWidth = self.cardBorderWidth
                newCellView.layer.borderColor = CGColor(gray: 0.8, alpha: 1.0)
                cell.contentView.addSubview(newCellView);
                
                // Token image
                let image = UIImageView()
                image.tag = imageTag
                imageView = image
                newCellView.addSubview(image)
                image.translatesAutoresizingMaskIntoConstraints = false
                let widthConstant = (self.cardSpacing + self.cardBorderWidth) * 2
                image.widthAnchor.constraint(equalTo: newCellView.widthAnchor, constant: -(widthConstant)).isActive = true
                image.heightAnchor.constraint(equalTo: newCellView.widthAnchor, multiplier: 0.8).isActive = true
                image.centerXAnchor.constraint(equalTo: newCellView.centerXAnchor).isActive = true
                image.topAnchor.constraint(equalTo: newCellView.topAnchor, constant: 8).isActive = true
                image.layer.cornerRadius = self.radius
//                Need to match borders of the card, below is not working on real devices
//                image.contentMode = .scaleAspectFit
//                image.clipsToBounds = true
                
                // Token owner title
                let ownerTitle = UILabel();
                newCellView.addSubview(ownerTitle)
                
                ownerTitle.translatesAutoresizingMaskIntoConstraints = false
                ownerTitle.text = "Owner"
                ownerTitle.font = .systemFont(ofSize: 10, weight: .medium)
                ownerTitle.textColor = UIColor(white: 0.5, alpha: 1.0)
                ownerTitle.leftAnchor.constraint(equalTo: image.leftAnchor).isActive = true
                ownerTitle.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 10).isActive = true
                
                let ownerValue = UILabel();
                ownerValue.tag = ownerTag
                ownerView = ownerValue
                newCellView.addSubview(ownerValue)
                ownerValue.translatesAutoresizingMaskIntoConstraints = false
                ownerValue.text = item.owner
                ownerValue.font = .systemFont(ofSize: 12, weight: .black)
                ownerValue.textColor = UIColor(white: 0.1, alpha: 1.0)
                ownerValue.leftAnchor.constraint(equalTo: ownerTitle.leftAnchor).isActive = true
                ownerValue.topAnchor.constraint(equalTo: ownerTitle.bottomAnchor, constant: 0).isActive = true
                ownerValue.widthAnchor.constraint(equalTo: image.widthAnchor).isActive = true
            } else {
                imageView = cell.contentView.viewWithTag(imageTag) as? UIImageView
                ownerView = cell.contentView.viewWithTag(ownerTag) as? UILabel
            }
            
            imageView?.image = item.tokenImage
            ownerView?.text = item.owner
            
            
            Task {
                let cachedImage = try await self.tokenCache.load(tokenId: item.id)
                    if cachedImage != item.tokenImage {
                        var updatedSnapshot = self.dataSource.snapshot()
                        if let datasourceIndex = updatedSnapshot.indexOfItem(item) {
                            let newItem = self.nftItems[datasourceIndex]
                            newItem.tokenImage = cachedImage
                            updatedSnapshot.reloadItems([newItem])
                            await self.dataSource.apply(updatedSnapshot, animatingDifferences: true)
                    }
                }
            }
            
            Task {
                let ownerResult = try await getOwner(tokenId: item.id)
                    if ownerResult != item.owner {
                        var updatedSnapshot = self.dataSource.snapshot()
                        if let datasourceIndex = updatedSnapshot.indexOfItem(item) {
                            let newItem = self.nftItems[datasourceIndex]
                            newItem.owner = ownerResult
                            updatedSnapshot.reloadItems([newItem])
                            await self.dataSource.apply(updatedSnapshot, animatingDifferences: true)
                    }
                }
            }
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
    
    // FlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing = (numColumns + 1) * cardSpacing
        let itemWidth = (self.view.frame.width - spacing) / numColumns
        return CGSize(width: itemWidth, height: 240)
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
        print("cancel prefetching for items at \(indexPaths)")
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        print("prefetching for items at \(indexPaths)")
        indexPaths.forEach { indexPath in
            let tokenId = self.nftItems[indexPath.row].id
            tokenCache.prefetch(tokenId: tokenId)
        }
    }
}
