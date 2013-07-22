//
//  TCPhotoStreamPage.h
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/17/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCPhotoStream.h"
@class TCPhoto;

/*
 This model represents a single page in the photo stream.
 Each page will have its own collection of photos.
 */
@interface TCPhotoStreamPage : NSObject

/*
 Weak reference to the photo stream parent that owns this page.
 */
@property (nonatomic, weak, readonly) TCPhotoStream *photoStream;

/*
 Gets the page number of this page. Page number starts from 1.
 */
@property (nonatomic, assign, readonly) NSInteger pageNumber;

/*
 Initializes a page with the photo stream that this page belongs to and its page number.
 */
- (id)initWithPhotoStream:(TCPhotoStream *)photoStream
               pageNumber:(NSInteger)pageNumber;

/*
 Set this page's properties from a dictionary of keys and values.
 */
- (void)setAttributes:(NSDictionary *)attributes;

/* 
 Returns the number of photos in this page.
 */
- (NSUInteger)photoCount;

/*
 Returns the photo in this page at the specified index.
 */
- (TCPhoto *)photoAtIndex:(NSUInteger)index;

@end
