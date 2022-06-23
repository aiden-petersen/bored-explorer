# BoredExplorer
Explore NFTs collections like Bored Ape Yacht Club

An iOS app which uses UIKit, UICollectionView, ViewController, async networking and caching, NFTs, alchemy API.

The app uses the alchemy API to query the tokens in the bored ape smart contract. For each token, it pulls down a thumbnail sized image and gets the 
owner of the token to display in the UICollection view. The small images allow for easy caching and when we actually go to the token page, we pull 
down the full res image.

Demo:

https://user-images.githubusercontent.com/11483212/175294043-900c4bb2-2d0b-40f6-93c6-9e8a3a6f40b5.mov
