//
//  TCPhotoCell.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/14/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCPhotoCell.h"
#import "TCPhoto.h"

// Higher performance async remote image loading than AFNetworking's default
// UIImageView category.
#import "UIImageView+WebCache.h"

@implementation TCPhotoCell

- (void)setPhoto:(TCPhoto *)newPhoto
{
    // Do nothing, if attempting we're given the same photo model object.
    if (_photo == newPhoto) { return; }
    
    _photo = newPhoto;
    
    // Refer to Apple's Transitioning to ARC Release Notes on non-trivial cycles.
    // Non-trivial in this case means we're using weakSelf multiple times in the block.
    // So, weakSelf may become nil during the execution of the block.
    __weak typeof(self) weakSelf = self;
    
    [self.imageView setImageWithURL:_photo.thumbnailURL placeholderImage:nil options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if (image) {
            // Image has finished loading. Hide the activity indicator.
            [strongSelf.activityIndicator stopAnimating];
            
            // Only perform fade animation when loading image from web.
            if (cacheType == SDImageCacheTypeNone) {
                strongSelf.imageView.alpha = 0.0f;
                [UIView animateWithDuration:0.7f animations:^{
                    strongSelf.imageView.alpha = 1.0f;
                }];
            }
        } else if (error) {
            NSLog(@"[SDWebImage Error] - %@", [error localizedDescription]);
        }
    }];
}

@end
