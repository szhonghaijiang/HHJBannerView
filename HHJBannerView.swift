//
//  HHJBannerView.swift
//  HHJBannerView
//
//  Created by bu88 on 2018/8/31.
//  Copyright © 2018年 HHJ. All rights reserved.
//

import UIKit

enum HHJBannerViewDirection {
    case left
    case right
}

class HHJBannerView: UIView, UIScrollViewDelegate {
    var currentPageIndicatorTintColor = UIColor(red: 0x08/255, green: 0xB7/255, blue: 0x9E/255, alpha: 1.0) {
        didSet {
            pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor
        }
    }
    var pageControlerTintColor = UIColor.gray {
        didSet {
            pageControl.pageIndicatorTintColor = pageControlerTintColor
        }
    }
    var bannerDidSelectedBlock: (_ index: Int) -> Void
    var dataSourceBlock: (_ button: UIButton, _ index: Int, _ finishBlock:@escaping () -> Void) -> Void
    var imageCount: Int
    
    fileprivate var imageViews = [HHJBannerImageView]()
    fileprivate let scrollView = UIScrollView()
    fileprivate var currentImageView: HHJBannerImageView!
    fileprivate let pageControl = UIPageControl()
    weak fileprivate var scrollViewTimer: Timer?
    
    init(frame: CGRect, imageCount: Int, dataSource:@escaping (_ button: UIButton, _ index: Int, _ finishBlock:@escaping () -> Void) -> Void, delegate:@escaping (_ index: Int) -> Void) {
        self.imageCount = imageCount
        self.dataSourceBlock = dataSource
        self.bannerDidSelectedBlock = delegate
        super.init(frame: frame)
        loadSubView()
    }
    
    //    init(frame: CGRect, bannerModels: [Banner], block:@escaping (_ index: Int) -> Void) {
    //        self.bannerModels = bannerModels
    //        self.bannerDidSelectedBlock = block
    //        super.init(frame: frame)
    //        loadSubView()
    //    }
    
    /// 初始化所有视图
    fileprivate func loadSubView() {
        scrollView.frame = bounds
        scrollView.contentSize = CGSize(width: 3*scrollView.bounds.size.width, height: 0)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        addSubview(scrollView)
        for _ in 0..<3 {
            let imageView = HHJBannerImageView(frame: scrollView.bounds)
            imageView.addTarget(self, action: #selector(HHJBannerView.didSelectedBanner(sender:)), for: .touchUpInside)
            imageViews.append(imageView)
            scrollView.addSubview(imageView)
        }
        
        pageControl.currentPage = 0;
        pageControl.pageIndicatorTintColor = pageControlerTintColor
        self.pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor
        self.pageControl.backgroundColor = UIColor.clear
        addSubview(pageControl)
        reloadSubView()
    }
    
    
    /// 当获得新的数据调用该方法刷新一下显示，第一次创建本对象时不需要调用，会自动调用
    func reloadSubView() {
        scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        if imageCount <= 1 {
            scrollView.isScrollEnabled = false;
            invalidateAutoScrollViewTimer()
        } else {
            scrollView.isScrollEnabled = true
            setTimer()
        }
        for (index, imageView) in imageViews.enumerated() {
            var bannerModelIndex = index-1
            if bannerModelIndex < 0 {
                bannerModelIndex = imageCount-1
            } else if (bannerModelIndex >= imageCount) {
                bannerModelIndex = 0
            }
            setButton(imageView, forImageAt: bannerModelIndex)
            imageView.index = bannerModelIndex
            imageView.frame = CGRect(x: scrollView.bounds.size.width * CGFloat(index), y: imageView.frame.origin.y, width: imageView.bounds.size.width, height: imageView.bounds.size.height)
            if imageView.frame.origin.x == scrollView.contentOffset.x {
                currentImageView = imageView
            }
        }
        pageControl.numberOfPages = imageCount
        pageControl.currentPage = 0
        let pageControlSizeHeight:CGFloat = 21
        let pageControlSize = pageControl.size(forNumberOfPages: imageCount)
        pageControl.frame = CGRect(x: (bounds.size.width-pageControlSize.width)*0.5, y: bounds.size.height-pageControlSizeHeight, width: pageControlSize.width, height: pageControlSizeHeight)
        pageControl.addTarget(self, action: #selector(HHJBannerView.pageControlDidSelected), for: .valueChanged)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //监听滑动事件，修改显示的各种东西
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x > 0 && scrollView.contentOffset.x < 2*scrollView.bounds.size.width {
            return
        }
        
        if scrollView.contentOffset.x <= 0 {
            getCurrentIamgeView(direction:.left)
            for (_, imageView) in imageViews.enumerated() {
                if imageView.frame.origin.x-scrollView.contentOffset.x<scrollView.bounds.size.width*1.5 {
                    imageView.frame = CGRect(x: imageView.frame.origin.x+scrollView.bounds.size.width, y: imageView.frame.origin.y, width: imageView.bounds.size.width, height: imageView.bounds.size.height)
                } else {
                    imageView.frame = CGRect(x: 0, y: imageView.frame.origin.y, width: imageView.bounds.size.width, height: imageView.bounds.size.height)
                    var index = currentImageView.index-1
                    if index < 0 {
                        index = imageCount-1
                    }
                    imageView.index = index
                    setButton(imageView, forImageAt: index)
                }
            }
        } else if scrollView.contentOffset.x >= 2*scrollView.bounds.size.width {
            getCurrentIamgeView(direction: .right)
            for (_, imageView) in imageViews.enumerated() {
                if scrollView.contentOffset.x-imageView.frame.origin.x<scrollView.bounds.size.width*1.5 {
                    imageView.frame = CGRect(x: imageView.frame.origin.x-scrollView.bounds.size.width, y: imageView.frame.origin.y, width: imageView.bounds.size.width, height: imageView.bounds.size.height)
                } else {
                    imageView.frame = CGRect(x: scrollView.bounds.size.width * 2, y: imageView.frame.origin.y, width: imageView.bounds.size.width, height: imageView.bounds.size.height)
                    var index = currentImageView.index+1
                    if index >= imageCount {
                        index = 0
                    }
                    imageView.index = index
                    setButton(imageView, forImageAt: index)
                }
            }
        }
        scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
    }
    
    fileprivate func getCurrentIamgeView(direction: HHJBannerViewDirection) {
        var currentImageViewX: CGFloat = 0
        if direction == .right {
            currentImageViewX = 2*scrollView.bounds.size.width
        }
        for (_, imageView) in imageViews.enumerated() {
            if (imageView.frame.origin.x == currentImageViewX) {
                currentImageView = imageView
                setPageControlCurrentIndex()
                break
            }
        }
    }
    
    private func setButton(_ button: HHJBannerImageView, forImageAt index:Int) {
        dataSourceBlock(button, index) {[weak button] in
            guard let weakButton = button else {
                return
            }
            weakButton.reloadImageViewContent()
        }
    }
    
    fileprivate func setPageControlCurrentIndex() {
        pageControl.currentPage = currentImageView.index
    }
    
    @objc fileprivate func pageControlDidSelected() {
        
    }
    
    
    /// 创建自动滑动事件
    fileprivate func setTimer() {
        invalidateAutoScrollViewTimer()
        scrollViewTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(HHJBannerView.autoScrollViewToNext), userInfo: nil, repeats: true)
    }
    
    //移除Timer
    func invalidateAutoScrollViewTimer() {
        if let timer = scrollViewTimer {
            timer.invalidate()
        }
    }
    
    //自动滑动事件
    @objc fileprivate func autoScrollViewToNext() {
        scrollView.setContentOffset(CGPoint(x: scrollView.bounds.size.width*2, y: 0), animated: true)
    }
    
    @objc fileprivate func didSelectedBanner(sender: UIButton) {
        bannerDidSelectedBlock(currentImageView.index)
    }
    
    //移除Timer
    override func removeFromSuperview() {
        invalidateAutoScrollViewTimer()
        super.removeFromSuperview()
    }
    
    //用户手动滑动时，关闭自动滑动定时器
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        invalidateAutoScrollViewTimer()
    }
    //用户手动滑动结束时，打开自动滑动定时器
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        setTimer()
    }
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}

fileprivate class HHJBannerImageView: UIButton {
    func reloadImageViewContent() {
        if let iv = imageView, iv.contentMode != .scaleAspectFill {
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 248.0/255.0, green: 248.0/255.0, blue: 248.0/255.0, alpha: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var index = 0
}