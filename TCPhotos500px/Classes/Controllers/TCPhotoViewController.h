//
//  TCPhotoViewController.h
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/22/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TCPhoto;

/*
 Manages a view that displays a large size version of the photo.
 */
@interface TCPhotoViewController : UIViewController

/*
 Presents this view controller with optional animation.
 */
- (void)presentWithRootViewController:(UIViewController *)rootViewController photo:(TCPhoto *)photo animated:(BOOL)animated;

/*
 Dismisses this view controller with optional animation.
 */
- (void)dismissAnimated:(BOOL)animated;

@end
