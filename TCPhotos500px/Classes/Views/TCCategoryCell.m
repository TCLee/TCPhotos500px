//
//  TCCategoryCell.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/21/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCCategoryCell.h"
#import "TCPhotoStreamCategory.h"

@implementation TCCategoryCell

- (void)setCategory:(TCPhotoStreamCategory *)category
{
    self.textLabel.text = category.title;    
    [self setSelected:category.isSelected animated:YES];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (self.isSelected) {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
        self.textLabel.font = [UIFont boldSystemFontOfSize:17];
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.textLabel.font = [UIFont systemFontOfSize:17];
    }
}

@end
