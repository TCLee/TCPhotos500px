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
 */
- (void)presentWithWindow:(UIWindow *)window
                    photo:(TCPhoto *)photo
                   sender:(UIView *)sender;

- (void)dismiss;

@end
