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
 Presents this modal view controller. 
 It's view will be added as window's subview, so that it will sit above all other views.
 */
- (void)presentWithWindow:(UIWindow *)window photo:(TCPhoto *)photo sender:(UIView *)sender;

/*
 Dismisses this modal view controller.
 */
- (void)dismiss;

@end
