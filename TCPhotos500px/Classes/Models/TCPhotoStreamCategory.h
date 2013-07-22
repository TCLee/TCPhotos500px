//
//  TCPhotoStreamCategory.h
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/20/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 This model represents a category to filter the photo stream with.
 */
@interface TCPhotoStreamCategory : NSObject

@property (nonatomic, assign, getter = isSelected) BOOL selected;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, assign, readonly) PXPhotoModelCategory value;

- (id)initWithTitle:(NSString *)title value:(PXPhotoModelCategory)value selected:(BOOL)selected;

@end
