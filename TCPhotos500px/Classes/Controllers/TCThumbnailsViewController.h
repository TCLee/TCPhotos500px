//
//  TCPopularViewController.h
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/14/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TCCategoryListViewController.h"

/*
 Displays a grid of thumbnails using UICollectionView.
 Thumbnails are loaded asynchronously and are lazily loaded for the fastest 
 performance.
 */
@interface TCThumbnailsViewController : UIViewController
    <UICollectionViewDataSource, UICollectionViewDelegate,
    TCCategoryListViewControllerDelegate>

@end
