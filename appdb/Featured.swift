//
//  Featured.swift
//  appdb
//
//  Created by ned on 11/10/2016.
//  Copyright © 2016 ned. All rights reserved.
//

import UIKit
import AlamofireImage
import RealmSwift
import Cartography

protocol ChangeCategory {
    func reloadViewAfterCategoryChange(id: String, type: ItemType)
}

class Featured: LoadingTableView, ChangeCategory, UIPopoverPresentationControllerDelegate {
    
    let cells : [FeaturedCell] = [
        ItemCollection(id: .cydia, title: "🚀 Custom Apps", fullSeparator: true),
        Dummy(),
        ItemCollection(id: .iosNew, title: "🎁 New and Noteworthy"),
        ItemCollection(id: .iosPaid, title: "💰 Top Paid", fullSeparator: true),
        Dummy(),
        ItemCollection(id: .iosPopular, title: "🃏 Popular Today"),
        ItemCollection(id: .iosGames, title: "🎈 Best Games", fullSeparator: true),
        Dummy(),
        ItemCollection(id: .books, title: "📚 Top Books", fullSeparator: true),
        Copyright()
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up
        title = "Featured"
        
        // Register cells
        registerCells()
        
        // Add categories button
        let categoriesButton = UIBarButtonItem(title: "Categories", style: .plain, target: self, action:#selector(Featured.openCategories(_:)))
        navigationItem.leftBarButtonItem = categoriesButton
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        // List Genres and enable button on completion
        API.listGenres( completion: { success in self.navigationItem.leftBarButtonItem?.isEnabled = success } )

        // Wait for data to be fetched, reload tableView on completion
        reloadTableWhenReady()
        
    }
    
    // MARK: - Load Initial Data
    
    func reloadTableWhenReady() {
        
        let itemCells = cells.flatMap{$0 as? ItemCollection}
        if itemCells.count != (itemCells.filter{$0.response.success == true}.count) {
            if !(itemCells.filter{$0.response.hasErrors==true}.isEmpty) {
                showErrorMessage(text: "Cannot connect to appdb.")
            } else {
                // Not ready, retrying in 0.2 seconds
                delay(0.2) { self.reloadTableWhenReady() }
            }
        } else {
            
            // Set layout scroll direction (Xcode gives bs logs if I don't do it here, smh)
            for cell in itemCells {
                if let layout = cell.collectionView?.collectionViewLayout as? FlowLayout { layout.scrollDirection = .horizontal }
            }
            
            // Add banner
            addBanner()
            
            // Works around crazy cell bugs on rotation, enables preloading
            tableView.estimatedRowHeight = 32
            tableView.rowHeight = UITableViewAutomaticDimension
            
            // Reload tableView, hide spinner
            loaded = true
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loaded ? cells.count : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return loaded ? cells[indexPath.row] : UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return loaded ? cells[indexPath.row].height : 0
    }
    
    // MARK: - Open categories
    
    func openCategories(_ sender: UIBarButtonItem) {
        let categoriesViewController = Categories()
        categoriesViewController.delegate = self
        let nav = UINavigationController(rootViewController: categoriesViewController)
        nav.modalPresentationStyle = .popover
        nav.preferredContentSize = CGSize(width: 350, height: 500)
        if let popover = nav.popoverPresentationController {
            popover.delegate = self
            popover.sourceView = sender.value(forKey: "view") as! UIView?
            popover.sourceRect = (sender.value(forKey: "view") as! UIView!).bounds
        }
        present(nav, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Popover on ipad, modal on iphone 
        return .fullScreen
    }
    
    // MARK: - Reload view after category change
    
    func reloadViewAfterCategoryChange(id: String, type: ItemType) {
        for cell in cells {
            if let collection = cell as? ItemCollection {
                collection.reloadAfterCategoryChange(id: id, type: type)
            }
        }
        
    }

}
