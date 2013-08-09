//
//  TCPhotoStream.h
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/15/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

@class TCPhotoStreamPage;
@class TCPhoto;

typedef void(^TCPhotoCompletionBlock)(TCPhoto *photo, NSError *error);

/*
 Photo count value that indicates that the photo stream has not been fetched in yet.
 */
enum { TCPhotoStreamNoPhotoCount = -1 };

/*
 This model represents a photo stream.  
 A photo stream will be separated into pages for more efficient retrieval.
 */
@interface TCPhotoStream : NSObject

/*
 Gets the photo stream's feature.
 */
@property (nonatomic, assign, readonly) PXAPIHelperPhotoFeature feature;

/*
 Gets the category that is used to filter the photo stream.
 */
@property (nonatomic, assign, readonly) PXPhotoModelCategory category;

/*
 Initialize the photo stream with the given feature and category.
 */
- (id)initWithFeature:(PXAPIHelperPhotoFeature)feature
             category:(PXPhotoModelCategory)category;

/*
 Returns the total number of photos in this photo stream.
 
 If photo stream has not finished loading yet, it returns TCPhotoStreamNoPhotoCount.
 */
- (NSInteger)photoCount;

/*
 If photo is in the cache, this method will return the photo from the cache. 
 It will not call the completionBlock in this case.
 
 If photo is not found in the cache, this method will return nil and async fetch 
 the photo from network. In this case, completionBlock will be called when the 
 photo is fetched.
 */
- (TCPhoto *)photoAtIndex:(NSUInteger)index completion:(TCPhotoCompletionBlock)completionBlock;

@end
