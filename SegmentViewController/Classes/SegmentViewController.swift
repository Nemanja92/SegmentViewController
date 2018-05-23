/*
 Copyright 2017 Nemanja Ignjatovic
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


import UIKit


public enum TabAnimationType {
    case none
    case whileScrolling
    case end
}



open class SegmentViewController: UIViewController, UIPageViewControllerDelegate,UIPageViewControllerDataSource,UIScrollViewDelegate {
    
    public var delegate: SegmentViewControllerDelegate!
    public var dataSource: SegmentViewControllerDataSource!
    
    private var fixTabWidth = false
    
    
    public var tabTagBegin = 10
    public var backgroundColor = UIColor.white
    public var tabFontDefault = UIFont.systemFont(ofSize: 12)
    public var tabFontSelected = UIFont.systemFont(ofSize: 12)
    public var tabTextColorDefault = UIColor.brown
    public var tabTextColorSelected = UIColor.brown
    public var tabWidth: CGFloat = 128.0
    public var tabHeight: CGFloat = 44.0
    public var tabAnimationType = TabAnimationType.none
    public var indicatorColor = UIColor.red
    public var indicatorHeight: CGFloat = 2.0
    public var indicatorWidth: CGFloat = 128.0
    public var padding: CGFloat = 0.0
    public var leadingPadding: CGFloat = 0.0
    public var trailingPadding: CGFloat = 0.0
    public var fixIndicatorWidth = true
    public var defaultDisplayPageIndex: Int = 0
    public var animationTabDuration: CGFloat = 0.3
    public var pageViewCtrlBackgroundColor  = UIColor.white
    public var tabContentBackgroundColor = UIColor.clear
    public var pageViewController = UIPageViewController()
    public var contentViewControllers = [UIViewController]()
    public var contentViews = [UIView]()
    public var tabContentView = UIScrollView()
    public var tabViews: [UIView] = []
    public var indicatorView = UIView()
    public var needsReload: Bool = true
    public var leftTabOffsetWidth: CGFloat = 0
    public var rightTabOffsetWidth: CGFloat = 0
    public var leftMinusCurrentWidth: CGFloat = 0
    public var rightMinusCurrentWidth: CGFloat = 0
    public var currentPageIndex: Int = 0
    public var enableTabAnimationWhileScrolling: Bool = true
    
    
    // life cycle
    
    convenience init() {
        self.init()
        commonInit()
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
        
    }
    
    
    
    override open func loadView() {
        self.view = UIView(frame: UIScreen.main.bounds)
        self.view.backgroundColor = backgroundColor
        self.view.addSubview(setuptabContentView())
        self.tabContentView.addSubview(indicatorView)
        self.view.addSubview(self.setupPageViewController().view)
    }
    
    
    override open func viewWillLayoutSubviews() {
        
        reloadDataIfNeed()
        layoutSubviews()
        
        var tabViewsTotalWidth: CGFloat = 0.0
        
        _ = tabViews.map {
            
            tabViewsTotalWidth += $0.frame.width
        }
        
        if tabViewsTotalWidth < tabContentView.frame.width {
            let centerOffset = CGPoint(x: (tabContentView.contentSize.width - tabContentView.frame.size.width) / 2, y: 0)
            tabContentView.setContentOffset(centerOffset, animated: false)
        }
        
        selectTab(tabIndex: currentPageIndex, animate: true)
        
        
        
    }
    
    
    //UIPageViewControllerDataSource
    
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let index: Int = self.contentViewControllers.index(of: viewController)!
        
        if index == 0 {
            return nil
        }
        return self.contentViewControllers[index-1]
    }
    
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let index: Int = self.contentViewControllers.index(of: viewController)!
        if index == self.contentViewControllers.count-1 {
            return nil
        }
        return self.contentViewControllers[index+1]
        
    }
    
    
    // UIPageViewControllerDelegate
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if completed {
            let currentPageIndex: Int = self.contentViewControllers.index(of: pageViewController.viewControllers![0])!
            let prevPageIndex: Int = self.contentViewControllers.index(of: previousViewControllers[0])!
            print("Current Page Index = \(currentPageIndex)")
            self.setActiveTabIndex(currentPageIndex)
            self.calculateTabOffsetWidth(currentPageIndex)
            self.currentPageIndex = currentPageIndex
            
            delegate.segmentViewController(self, didChangeSegmentTo: currentPageIndex, fromIndex: prevPageIndex)
            
            
            if self.tabAnimationType == .whileScrolling {
                enableTabAnimationWhileScrolling = false
            }
        }
        
        
    }
    
    
    
    // UIScrollViewDelegate
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.tabAnimationType == .whileScrolling {
            enableTabAnimationWhileScrolling = true
        }
        
    }
    
    
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.tabAnimationType == .whileScrolling {
            enableTabAnimationWhileScrolling = false
        }
    }
    
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.tabAnimationType == .whileScrolling && enableTabAnimationWhileScrolling {
            let scale: CGFloat = abs((scrollView.contentOffset.x-scrollView.frame.size.width)/scrollView.frame.size.width)
            var offset: CGFloat = 0
            var indicationAnimationWidth: CGFloat = 0
            let currentPageIndex: Int = self.currentPageIndex
            var indicatorViewFrame: CGRect = self.caculateTabViewFrame(currentPageIndex)
            
            
            /** left to right */
            if scrollView.contentOffset.x-scrollView.frame.size.width > 0 {
                offset = rightTabOffsetWidth*scale
                indicationAnimationWidth = indicatorViewFrame.size.width+rightMinusCurrentWidth*scale
                
                
                
                
                delegate.segmentViewController(self, willChangeTabTo: (currentPageIndex+1) > self.tabViews.count-1 ? currentPageIndex : currentPageIndex+1, fromIndex: currentPageIndex, withTransitionProgress: scale)
                
            }
                /** right to left */
            else {
                
                offset = -leftTabOffsetWidth*scale
                indicationAnimationWidth = indicatorViewFrame.size.width+leftMinusCurrentWidth*scale
                
                
                delegate.segmentViewController(self, willChangeTabTo: currentPageIndex == 0 ? 0 : currentPageIndex-1, fromIndex: currentPageIndex, withTransitionProgress: scale)
                
                
            }
            indicatorViewFrame.origin.x += offset
            indicatorViewFrame.size.width = indicationAnimationWidth
            self.indicatorView.frame = indicatorViewFrame
        }
    }
    
    
    
    // user events
    
    
    @objc func tapInTabView(_ sender: UITapGestureRecognizer) {
        let tabIndex: Int = sender.view!.tag-tabTagBegin
        self.selectTab(tabIndex: tabIndex, animate: false)
    }
    
    // functions
    
    
    
    func commonInit() {
        
        pageViewController.delegate = self
        tabContentView.delegate = self
        
        
        self.setNeedsReload()
        
    }
    
    
    func calculateTabOffsetWidth(_ index: Int) {
        
        let currentTabIndex: Int = index
        let currentTabView: UIView = self.tabViews[currentTabIndex]
        
        
        let optPreviousTabView: UIView? = (currentTabIndex  > 0) ? self.tabViews[currentTabIndex - 1]:nil
        
        let optAfterTabView: UIView? = (currentTabIndex < self.tabViews.count - 1) ? self.tabViews[currentTabIndex + 1] : nil
        
        
        if currentTabIndex == 0 {
            
            guard let afterTabView = optAfterTabView else { return }
            
            leftTabOffsetWidth = self.leadingPadding
            rightTabOffsetWidth = afterTabView.frame.minX-currentTabView.frame.minX
            leftMinusCurrentWidth = 0.0
            rightMinusCurrentWidth = afterTabView.frame.width-currentTabView.frame.width
        } else if currentTabIndex == self.tabViews.count-1 {
            
            guard let previousTabView = optPreviousTabView else { return }
            
            leftTabOffsetWidth = currentTabView.frame.minX-previousTabView.frame.minX
            rightTabOffsetWidth = self.trailingPadding
            leftMinusCurrentWidth = previousTabView.frame.width-currentTabView.frame.width
            rightMinusCurrentWidth = 0.0
        }else {
            
            guard let previousTabView = optPreviousTabView else { return }
            guard let afterTabView = optAfterTabView else { return }
            
            leftTabOffsetWidth = currentTabView.frame.minX-previousTabView.frame.minX
            rightTabOffsetWidth = afterTabView.frame.minX-currentTabView.frame.minX
            leftMinusCurrentWidth = previousTabView.frame.width-currentTabView.frame.width
            rightMinusCurrentWidth = afterTabView.frame.width-currentTabView.frame.width
            
            
        }
        
        print("left tab offset = \(leftTabOffsetWidth),right tab offset = \(rightTabOffsetWidth)")
        
    }
    
    
    func setActiveTabIndex(_ index: Int) {
        
        assert(index <= self.tabViews.count-1, "Default display page index is bigger than amount of  view controller")
        let frameOfTabView: CGRect = self.caculateTabViewFrame(index)
        if self.tabAnimationType == .end || self.tabAnimationType == .whileScrolling {
            UIView.animate(withDuration: TimeInterval(self.animationTabDuration), animations: {	self.indicatorView.frame = frameOfTabView
                
            })
        } else if self.tabAnimationType == .none {
            self.indicatorView.frame = frameOfTabView
        }
        /** Center active tab in scrollview */
        let tabView: UIView = self.tabViews[index]
        var frame: CGRect = tabView.frame
        
        if true {
            frame.origin.x += (frame.width/2)
            frame.origin.x -= self.tabContentView.frame.width/2
            frame.size.width = self.tabContentView.frame.width
            if frame.origin.x < 0 {
                frame.origin.x = 0
            }
            if (frame.origin.x+frame.width) > self.tabContentView.contentSize.width {
                frame.origin.x = (self.tabContentView.contentSize.width-self.tabContentView.frame.width)
            }
        }
        
        
        self.tabContentView.scrollRectToVisible(frame, animated: true)
        
    }
    
    
    
    func setActivePageIndex(_ index: Int) {
        
        
        
        assert(index <= self.contentViewControllers.count-1, "Default display page index is bigger than amount of  view controller")
        var direction = UIPageViewControllerNavigationDirection.reverse
        if index > currentPageIndex {
            direction = UIPageViewControllerNavigationDirection.forward
        }
        
        
        
        pageViewController.setViewControllers([contentViewControllers[index]], direction: direction, animated: true, completion: nil)
        
        
    }
    
    
    func caculateTabViewFrame(_ index: Int) -> CGRect {
        
        var frameOfTabView: CGRect = .zero
        if self.fixTabWidth {
            frameOfTabView.origin.x = CGFloat(index*self.fixTabWidth.hashValue)+(CGFloat(index)*self.padding)+self.leadingPadding
            frameOfTabView.origin.y = self.tabContentView.frame.size.height-self.indicatorHeight
            frameOfTabView.size.height = self.indicatorHeight
            frameOfTabView.size.width = self.tabWidth
        } else {
            
            
            let previousTabView : UIView = (index > 0) ? self.tabViews[index-1] : UIView()
            
            
            
            var x: CGFloat = 0
            if index == 0 {
                x += self.leadingPadding
            } else {
                x += self.padding
                
            }
            x += previousTabView.frame.maxX
            frameOfTabView = CGRect.zero
            frameOfTabView.origin.x = x
            frameOfTabView.origin.y = self.tabHeight-self.indicatorHeight
            frameOfTabView.size.height = self.indicatorHeight
            frameOfTabView.size.width = self.getTabWidthAtIndex(index)
            
        }
        return frameOfTabView
    }
    
    
    func getTabWidthAtIndex(_ index: Int) -> CGFloat {
        
        var tabWidth: CGFloat = 0.0
        let tabView: UIView = self.tabViews[index]
        
        
        tabWidth = delegate.segmentViewController(self, widthForSegmentAtIndex: index)
        
        
        return tabWidth == 0 ? tabView.intrinsicContentSize.width : tabWidth
        
        
    }
    
    
    
    
    func layoutSubviews() {
        
        let topLayoutGuide: CGFloat = self.topLayoutGuide.length
        let bottomLayoutGuide: CGFloat = self.bottomLayoutGuide.length
        /** TabContentView */
        var tabContentViewFrame: CGRect = self.tabContentView.frame
        tabContentViewFrame.size.width = self.view.bounds.size.width
        tabContentViewFrame.size.height = tabHeight
        tabContentViewFrame.origin.x = 0
        tabContentViewFrame.origin.y = topLayoutGuide
        self.tabContentView.frame = tabContentViewFrame
        /** PageViewController */
        var pageViewCtrlFrame: CGRect = self.pageViewController.view.frame
        pageViewCtrlFrame.size.width = self.view.bounds.size.width
        pageViewCtrlFrame.size.height = self.view.bounds.size.height-topLayoutGuide-bottomLayoutGuide-self.tabContentView.frame.height
        pageViewCtrlFrame.origin.x = 0
        pageViewCtrlFrame.origin.y = topLayoutGuide+self.tabContentView.frame.height
        self.pageViewController.view.frame = pageViewCtrlFrame
        
        
        
    }
    
    
    public func tabViewAt(_ index: Int) -> UIView {
        return self.tabViews[index]
    }
    
    
    
    
    
    func setNeedsReload() {
        
        needsReload = true
        //        view.setNeedsLayout()
        view.layoutSubviews()
        
        
    }
    
    func reloadDataIfNeed() {
        if needsReload {
            self.reloadData()
        }
    }
    
    
    func selectTab(tabIndex: Int, animate: Bool) {
        
        let prevPageIndex: Int = currentPageIndex
        self.disableViewPagerScroll()
        self.setActivePageIndex(tabIndex)
        self.setActiveTabIndex(tabIndex)
        self.calculateTabOffsetWidth(tabIndex)
        currentPageIndex = tabIndex
        enableTabAnimationWhileScrolling = false
        self.enableViewPagerScroll()
        
        delegate.segmentViewController(self, didChangeSegmentTo: currentPageIndex, fromIndex: prevPageIndex)
        
        
    }
    
    
    
    func setupPageViewController() -> UIPageViewController {
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        
        pageViewController.view.backgroundColor = pageViewCtrlBackgroundColor
        pageViewController.dataSource = self
        pageViewController.delegate = self
        for view in pageViewController.view.subviews {
            if view.isKind(of: UIScrollView.self) {
                (view as! UIScrollView).delegate = self
            }
        }
        return pageViewController
        
    }
    
    
    func disableViewPagerScroll() {
        for view in pageViewController.view.subviews {
            if view.isKind(of: UIScrollView.self) {
                (view as! UIScrollView).isScrollEnabled = false
            }
        }
    }
    
    func enableViewPagerScroll() {
        for view in pageViewController.view.subviews {
            if view.isKind(of: UIScrollView.self) {
                (view as! UIScrollView).isScrollEnabled = true
            }
        }
    }
    
    func setuptabContentView() -> UIScrollView {
        tabContentView = UIScrollView(frame: CGRect.zero)
        tabContentView.backgroundColor = tabContentBackgroundColor
        tabContentView.showsVerticalScrollIndicator = true
        tabContentView.showsHorizontalScrollIndicator = true
        tabContentView.autoresizingMask = .flexibleWidth
        tabContentView.scrollsToTop = false
        tabContentView.showsHorizontalScrollIndicator = false
        tabContentView.showsVerticalScrollIndicator = false
        tabContentView.bounces = false
        tabContentView.contentSize = CGSize.zero
        
        
        return tabContentView
    }
    
    
    
    
    
    
    func reloadData() {
        
        
        self.indicatorView.backgroundColor = self.indicatorColor;
        
        self.tabViews.removeAll()
        
        _ = tabContentView.subviews.map { if $0.isKind(of: UIView.self) {
            $0.removeFromSuperview()
            }
        }
        
        
        
        var numberOfTabs: Int = 0
        numberOfTabs = dataSource.numberOfSegmentItemsIn(self)
        
        if !self.tabContentView.subviews.contains(self.indicatorView) && numberOfTabs > 0 {
            self.tabContentView.addSubview(self.indicatorView)
        }
        var preTabView: UIView? = nil
        var tabContentWidth: CGFloat = 0
        for i: Int in 0  ..< numberOfTabs  {
            
            let tabView: UIView = dataSource.segmentViewController(self, viewForSegmentAtIndex: i)
            assert(tabView.isKind(of: UIView.self), "This is not an UIView subclass")
            self.tabContentView.addSubview(tabView)
            self.tabViews.append(tabView)
            
            tabView.tag = tabTagBegin+i
            tabView.isUserInteractionEnabled = true
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapInTabView(_:)))
            
            tabView.addGestureRecognizer(tapGesture)
            if preTabView == nil {
                var rect: CGRect = tabView.frame
                rect.size.width = self.fixTabWidth ? self.tabWidth : self.getTabWidthAtIndex(i)
                rect.size.height = self.tabHeight
                rect.origin.x = self.leadingPadding
                rect.origin.y = 0
                tabView.frame = rect
                preTabView = tabView
                tabContentWidth += self.fixTabWidth ? self.tabWidth : self.getTabWidthAtIndex(i)+self.leadingPadding
            } else {
                var rect: CGRect = tabView.frame
                rect.size.width = self.fixTabWidth ? self.tabWidth : self.getTabWidthAtIndex(i)
                rect.size.height = self.tabHeight
                rect.origin.x = (preTabView?.frame)!.maxX+self.padding
                rect.origin.y = 0
                tabView.frame = rect
                preTabView = tabView
                tabContentWidth += ((self.fixTabWidth ? self.tabWidth : self.getTabWidthAtIndex(i))+self.padding)
                if i == numberOfTabs-1 {
                    tabContentWidth += self.trailingPadding
                }
                
            }
        }
        self.tabContentView.contentSize = CGSize(width: tabContentWidth, height: tabHeight)
        
        self.contentViews.removeAll()
        self.contentViewControllers.removeAll()
        
        for i in 0  ..< numberOfTabs  {
            
            
            let viewController: UIViewController = dataSource.contentViewControllerForTabAt!(i, pager: self)
            
            
            
            
            assert(viewController.isKind(of: UIViewController.self), "This is not an UIViewController subclass")
            self.contentViewControllers.append(viewController)
        }
        assert(self.defaultDisplayPageIndex <= self.contentViewControllers.count-1, "Default display page index is bigger than amount of  view controller")
        self.setActivePageIndex(self.defaultDisplayPageIndex)
        self.setActiveTabIndex(self.defaultDisplayPageIndex)
        self.calculateTabOffsetWidth(self.defaultDisplayPageIndex)
        currentPageIndex = self.defaultDisplayPageIndex
        
        
        
        delegate.segmentViewController(self, didChangeSegmentTo: currentPageIndex, fromIndex: self.defaultDisplayPageIndex)
        
        needsReload = false
        
        
        
        
    }
    
    
    
    
}

@objc public protocol SegmentViewControllerDataSource {
    
    func numberOfSegmentItemsIn(_ segmentViewController: SegmentViewController) -> Int
    
    
    func segmentViewController(_ segmentViewController: SegmentViewController, viewForSegmentAtIndex index: Int) -> UIView
    
    @objc optional func contentViewControllerForTabAt(_ index: Int, pager: SegmentViewController) -> UIViewController
    
    @objc optional func contentViewForTabAtIndex(_ index: Int, pager: SegmentViewController) -> UIView
    
    
}

public protocol SegmentViewControllerDelegate {
    
    
    func segmentViewController(_ segmentViewController: SegmentViewController, didChangeSegmentTo index: Int, fromIndex: Int)
    
    
    func segmentViewController(_ segmentViewController: SegmentViewController, willChangeTabTo index: Int, fromIndex: Int, withTransitionProgress: CGFloat)
    
    
    func segmentViewController(_ segmentViewController: SegmentViewController, widthForSegmentAtIndex index: Int) -> CGFloat
    
    
    
    
}

