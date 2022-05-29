//
//  ViewController.swift
//  BoredExplorer
//
//  Created by Aiden Petersen on 23/04/22.
//


import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        
        let stackView = UIStackView()
        stackView.backgroundColor = .yellow
        view.addSubview(stackView);
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        stackView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        stackView.axis = .vertical
        stackView.alignment = .trailing


        let tokenCollectionView = TokenCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
        self.addChild(tokenCollectionView)
        stackView.addArrangedSubview(tokenCollectionView.view)
        tokenCollectionView.didMove(toParent: self)

        tokenCollectionView.view.translatesAutoresizingMaskIntoConstraints = false
        tokenCollectionView.view.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        tokenCollectionView.view.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: 0.9).isActive = true
    }
}
