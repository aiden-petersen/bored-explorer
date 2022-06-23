//
//  TokenCell.swift
//  BoredExplorer
//
//  Created by Aiden Petersen on 1/06/22.
//

import Foundation
import UIKit

class TokenCell: UICollectionViewCell {
    let cardSpacing = 16.0;
    let cardBorderWidth = 1.0
    let radius = 16.0
    let ownerView = UILabel();
    let imageView = UIImageView()
    let tokenIdView = UILabel();

    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        let newCellView = UIView();
        contentView.addSubview(newCellView);
        newCellView.backgroundColor = .quaternarySystemFill
        newCellView.translatesAutoresizingMaskIntoConstraints = false
        newCellView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        newCellView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        newCellView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        newCellView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        newCellView.layer.cornerRadius = self.radius
        
        
        // Token image
        newCellView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstant = (self.cardSpacing) * 2
        imageView.widthAnchor.constraint(equalTo: newCellView.widthAnchor, constant: -(widthConstant)).isActive = true
        imageView.heightAnchor.constraint(equalTo: newCellView.widthAnchor, multiplier: 0.8).isActive = true
        imageView.centerXAnchor.constraint(equalTo: newCellView.centerXAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: newCellView.topAnchor, constant: 8).isActive = true
        imageView.layer.cornerRadius = self.radius
        imageView.clipsToBounds = true

        // Token owner title
        let ownerTitle = UILabel();
        newCellView.addSubview(ownerTitle)

        ownerTitle.translatesAutoresizingMaskIntoConstraints = false
        ownerTitle.text = "Owner"
        ownerTitle.font = .systemFont(ofSize: 10, weight: .medium)
        ownerTitle.textColor = .secondaryLabel
        ownerTitle.leftAnchor.constraint(equalTo: imageView.leftAnchor).isActive = true
        ownerTitle.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10).isActive = true

        newCellView.addSubview(ownerView)
        ownerView.translatesAutoresizingMaskIntoConstraints = false
        ownerView.text = "Loading..."
        ownerView.font = .systemFont(ofSize: 12, weight: .black)
        ownerView.textColor = .label
        ownerView.leftAnchor.constraint(equalTo: ownerTitle.leftAnchor).isActive = true
        ownerView.topAnchor.constraint(equalTo: ownerTitle.bottomAnchor, constant: 0).isActive = true
        ownerView.widthAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        
        // Token ID title
        let tokenIdTitle = UILabel();
        newCellView.addSubview(tokenIdTitle)

        tokenIdTitle.translatesAutoresizingMaskIntoConstraints = false
        tokenIdTitle.text = "ID"
        tokenIdTitle.font = .systemFont(ofSize: 10, weight: .medium)
        tokenIdTitle.textColor = .secondaryLabel
        tokenIdTitle.leftAnchor.constraint(equalTo: imageView.leftAnchor).isActive = true
        tokenIdTitle.topAnchor.constraint(equalTo: ownerView.bottomAnchor, constant: 6).isActive = true

        newCellView.addSubview(tokenIdView)
        tokenIdView.translatesAutoresizingMaskIntoConstraints = false
        tokenIdView.text = "Loading..."
        tokenIdView.font = .systemFont(ofSize: 12, weight: .black)
        tokenIdView.textColor = .label
        tokenIdView.leftAnchor.constraint(equalTo: tokenIdTitle.leftAnchor).isActive = true
        tokenIdView.topAnchor.constraint(equalTo: tokenIdTitle.bottomAnchor, constant: 0).isActive = true
        tokenIdView.widthAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
