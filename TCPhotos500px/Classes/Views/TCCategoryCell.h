//
//  TCCategoryCell.h
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/21/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TCPhotoStreamCategory;

@interface TCCategoryCell : UITableViewCell

/*
 The photo stream category model that this cell view renders.
 */
@property (nonatomic, strong) TCPhotoStreamCategory *category;

@end
