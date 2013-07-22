//
//  TCPhotoStreamCategoryList.h
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/20/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

@class TCPhotoStreamCategory;

/*
 This model represents a list of supported categories that can be used to 
 filter the photo stream.
 */
@interface TCPhotoStreamCategoryList : NSObject

/*
 Returns a shared list of supported categories.
 */
+ (instancetype)defaultList;

/*
 Number of categories in this list.
 */
- (NSUInteger)categoryCount;

/* 
 Returns the index of the selected category.
 */
- (NSUInteger)indexOfSelectedCategory;

/*
 Selects category at given index and deselects any currently selected category.
 */
- (void)selectCategoryAtIndex:(NSUInteger)index;

/*
 Returns the category at the given index.
 */
- (TCPhotoStreamCategory *)categoryAtIndex:(NSUInteger)index;

/*
 Removes all TCPhotoStreamCategory objects from the list. The list will be
 re-created automatically when attempting to access the categories again.
 This method should be called when the controller receives a memory warning.
 */
- (void)removeAllCategories;

@end
