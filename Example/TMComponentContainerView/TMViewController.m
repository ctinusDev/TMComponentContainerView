//
//  TMViewController.m
//  TMComponentContainerView
//
//  Created by ctinusDEV on 01/26/2021.
//  Copyright (c) 2021 ctinusDEV. All rights reserved.
//

#import "TMViewController.h"
#import <WebKit/WebKit.h>
#import <TMComponentContainerView/TMComponentContainerView.h>

@interface TMViewController ()

@property (nonatomic, strong) TMComponentContainerView *componentView;

@end

@implementation TMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.componentView = [[TMComponentContainerView alloc] init];
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0) configuration:[[WKWebViewConfiguration alloc] init]];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://xclient.info/s/"]]];
    webView.tm_padding = UIEdgeInsetsMake(10, 10, 10, 10);
    webView.tm_widthAdjust = TMUIWidthAdjustAutoFix;
    
    WKWebView *webView1 = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width-80, 0) configuration:[[WKWebViewConfiguration alloc] init]];
    [webView1 loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://baijiahao.baidu.com/s?id=1689828849661274143&wfr=spider&for=pc"]]];
    webView1.tm_widthAdjust = TMUIWidthAdjustAutoFix;
    
    self.componentView.componentViews = @[webView, webView1];
    
    [self.view addSubview:self.componentView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.componentView.frame = self.view.bounds;
}

@end
