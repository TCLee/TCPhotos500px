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
 Presents this view controller with optional animation.
 */
- (void)presentViewWithWindow:(UIWindow *)window photo:(TCPhoto *)photo animated:(BOOL)animated;

/*
 Dismisses this view controller with optional animation.
 */
- (void)dismissAnimated:(BOOL)animated;

@end
