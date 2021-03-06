//
//  OkPagerView.swift
//  OkDataSources
//
//  Created by Roberto Frontado on 20/2/16.
//  Copyright © 2016 Roberto Frontado. All rights reserved.
//

import UIKit

public protocol OkPagerViewDataSource: class {

  func viewControllerAtIndex(_ index: Int) -> UIViewController?
  func numberOfPages() -> Int?
}

public protocol OkPagerViewDelegate: class {

  func onPageSelected(_ viewController: UIViewController, index: Int)
}

public protocol OkPagerViewAnimationDelegate: class {

  func onScrolling(_ viewController: UIViewController, index: Int, offset: CGFloat)
}

open class OkPagerView: UIView, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {

  @IBOutlet var pageControl: UIPageControl?

  fileprivate var pageViewController: UIPageViewController!
  open fileprivate(set) var currentIndex = 0
  open var callFirstItemOnCreated = true
  open weak var dataSource: OkPagerViewDataSource? {
    didSet {
      reloadData()
    }
  }
  open weak var delegate: OkPagerViewDelegate?

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    addPagerViewController()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addPagerViewController()
  }
  
  override open func layoutSubviews() {
    super.layoutSubviews()
    addPagerViewController()
  }

  // MARK: - Private methods
  fileprivate func addPagerViewController() {

    if pageViewController != nil {
      return
    }

    pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    pageViewController.dataSource = self
    pageViewController.delegate = self
    self.parentViewController?.addChild(pageViewController)
    addPagerView(pageViewController.view)
    pageViewController.didMove(toParent: self.parentViewController)
    pageControl?.currentPage = 0

    for view in pageViewController.view.subviews {
      if let scrollView = view as? UIScrollView {
        scrollView.delegate = self
      }
    }
  }

  fileprivate func addPagerView(_ pagerView: UIView) {
    pagerView.frame = self.bounds
    self.addSubview(pagerView)

    let constTop = NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: pagerView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)

    let constBottom = NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: pagerView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)

    let constLeft = NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: pagerView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: 0)

    let constRight = NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: pagerView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0)

    self.addConstraints([constTop, constBottom, constLeft, constRight])
  }

  fileprivate func getViewControllerAtIndex(_ index: Int) -> UIViewController? {
    if (getNumberOfPages() == 0
      || index >= getNumberOfPages())
    {
      return nil
    }

    // Create a new View Controller and pass suitable data.
    guard let viewController = dataSource?.viewControllerAtIndex(index) else {
      return nil
    }

    viewController.view.tag = index
    return viewController
  }

  fileprivate func getNumberOfPages() -> Int {
    if let dataSource = dataSource,
      let numberOfPages = dataSource.numberOfPages()
      , pageViewController != nil {
      return numberOfPages
    }
    return 0
  }

  // MARK: - Public methods
  open func reloadData() {

    if getNumberOfPages() > 0
      && currentIndex >= 0
      && currentIndex < getNumberOfPages() {
      self.pageViewController.setViewControllers(
        [getViewControllerAtIndex(currentIndex)!],
        direction: UIPageViewController.NavigationDirection.forward,
        animated: false,
        completion: nil)

      pageControl?.currentPage = currentIndex

      if callFirstItemOnCreated {
        delegate?.onPageSelected(getViewControllerAtIndex(currentIndex)!, index: currentIndex)
      }
    }
  }

  open func setCurrentIndex(_ index: Int, animated: Bool) {
    if index == currentIndex {
      print("Same page")
      return
    }
    if index >= getNumberOfPages() {
      print("Trying to reach an unknown page")
      return
    }

    let direction: UIPageViewController.NavigationDirection = currentIndex < index ? .forward : .reverse

    guard let viewController = getViewControllerAtIndex(index) else {
      print("Method getViewControllerAtIndex(\(index)) is returning nil")
      return
    }

    self.pageViewController.setViewControllers([viewController], direction: direction, animated: true, completion: { _ in
      self.currentIndex = index
    })

    delegate?.onPageSelected(viewController, index: index)
  }

  open func setScrollEnabled(_ enabled: Bool) {

    if let pageViewController = pageViewController {

      for view in pageViewController.view.subviews {
        if let scrollView = view as? UIScrollView {
          scrollView.isScrollEnabled = enabled
        }
      }
    }
  }

  // MARK: - UIPageViewControllerDataSource
  open func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    var index = viewController.view.tag
    if (index == 0) || (index == NSNotFound) { return nil }
    index -= 1
    return getViewControllerAtIndex(index)
  }

  open func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    var index = viewController.view.tag
    if index == NSNotFound { return nil }
    index += 1
    if (index == getNumberOfPages()) { return nil }
    return getViewControllerAtIndex(index)
  }

  // MARK: - UIPageViewControllerDelegate
  open func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    if completed {
      if let pageVC = pageViewController.viewControllers?.last {
        delegate?.onPageSelected(pageVC, index: pageVC.view.tag)
        // Save currentIndex
        currentIndex = pageVC.view.tag
        pageControl?.currentPage = currentIndex
      }
    }
  }

  // MARK: - UIScrollViewDelegate
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let direction = scrollView.contentOffset.x > frame.size.width ? 1 : -1
    let point = scrollView.contentOffset
    let percentComplete: CGFloat = abs(point.x - frame.size.width)/frame.size.width

    notifyAnimationDelegates(percentComplete: percentComplete, direction: direction)
  }

  func notifyAnimationDelegates(percentComplete: CGFloat, direction: Int) {
    guard let dataSource = dataSource,
      let numberOfPages = dataSource.numberOfPages() else {
        return
    }

    for i in 0..<numberOfPages {
      if let vc = dataSource.viewControllerAtIndex(i),
        let animationDelegate = vc as? OkPagerViewAnimationDelegate, vc.isViewLoaded {
        let index = CGFloat(i - currentIndex)
        let offset: CGFloat
        if index == 0 { // Current index
          offset = percentComplete * CGFloat(direction)
        } else {
          offset = index - (percentComplete * CGFloat(direction))
        }
        animationDelegate.onScrolling(vc, index: i, offset: offset)
      }
    }
  }
}

fileprivate extension UIView {
  var parentViewController: UIViewController? {
    var parentResponder: UIResponder? = self
    while parentResponder != nil {
      parentResponder = parentResponder?.next
      if let viewController = parentResponder as? UIViewController {
        return viewController
      }
    }
    return nil
  }
}


