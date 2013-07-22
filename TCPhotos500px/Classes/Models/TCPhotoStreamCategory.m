//
//  TCPhotoStreamCategory.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/20/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCPhotoStreamCategory.h"

@implementation TCPhotoStreamCategory

- (id)initWithTitle:(NSString *)title value:(PXPhotoModelCategory)value selected:(BOOL)selected
{
    self = [super init];
    if (self) {
        _title = [title copy];
        _value = value;
        _selected = selected;
    }
    return self;
}

@end
