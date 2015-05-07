//
//  ViewController.h
//  ElliptiChat
//
//  Copyright (c) 2015 Stephen Salerno. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSMutableArray* chat;


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *nameField;
@property (weak, nonatomic) IBOutlet UIButton *keyField;


@end

