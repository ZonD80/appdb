//
//  Details.swift
//  appdb
//
//  Created by ned on 19/02/2017.
//  Copyright © 2017 ned. All rights reserved.
//

import UIKit
import RealmSwift

class Details: LoadingTableView {
    
    weak var content: Object!
    var descriptionCollapsed: Bool = true
    var changelogCollapsed: Bool = true
    var reviewCollapsedForIndexPath : [IndexPath: Bool] = [:]
    var heightForIndexPath : [IndexPath: CGFloat] = [:]
    var indexForSegment: detailsSelectedSegmentState = .details
    var versions: [Version] = []
    
    var header: [DetailsCell] = []
    var details: [DetailsCell] = []
    
    var loadedLinks: Bool = false {
        didSet { if loadedLinks, let segment = tableView.headerView(forSection: 1) as? DetailsSegmentControl {
            segment.setLinksEnabled(true)
        }}
    }
    
    // Properties for dynamic load
    var loadDynamically: Bool = false
    var dynamicType: ItemType = .ios
    var dynamicTrackid: String = ""
    
    // Init dynamically - fetch info from API
    convenience init(type: ItemType, trackid: String) {
        self.init(style: .plain)
        
        loadDynamically = true
        dynamicType = type
        dynamicTrackid = trackid
    }
    
    // Init with content (app, cydia app or book)
    convenience init(content: Object) {
        self.init(style: .plain)

        self.content = content
        loadDynamically = false
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the 'Back' text on back button
        let backItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        
        setUp()

        if !loadDynamically {
            initializeCells()
            getLinks()
        } else {
            state = .loading
            showsErrorButton = false
            fetchInfo(type: dynamicType, trackid: dynamicTrackid)
        }

    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        switch indexForSegment {
            case .details, .reviews: return 2
            case .download: return 2 + (versions.isEmpty ? 1 : versions.count)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case 0: return header.count
            case 1:
                switch indexForSegment {
                    case .details: return details.count
                    case .reviews: return reviews.count + 1
                    case .download: return 0
                }
            default:
                switch indexForSegment {
                    case .details, .reviews: return 0
                    case .download: return versions.isEmpty ? 1 : versions[section-2].links.count
                }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
            case 0: return header[indexPath.row].height
            case 1:
                switch indexForSegment {
                    case .details: return details[indexPath.row].height
                    case .reviews: return indexPath.row == reviews.count ? UITableViewAutomaticDimension : DetailsReview.height
                    case .download: return 0
                }
            default:
                switch indexForSegment {
                    case .details, .reviews: return 0
                    case .download: return versions.isEmpty ? DetailsDownloadEmptyCell.height : DetailsDownload.height
                }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            case 0: return header[indexPath.row]
            case 1:
                switch indexForSegment {
                    case .details:
                        // DetailsDescription and DetailsChangelog need to be dynamic to have smooth expand
                        if details[indexPath.row] is DetailsDescription {
                            if let cell = tableView.dequeueReusableCell(withIdentifier: "description", for: indexPath) as? DetailsDescription {
                                cell.desc.collapsed = descriptionCollapsed
                                cell.configure(with: description_)
                                cell.desc.delegated = self
                                details[indexPath.row] = cell // ugly but needed to update height correctly
                                return cell
                            } else { return UITableViewCell() }
                        }
                        if details[indexPath.row] is DetailsChangelog {
                            if let cell = tableView.dequeueReusableCell(withIdentifier: "changelog", for: indexPath) as? DetailsChangelog {
                                cell.desc.collapsed = changelogCollapsed
                                cell.configure(type: contentType, changelog: changelog, updated: updatedDate)
                                cell.desc.delegated = self
                                details[indexPath.row] = cell // ugly but needed to update height correctly
                                return cell
                            } else { return UITableViewCell() }
                        }
                        // Otherwise, just return static cells
                        return details[indexPath.row]
                    case .reviews:
                        if indexPath.row == reviews.count { return DetailsPublisher("Reviews are from Apple's iTunes Store ©".localized()) }
                        if let cell = tableView.dequeueReusableCell(withIdentifier: "review", for: indexPath) as? DetailsReview {
                            cell.desc.collapsed = reviewCollapsedForIndexPath[indexPath] ?? true
                            cell.configure(with: reviews[indexPath.row])
                            cell.desc.delegated = self
                            return cell
                        } else { return UITableViewCell() }
                    case .download: return UITableViewCell()
                }
            default:
                switch indexForSegment {
                    case .details, .reviews: return UITableViewCell()
                    case .download:
                        if !versions.isEmpty {
                            let cell = tableView.dequeueReusableCell(withIdentifier: "download", for: indexPath) as! DetailsDownload
                            cell.configure(with: versions[indexPath.section-2].links[indexPath.row])
                            return cell
                        } else {
                            return DetailsDownloadEmptyCell("No links found.")
                        }
                }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if state != .done { return nil }
        if section == 1 {
            return DetailsSegmentControl(itemsForSegmentedControl, state: indexForSegment, enabled: loadedLinks, delegate: self)
        }
        if section > 1, indexForSegment == .download, !versions.isEmpty {
            return DetailsVersionHeader(versions[section-2].number, isLatest: versions[section-2].number == version)
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if state != .done { return 0 }
        if section == 1 { return DetailsSegmentControl.height }
        if section > 1, indexForSegment == .download, !versions.isEmpty { return DetailsVersionHeader.height }
        return 0
    }
    
}

////////////////////////////////
//  PROTOCOL IMPLEMENTATIONS  //
////////////////////////////////

//
//   MARK: - SwitchDetailsSegmentDelegate
//   Handle Details segment index change
//
extension Details: SwitchDetailsSegmentDelegate {
    func segmentSelected(_ state: detailsSelectedSegmentState) {
        indexForSegment = state
        tableView.reloadData()
    }
}

/* OLD WAY, probably need to use this on ios 8
 UIView.setAnimationsEnabled(false)
 tableView.beginUpdates()
 tableView.endUpdates()
 UIView.setAnimationsEnabled(true)
 */

//
//   MARK: - ElasticLabelDelegate
//   Expand cell when 'more' button is pressed
//
extension Details: ElasticLabelDelegate {
    func expand(_ label: ElasticLabel) {
        let point = label.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) as IndexPath? {
            switch indexForSegment {
            case .details:
                if details[indexPath.row] is DetailsDescription { descriptionCollapsed = false }
                else if details[indexPath.row] is DetailsChangelog { changelogCollapsed = false }
            case .reviews: reviewCollapsedForIndexPath[indexPath] = false
            case .download: break
            }
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}


//
//   MARK: - RelatedRedirectionDelegate
//   Push related item view controller
//
extension Details: RelatedRedirectionDelegate {
    func relatedItemSelected(trackid: String) {
        let vc = Details(type: contentType, trackid: trackid)
        // navigationController?.navigationBar.isTranslucent = false /* God damnit, Apple */
        navigationController?.pushViewController(vc, animated: true)
    }
}

//
//   MARK: - ScreenshotRedirectionDelegate
//   Present Full screenshots view controller with given index
//
extension Details: ScreenshotRedirectionDelegate {
    func screenshotImageSelected(with index: Int) {
        let vc = DetailsFullScreenshots(screenshots: screenshots, index: index)
        let nav = DetailsFullScreenshotsNavController(rootViewController: vc)
        present(nav, animated: true)
    }
}

//
//   MARK: - DynamicContentRedirection
//   Push details controller given type and trackid
//
extension Details: DynamicContentRedirection {
    func dynamicContentSelected(type: ItemType, id: String) {
        let vc = Details(type: type, trackid: id)
        navigationController?.pushViewController(vc, animated: true)
    }
}
