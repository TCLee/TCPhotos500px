//
//  TCCategoryListViewController.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/20/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCCategoryListViewController.h"
#import "TCPhotoStreamCategoryList.h"
#import "TCPhotoStreamCategory.h"
#import "TCCategoryCell.h"

// FlatUIKit
#import "UIColor+FlatUI.h"

@interface TCCategoryListViewController ()

@end

#pragma mark -

@implementation TCCategoryListViewController

#pragma mark - View Events

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor cloudsColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
  
    // When this view is re-displayed in the popover, we will need to
    // scroll to the previously selected category to make it visible.
    NSUInteger selectedIndex = [[TCPhotoStreamCategoryList defaultList] indexOfSelectedCategory];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0]
                          atScrollPosition:UITableViewScrollPositionNone animated:NO];
}

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
    [[TCPhotoStreamCategoryList defaultList] removeAllCategories];
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[TCPhotoStreamCategoryList defaultList] categoryCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CategoryCell";
    TCCategoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    TCPhotoStreamCategory *category = [[TCPhotoStreamCategoryList defaultList] categoryAtIndex:indexPath.row];
    [cell setCategory:category];    
    return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TCPhotoStreamCategoryList *categoryList = [TCPhotoStreamCategoryList defaultList];
    UITableViewCell *cell = nil;
    NSUInteger selectedIndex = [categoryList indexOfSelectedCategory];
    
    // If user is selecting an already selected category, we do nothing.
    if (selectedIndex == indexPath.row) {
        // Cross fade the selection to let user know their touch was registered.
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    // Deselect currently selected category.
    cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0]];
    [cell setSelected:NO animated:YES];
    
    // Select new category.
    [categoryList selectCategoryAtIndex:indexPath.row];
    cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:YES animated:YES];
    
    // Notify the delegate that a category has been selected from the table view.
    [self.delegate categoryListViewController:self
                            didSelectCategory:[categoryList categoryAtIndex:indexPath.row]];
}

@end
