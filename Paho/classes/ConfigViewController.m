//
//  ConfigViewController.m
//  TRemotEye
//
//  Created by boxer on 2017. 9. 20..
//  Copyright © 2017년 Park. All rights reserved.
//

#import "ConfigViewController.h"
#import "AppDelegate.h"
#import "NHCNavigationBar.h"
#import "ConfigViewCell.h"

@interface ConfigViewController ()<UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UITextField *tfHost;
    IBOutlet UITextField *tfPort;
    IBOutlet UITextField *tfUserName;
    IBOutlet UITextField *tfTopic;
    IBOutlet UITableView *tvTrip;
    NSDictionary *dicPayload;
}
@end

@implementation ConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [NHCNavigationBar navigationBarTitleViewController:self withTitle:@"Config"];
    [NHCNavigationBar drawBackButton:self withAction:@selector(onNaviBackButton)];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"payload" ofType:@"plist"];
    dicPayload = [[NSDictionary alloc] initWithContentsOfFile:path];
    
    tfHost.text = [AppDelegate loadFromUserDefaults:@"Host"];
    tfPort.text = [AppDelegate loadFromUserDefaults:@"Port"];
    tfUserName.text = [AppDelegate loadFromUserDefaults:@"UserName"];
    tfTopic.text = [AppDelegate loadFromUserDefaults:@"Topic"];
}

- (void)onNaviBackButton{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFeildDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [self setTapGestureCloseTextField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [self.view endEditing:NO];
    
    [AppDelegate instance].strHost = tfHost.text;
    [AppDelegate instance].strPort = tfPort.text;
    [AppDelegate instance].strUserName = tfUserName.text;
    [AppDelegate instance].strTopic = tfTopic.text;
    
    [AppDelegate saveFromUserDefaults:tfHost.text forKey:@"Host"];
    [AppDelegate saveFromUserDefaults:tfPort.text forKey:@"Port"];
    [AppDelegate saveFromUserDefaults:tfUserName.text forKey:@"UserName"];
    [AppDelegate saveFromUserDefaults:tfTopic.text forKey:@"Topic"];
}

- (void)setTapGestureCloseTextField{
    UITapGestureRecognizer* tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTap)];
    tgr.numberOfTapsRequired = 1;
    tgr.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tgr];
}

- (void)viewTap
{
    [self.view endEditing:YES];
}

#pragma mark - Table View Data Source Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return dicPayload.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"ConfigViewCell";
    ConfigViewCell *cell = (ConfigViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ConfigViewCell" owner:self options:nil];
        
        cell = (ConfigViewCell *)[nib objectAtIndex:0];
    }
    
    cell.lblName.text = [dicPayload objectForKey:[NSString stringWithFormat:@"TRE%lu", indexPath.row + 1]];
    cell.lblItem.text = @"tripid";
    
    return cell;
}

#pragma mark - Table Delegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

@end
