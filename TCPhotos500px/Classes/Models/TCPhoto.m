//
//  TCPhoto.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/17/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCPhoto.h"

// 500px Image Size Constants
typedef NS_ENUM(NSInteger, TCPhotoSize) {
    TCPhotoSizeThumbnail = 3,
    TCPhotoSizeLarge     = 4,
};

@implementation TCPhoto

- (id)initWithPage:(TCPhotoStreamPage *)page attributes:(NSDictionary *)attributes
{
    self = [super init];
    
    if (self) {
        _photoStreamPage = page;
        [self setAttributes:attributes];
    }
    
    return self;
}

- (void)setAttributes:(NSDictionary *)attributes
{    
    // Title of the photo.
    _title = [attributes[@"name"] copy];
    
    // User's full name.
    _userFullName = attributes[@"user"][@"fullname"];
    
    // Set thumbnail and image URL.
    NSArray *imageArray = attributes[@"images"];
    for (NSDictionary *imageDict in imageArray) {
        NSInteger imageSize = [imageDict[@"size"] integerValue];
        NSURL *imageURL = [[NSURL alloc] initWithString:imageDict[@"url"]];
        
        switch (imageSize) {
            case TCPhotoSizeThumbnail:
                _thumbnailURL = imageURL;
                break;
            
            case TCPhotoSizeLarge:
                _imageURL = imageURL;
                break;
                
            default:
                break;
        }
    }    
}

@end
