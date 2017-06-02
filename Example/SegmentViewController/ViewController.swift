//
//  ViewController.swift
//  SegmentViewController
//
//  Created by Nemanja on 5/21/17.
//  Copyright © 2017 Nemanja. All rights reserved.
//

import UIKit
import SegmentViewController

class ViewController: SegmentViewController, SegmentViewControllerDataSource, SegmentViewControllerDelegate {
    
    
    
    var viewControllers = [UIViewController]()
    var tagTitles = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.dataSource = self
        self.delegate = self
        self.padding = 10
        self.leadingPadding = 10
        self.trailingPadding = 10
        self.defaultDisplayPageIndex = 0
        self.tabAnimationType = .whileScrolling;
        self.indicatorColor = .red
        
        let firstVC = FirstViewController()
        let secondVC = SecondViewController()
        let thirdVC = ThirdViewController()
        let forthVC = ForthViewController()
        
        self.viewControllers = [firstVC, secondVC, thirdVC, forthVC]
        tagTitles = ["Page tab 1","Page tab 2","Page tab 3", "Page tab 4"]
        
        
    }
    
    // GLViewPagerViewControllerDataSource
    
    
    func numberOfSegmentItemsIn(_ segmentViewController: SegmentViewController) -> Int {
        return viewControllers.count
    }
    
    
    func segmentViewController(_ segmentViewController: SegmentViewController, viewForSegmentAtIndex index: Int) -> UIView {
        
        let label = UILabel()
        label.text = tagTitles[Int(index)]
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }
    
    
    func contentViewControllerForTabAt(_ index: Int, pager: SegmentViewController) -> UIViewController {
        return self.viewControllers[index]
    }
    
    
    // GLViewPagerViewControllerDelegate
    
    
    
    
    func segmentViewController(_ segmentViewController: SegmentViewController, didChangeSegmentTo index: Int, fromIndex: Int) {
        
        
        let prevLabel = segmentViewController.tabViewAt(fromIndex) as! UILabel
        let currentLabel = segmentViewController.tabViewAt(index) as! UILabel
        
        
        prevLabel.textColor = .gray
        currentLabel.textColor = .black
        
    }
    
    
    
    func segmentViewController(_ segmentViewController: SegmentViewController, willChangeTabTo index: Int, fromIndex: Int, withTransitionProgress: CGFloat) {
        
    }
    
    
    func segmentViewController(_ segmentViewController: SegmentViewController, widthForSegmentAtIndex index: Int) -> CGFloat {
        
        let prototypeLabel = UILabel()
        prototypeLabel.text = self.tagTitles[index]
        prototypeLabel.textAlignment = .center
        prototypeLabel.font = UIFont.systemFont(ofSize: 16.0)
        return prototypeLabel.intrinsicContentSize.width
        
        
    }
    
    
    
    
}

