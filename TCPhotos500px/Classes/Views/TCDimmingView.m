//
//  TCDimmingView.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/28/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCDimmingView.h"

@implementation TCDimmingView

- (id)init
{
    self = [super init];
    if (self) {
        [self configureView];
    }    
    return self;
}

- (void)configureView
{
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    self.userInteractionEnabled = NO;
}

@end
