//
//  TCPhotoCell.h
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/14/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TCPhoto;

@interface TCPhotoCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (void)setPhoto:(TCPhoto *)photo;

@end
