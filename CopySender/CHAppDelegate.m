//
//  CHAppDelegate.m
//  CopySender
//
//  Created by Christian Hedin on 2013-08-03.
//  Copyright (c) 2013 Christian Hedin. All rights reserved.
//

#import "CHAppDelegate.h"
#import "AFHTTPClient.h"


@interface CHAppDelegate() <NSTextFieldDelegate>
@property (weak) IBOutlet NSSecureTextField *passwordTextField;
@property (weak) IBOutlet NSTextField *hostnameTextField;
@property (weak) IBOutlet NSTextField *portTextField;
@property (weak) IBOutlet NSButton *bottomButton;
@property (strong) NSTimer* timer;
@property (assign) BOOL  isRunning;
@property (strong) NSStatusItem *statusMenuItem;
@end

@implementation CHAppDelegate
{
  NSInteger previousChangeCount;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  [self setupStatusItem];
  [self readFromSettings];
  
  if ([self settingsValidate]) {
    [self.bottomButton setEnabled:YES];
  }
  else {
    [self.bottomButton setEnabled:NO];
  }
  
  if ([self settingsValidate]) {
    [self.window setIsVisible:NO];
    [self startRunning];

  }
  else {
    [self updateButtonTo:@"Start"];
  }
}


-(void)setupStatusItem;
{
  
  NSStatusItem *statusItem = [[NSStatusBar systemStatusBar]
                 statusItemWithLength:NSVariableStatusItemLength]
                ;
  [statusItem setHighlightMode:YES];
  [statusItem setTitle:@"CS"];
  [statusItem setEnabled:YES];
  [statusItem setToolTip:@"Toggle the main window"];
  
  [statusItem setAction:@selector(toggleMainWindow:)];
  [statusItem setTarget:self];
  self.statusMenuItem = statusItem;
}


-(void)toggleMainWindow:(id)sender;
{
  if ([self.window isVisible]) {
    [self.window setIsVisible:NO];
  }
  else
    [self.window setIsVisible:YES];
}

-(void)updateButtonTo:(NSString*)text;
{
  [self.bottomButton setTitle:text];
}

-(void)setFieldsEnabled:(BOOL)enabled;
{
  [self.hostnameTextField setEnabled:enabled];
  [self.portTextField setEnabled:enabled];
  [self.passwordTextField setEnabled:enabled];
}

- (void)pollPasteboard:(NSTimer *)timer {
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  NSInteger currentChangeCount = [pasteboard changeCount];
  if (currentChangeCount == previousChangeCount)
    return;
  NSArray *classes = [[NSArray alloc] initWithObjects:[NSString class], nil];
  NSDictionary *options = [NSDictionary dictionary];
  NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
  if (copiedItems != nil && [copiedItems count]>0) {
    NSString *item = [copiedItems objectAtIndex:0];
    NSString *escapedItem = [item stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [self sendToServer:escapedItem];
  }
  previousChangeCount = currentChangeCount;
}

-(void)startRunning;
{
  [self setFieldsEnabled:NO];
  self.isRunning = YES;
  [self updateButtonTo:@"Stop"];
  self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self
                                 selector:@selector(pollPasteboard:)
                                 userInfo:nil repeats:YES];
}

-(void)stopRunning;
{
  [self setFieldsEnabled:YES];
  self.isRunning = NO;
  if(self.timer) {
    [self.timer invalidate];
    self.timer = nil;
  }

  [self updateButtonTo:@"Start"];
}

-(void)sendToServer:(NSString*)string;
{
  NSLog(@"Sending: '%@'",string);
  
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@",self.hostnameTextField.stringValue,self.portTextField.stringValue]];
    //NSURL *url = [NSURL URLWithString:@"http://localhost:4567"];
  AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
  
  [httpClient setAuthorizationHeaderWithUsername:@"admin" password:self.passwordTextField.stringValue];
  httpClient.allowsInvalidSSLCertificate = YES;
  NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                          string, @"clipboard",
                          nil];
  [httpClient postPath:@"/" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
    if ([responseStr isEqualToString:@"OK"]) {
      // silent success!
    }
    else {
      NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The server replied, but not as expected."];
      [alert runModal];
    }
    NSLog(@"Request Successful, response '%@'", responseStr);
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    [self stopRunning];
    NSLog(@"[HTTPClient Error]: %@", error.localizedDescription);
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert runModal];
    
  }];
}

#define kCopySenderHostname @"hostname"
#define kCopySenderPort @"port"
#define kCopySenderPassword @"password"

-(void)saveHostname:(NSString*)hostname portString:(NSString*)port password:(NSString*)password;
{
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  [prefs setObject:hostname forKey:kCopySenderHostname];
  [prefs setObject:port forKey:kCopySenderPort];
  [prefs setObject:password forKey:kCopySenderPassword];
  [prefs synchronize];
}

-(void)readFromSettings;
{
  if([self settingsValidate]) {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *hostname = [prefs objectForKey:kCopySenderHostname];
    NSString *port = [prefs objectForKey:kCopySenderPort];
    NSString *password = [prefs objectForKey:kCopySenderPassword];
    [self.hostnameTextField setStringValue:hostname];
    [self.portTextField setStringValue:port];
    [self.passwordTextField setStringValue:password];
  }

}

-(NSString*)settingsFile;
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString * path =[[NSString alloc] initWithString:
                    [documentsDirectory stringByAppendingPathComponent:@"settings_file.plist"]];
  return path;
}


#pragma mark UI callbacks

- (IBAction)didTapBottomButton:(id)sender
{
  if (![self settingsValidate]) {
    return;
  }
  
  if (!self.isRunning) {
    [self startRunning];
  }
  else {
    [self stopRunning];
  }
}

- (void)controlTextDidChange:(NSNotification *)obj;
{
  [self saveHostname:self.hostnameTextField.stringValue portString:self.portTextField.stringValue password:self.passwordTextField.stringValue];
  
  if ([self settingsValidate]) {
    [self.bottomButton setEnabled:YES];
  }
  else {
    [self.bottomButton setEnabled:NO];
  }
}


#pragma mark Validation

-(BOOL)settingsValidate;
{
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  NSString *hostname = [prefs objectForKey:kCopySenderHostname];
  NSString *port = [prefs objectForKey:kCopySenderPort];
  NSString *password = [prefs objectForKey:kCopySenderPassword];
  if (![[hostname class] isSubclassOfClass:[NSString class]] || [hostname isEqualToString:@""]) {
    hostname = nil;
  }
  
  BOOL notNilNotEmpty =  hostname!=nil && port!=nil && ![hostname isEqualToString:@""] && ![port isEqualToString:@""] && password!=nil && ![password isEqualToString:@""];

  return notNilNotEmpty;
}



@end
