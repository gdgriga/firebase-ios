//
//  PagerController.swift
//  FirebaseWorkshop
//
//  Created by Romans Karpelcevs on 28/07/16.
//  Copyright © 2016 GDG. All rights reserved.
//

import UIKit
import MXSegmentedPager

class PagerController: MXSegmentedPagerController {

    var selectedPageChangedBlock: ((index: Int) -> Void)?

    private var viewControllers: [UIViewController]!
    private var titles: [String]!

    var selectedPageIndex: Int {
        return self.segmentedPager.pager.indexForSelectedPage
    }

    convenience init(viewControllers: [UIViewController], titles: [String]) {
        self.init()
        self.viewControllers = viewControllers
        self.titles = titles
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.segmentedPager.backgroundColor = UIColor.whiteColor()

        // Segmented Control customization
        self.segmentedPager.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        self.segmentedPager.segmentedControl.backgroundColor = UIColor.whiteColor()
        self.segmentedPager.segmentedControl.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.blackColor()];
        self.segmentedPager.segmentedControl.selectedTitleTextAttributes = [NSForegroundColorAttributeName : UIColor.orangeColor()]
        self.segmentedPager.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe
        self.segmentedPager.segmentedControl.selectionIndicatorColor = UIColor.orangeColor()
    }

    override func numberOfPagesInSegmentedPager(segmentedPager: MXSegmentedPager) -> Int {
        return self.viewControllers.count
    }

    override func segmentedPager(segmentedPager: MXSegmentedPager, viewControllerForPageAtIndex index: Int) -> UIViewController {
        return self.viewControllers[index]
    }

    override func segmentedPager(segmentedPager: MXSegmentedPager, titleForSectionAtIndex index: Int) -> String {
        return self.titles[index]
    }

    override func segmentedPager(segmentedPager: MXSegmentedPager, didSelectViewWithIndex index: Int) {
        self.selectedPageChangedBlock?(index: index)
    }
}
