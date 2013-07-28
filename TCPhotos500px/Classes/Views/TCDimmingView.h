//
//  TCDimmingView.h
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/28/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TCDimmingView;

@protocol TCDimmingViewDelegate <NSObject>

@required

/* Tells the delegate that the dimming view has received a tap gesture. */
- (void)dimmingViewDidReceiveTapGesture:(TCDimmingView *)dimmingView;

@end

/*
 Dims the background and disables user interaction.
 Much simplified version of Apple's private class "UIDimmingView".
 */
@interface TCDimmingView : UIView

@property (nonatomic, weak) id<TCDimmingViewDelegate> delegate;

- (id)initWithDelegate:(id<TCDimmingViewDelegate>)delegate;

/* Add the dimming view to the given parent view with an animation (or not). */
- (void)addToSuperview:(UIView *)parentView animated:(BOOL)animated;

/* Remove the dimming view from it superview with an animation (or not). */
- (void)removeFromSuperviewAnimated:(BOOL)animated;

@end
