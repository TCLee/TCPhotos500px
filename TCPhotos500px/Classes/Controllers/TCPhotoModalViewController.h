//
//  TCPhotoModalViewController.h
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/29/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TCPhoto;

/*
 Displays a large size version of the photo in an overlay modal view.
 */
@interface TCPhotoModalViewController : UIViewController

/*
 Presents this modal view controller with an optional animation.
 The view will be added to the given window, so that it will sit above all other views.
 */
- (void)presentWithWindow:(UIWindow *)window photo:(TCPhoto *)photo animated:(BOOL)animated;

/*
 Dismisses this view controller with an optional animation.
 */
//- (void)dismissAnimated:(BOOL)animated;


- (void)presentWithWindow:(UIWindow *)window photo:(TCPhoto *)photo sender:(UIView *)sender;
- (void)dismiss;

@end
