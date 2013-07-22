//
//  TCPhoto.h
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/17/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

@class TCPhotoStreamPage;

/*
 This model represents a photo within a page.
 */
@interface TCPhoto : NSObject

/*
 Weak reference to the page that owns this photo.
 */
@property (nonatomic, weak, readonly) TCPhotoStreamPage *photoStreamPage;

@property (nonatomic, copy, readonly) NSURL *thumbnailURL;
@property (nonatomic, copy, readonly) NSURL *imageURL;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *userFullName;

/*
 Initializes a new photo with the given attributes and the page that this
 photo belongs to.
 */
- (id)initWithPage:(TCPhotoStreamPage *)page attributes:(NSDictionary *)attributes;

@end
