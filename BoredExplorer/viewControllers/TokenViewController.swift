//
//  TokenViewController.swift
//  BoredExplorer
//
//  Created by Aiden Petersen on 14/06/22.
//

import Foundation
import UIKit

class TokenViewController: UIViewController {
    private let imageView = UIImageView()
    private let stackView = UIStackView()
    private let attributesView = UIStackView()
    let titleLabel = UILabel()
    
    private var tokenMetadata: TokenMetadata? {
        didSet {
            if let tokenId = tokenMetadata?.id {
                titleLabel.text = "Bored Ape #\(tokenId)"
            }
            
            attributesView.arrangedSubviews.forEach { view in
                attributesView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            
            tokenMetadata?.attributes.forEach { (key, value) in
                let attributeTitle = UILabel()
                attributesView.addArrangedSubview(attributeTitle)
                attributeTitle.text = key
                attributeTitle.translatesAutoresizingMaskIntoConstraints = false
                attributeTitle.textColor = .secondaryLabel
                attributeTitle.font = .systemFont(ofSize: 10, weight: .medium)
                
                let attributeValue = UILabel()
                attributesView.addArrangedSubview(attributeValue)
                attributeValue.text = value
                attributeValue.translatesAutoresizingMaskIntoConstraints = false
                attributeValue.font = .systemFont(ofSize: 16, weight: .black)
                attributeValue.textColor = .label
                
                let spacer = UIView()
                attributesView.addArrangedSubview(spacer)
                spacer.translatesAutoresizingMaskIntoConstraints = false
                spacer.heightAnchor.constraint(equalToConstant: 10).isActive = true
            }
            
            // We display thumbnail but then fetch full res image to display
            Task {
                guard let url = tokenMetadata?.imageUrl, let imageUrl = URL(string: url) else { return }
                
                let (data, response) = try await URLSession.shared.data(from: imageUrl)
                
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
                
                guard let image = UIImage(data: data) else {
                    return
                }
                
                // Crop image because it has rounded edges
                let cropRect = CGRect(
                    x: 8,
                    y: 8,
                    width: image.size.width - 2 * 8,
                    height: image.size.height - 2 * 8
                ).integral

                // Center crop the image
                let sourceCGImage = image.cgImage!
                let croppedCGImage = sourceCGImage.cropping(
                    to: cropRect
                )!
                let croppedImage = UIImage(
                    cgImage: croppedCGImage,
                    scale: image.imageRendererFormat.scale,
                    orientation: image.imageOrientation
                )
                imageView.image = croppedImage
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.topItem?.backButtonTitle = " "
        
        view.backgroundColor = .systemBackground

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        stackView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        stackView.axis = .vertical
        stackView.alignment = .center
        
        stackView.addArrangedSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        
        let titleView = UIView()
        stackView.addArrangedSubview(titleView)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        titleView.heightAnchor.constraint(equalToConstant: 76).isActive = true
        
        titleView.addSubview(titleLabel)
        titleLabel.font = .systemFont(ofSize: 32.0, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: titleView.topAnchor, constant: 10).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: titleView.leftAnchor, constant: 10).isActive = true
        
        
        stackView.addArrangedSubview(attributesView)
        attributesView.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 4, right: 14)
        attributesView.translatesAutoresizingMaskIntoConstraints = false
        attributesView.isLayoutMarginsRelativeArrangement = true
        attributesView.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.9).isActive = true
        attributesView.axis = .vertical
        attributesView.layer.cornerRadius = 8
        attributesView.backgroundColor = .quaternarySystemFill
        
        let stackFiller = UIStackView()
        stackView.addArrangedSubview(stackFiller)
    }
    
    
    func setTokenAttributes(_ metadata: TokenMetadata, _ image: UIImage){
        self.tokenMetadata = metadata
        self.imageView.image = image
    }
}
