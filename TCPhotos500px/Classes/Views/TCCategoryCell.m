//
//  TCCategoryCell.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/21/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCCategoryCell.h"
#import "TCPhotoStreamCategory.h"

// FlatUIKit
#import "UIColor+FlatUI.h"
#import "UITableViewCell+FlatUI.h"
#import "FUICellBackgroundView.h"

@implementation TCCategoryCell

// Customize the cell's appearance after it has been loaded from the storyboard.
- (void)awakeFromNib
{
    [self configureFlatCellWithColor:[UIColor cloudsColor] selectedColor:[UIColor peterRiverColor]];
    
    self.textLabel.textColor = [UIColor blackColor];
    self.textLabel.highlightedTextColor = [UIColor whiteColor];
}

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
