//
//  ViewController.m
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import "ViewController.h"

#import "OIDOpenIdManager.h"

@interface ViewController () <UIWebViewDelegate>

@property (nonatomic) OIDOpenIdManager *manager;
@property (nonatomic) NSString *alias;
@property (nonatomic) NSData *macKey;

@end

@implementation ViewController

- (OIDOpenIdManager *)manager
{
    if (! _manager) {
       _manager = [[OIDOpenIdManager alloc] init];
       _manager.returnTo = @"https://www.openid-example.com/";
       _manager.realm = @"https://*.openid-example.com";
    }
    return _manager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.webView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.manager lookupEndpoint:@"Google" callback:^(OIDEndpoint *endpoint) {
        NSLog(@"%@", endpoint);
        self.alias = endpoint.alias;
        
        [self.manager lookupAssociation:endpoint callback:^(OIDAssociation *association) {
            NSLog(@"%@", association);
            self.macKey = association.rawMacKey;
            
            NSString *url = [self.manager getAuthenticationUrl:endpoint association:association];
            NSLog(@"Open the authentication URL in browser: %@", url);
            
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        }];
    }];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeFormSubmitted) {
        NSString *url = request.URL.absoluteString;
        if ([url hasPrefix:self.manager.returnTo]) {
            NSLog(@"After successfully sign on in browser, enter the URL of address bar in browser: %@", url);
            
            OIDAuthentication *authentication = [self.manager authentication:request key:self.macKey alias:self.alias];
            if (authentication) {
                NSLog(@"Login Success Identity: %@", authentication.identity);
            } else {
                NSLog(@"Login failure.");
            }
            
            [webView loadHTMLString:authentication.description baseURL:nil];
            return NO;
        }
    }
    return YES;
}

@end