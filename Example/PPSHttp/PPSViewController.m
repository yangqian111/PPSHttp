//
//  PPSViewController.m
//  PPSHttp
//
//  Created by ppsheep.qian@gmail.com on 07/04/2017.
//  Copyright (c) 2017 ppsheep.qian@gmail.com. All rights reserved.
//

#import "PPSViewController.h"
#import <PPSHttp/PPSHttp-umbrella.h>

@interface PPSViewController ()

@end

@implementation PPSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)TEST:(id)sender {
    
    [PPSHttp POST:@"https://4g.n.netease.com/sdk/api/v1/qos" parameters:@{@"id":@"9884321231231",@"ip":@"20.32.2.3",@"server":@[@"10.234,321",@"76.389.421"]} success:^(NSData * _Nullable data, NSURLResponse * _Nullable response) {
        NSLog(@"成功");
        NSLog(@"成功");
    } failure:^(NSError * _Nullable error) {
        NSLog(@"失败");
        NSLog(@"失败");
    }];
    
}
@end
