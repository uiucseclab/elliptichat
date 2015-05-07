//
//  ViewController.m
//  ElliptiChat
//
//  Copyright (c) 2015 Stephen Salerno. All rights reserved.
//

#import "ViewController.h"
#import "GMEllipticCurveCrypto.h"
#import "GMEllipticCurveCrypto+hash.h"

@interface ViewController ()

@property (strong, nonatomic) NSString* message;
@property (strong, nonatomic) NSString* publicKey;
@property (strong, nonatomic) NSString* privateKey;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textField.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    GMEllipticCurveCrypto *crypto = [GMEllipticCurveCrypto generateKeyPairForCurve:
                                     GMEllipticCurveSecp192r1];
    
    self.publicKey = crypto.publicKeyBase64;
    self.privateKey = crypto.privateKeyBase64;
    
    
    NSString *keyString = @"Public Key: ";
    keyString = [keyString stringByAppendingString:self.publicKey];
    [self.keyField setTitle:keyString forState:UIControlStateNormal];
    
    self.chat = [[NSMutableArray alloc] init];
    self.name = @"Stephen";
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Text field handling


- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    
    __weak typeof(self) weakSelf = self;
    self.message = [NSString stringWithString:aTextField.text];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{
        NSData *messageData = [weakSelf.message dataUsingEncoding:NSUTF8StringEncoding];
        GMEllipticCurveCrypto *crypto = [GMEllipticCurveCrypto cryptoForCurve:GMEllipticCurveSecp192r1];
        crypto.privateKeyBase64 = self.privateKey;
        crypto.publicKeyBase64 = self.publicKey;
        NSData *signedMessage = [crypto hashSHA256AndSignData:messageData];
        
        NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.message, @"message", signedMessage, @"signature", nil];
        
        [weakSelf.chat insertObject:item atIndex:0];
        [weakSelf.tableView reloadData];
        
    });
    
    //[self.chat insertObject:aTextField.text atIndex:0];
    
    [aTextField setText:@""];
    //[self.tableView reloadData];
    return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)table numberOfRowsInSection:(NSInteger)section
{
    return [self.chat count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    NSDictionary *item = [self.chat objectAtIndex:indexPath.row];
    NSString *text = [item objectForKey:@"message"];
    
    // typical textLabel.frame = {{10, 30}, {260, 22}}
    const CGFloat TEXT_LABEL_WIDTH = 260;
    CGSize constraint = CGSizeMake(TEXT_LABEL_WIDTH, 20000);
    
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:18] constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping]; // requires iOS 6+
    const CGFloat CELL_CONTENT_MARGIN = 22;
    CGFloat height = MAX(CELL_CONTENT_MARGIN + size.height, 44);
    
    return height;
}

- (UITableViewCell*)tableView:(UITableView*)table cellForRowAtIndexPath:(NSIndexPath *)index
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:18];
        cell.textLabel.numberOfLines = 0;
    }
    
    NSDictionary *item = [self.chat objectAtIndex:index.row];
    cell.textLabel.text = [item objectForKey:@"message"];
    NSData *sigData = [item objectForKey:@"signature"];
    
    NSUInteger dataLength = [sigData length];
    NSMutableString *sig = [NSMutableString stringWithCapacity:dataLength*2];
    const unsigned char *dataBytes = [sigData bytes];
    for (NSInteger idx = 0; idx < dataLength; ++idx) {
        [sig appendFormat:@"%02x", dataBytes[idx]];
    }
    cell.detailTextLabel.text = sig;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary *item = [self.chat objectAtIndex:indexPath.row];
    
    NSString *message = [item objectForKey:@"message"];
    NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSData *sigData = [item objectForKey:@"signature"];
    
    GMEllipticCurveCrypto *crypto = [GMEllipticCurveCrypto cryptoForCurve:GMEllipticCurveSecp192r1];
    crypto.privateKeyBase64 = self.privateKey;
    crypto.publicKeyBase64 = self.publicKey;

    UIAlertView *alert;
    
    BOOL check = [crypto hashSHA256AndVerifySignature:sigData forData:messageData];
    if (check) {
        alert = [[UIAlertView alloc] initWithTitle:@"Authenticity Check" message:@"The message is authentic" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    }
    else {
        alert = [[UIAlertView alloc] initWithTitle:@"Authenticity Check" message:@"The message is NOT authentic" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    }
    
    [alert show];
    
}

#pragma mark - Keyboard handling

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(keyboardWillShow:)
     name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(keyboardWillHide:)
     name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    [self moveView:[notification userInfo] up:YES];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    [self moveView:[notification userInfo] up:NO];
}

- (void)moveView:(NSDictionary*)userInfo up:(BOOL)up
{
    CGRect keyboardEndFrame;
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]
     getValue:&keyboardEndFrame];
    
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]
     getValue:&animationCurve];
    
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey]
     getValue:&animationDuration];
    
    // Get the correct keyboard size to we slide the right amount.
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
    int y = keyboardFrame.size.height * (up ? -1 : 1);
    self.view.frame = CGRectOffset(self.view.frame, 0, y);
    
    [UIView commitAnimations];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    if ([self.textField isFirstResponder]) {
        [self.textField resignFirstResponder];
    }
}



@end
