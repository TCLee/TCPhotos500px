//
//  TCCategoryListViewController.h
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/20/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TCCategoryListViewController;
@class TCPhotoStreamCategory;

@protocol TCCategoryListViewControllerDelegate <NSObject>

@required
- (void)categoryListViewController:(TCCategoryListViewController *)categoryListViewController
                 didSelectCategory:(TCPhotoStreamCategory *)category;
@end

@interface TCCategoryListViewController : UITableViewController

@property(nonatomic, weak) id <TCCategoryListViewControllerDelegate> delegate;

@end
