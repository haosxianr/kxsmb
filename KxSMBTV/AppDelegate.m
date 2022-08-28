//
//  AppDelegate.m
//  KxSMBTV
//
//  Created by L on 27/8/2022.
//  Copyright © 2022 Konstantin Bukreev. All rights reserved.
//

#import "AppDelegate.h"
#import "TreeViewController.h"
#import "SmbAuthViewController.h"
#import "KxSMBProvider.h"

@interface AppDelegate() <KxSMBProviderDelegate, SmbAuthViewControllerDelegate>
@end

@implementation AppDelegate {

	TreeViewController *_headVC;
	NSMutableDictionary *_cachedAuths;
	SmbAuthViewController *_smbAuthViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	_headVC = [[TreeViewController alloc] initAsHeadViewController];
	//_headVC.defaultAuth = [KxSMBAuth smbAuthWorkgroup:@"" username:@"guest" password:@""];
	
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:_headVC];
	[self.window makeKeyAndVisible];
	
	_cachedAuths = [NSMutableDictionary dictionary];
	KxSMBProvider *provider = [KxSMBProvider sharedSmbProvider];
	provider.delegate = self;
	provider.config.browseMaxLmbCount = 0;
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

#pragma mark - KxSMBProviderDelegate

- (void) presentSmbAuthViewControllerForServer:(NSString *)server
										 share:(NSString *)share
									 workgroup:(NSString *)workgroup
									  username:(NSString *)username
{
	if (!_smbAuthViewController) {
		_smbAuthViewController = [[SmbAuthViewController alloc] init];
		_smbAuthViewController.delegate = self;
		_smbAuthViewController.username = @"guest";
	}
	
	UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
	
	if (nav.presentedViewController)
		return;
	
	_smbAuthViewController.server = server;
	_smbAuthViewController.workgroup = workgroup;
	_smbAuthViewController.username = username;
	
	UIViewController *vc = [[UINavigationController alloc] initWithRootViewController:_smbAuthViewController];
	
	[nav.topViewController presentViewController:vc
										animated:NO
									  completion:nil];
}

- (void) couldSmbAuthViewController:(SmbAuthViewController *) controller
							   done:(BOOL) done
{
	if (done) {
		
		KxSMBAuth *auth = [KxSMBAuth smbAuthWorkgroup:controller.workgroup
											 username:controller.username
											 password:controller.password];
		
		_cachedAuths[controller.server.uppercaseString] = auth;
		
		NSLog(@"store auth %@ -> (%@) %@:%@", controller.server, controller.workgroup, controller.username, controller.password);
	}
	
	UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
	[nav dismissViewControllerAnimated:YES completion:nil];
	
	[_headVC reloadPath];
}

- (KxSMBAuth *) smbRequestAuthServer:(NSString *)server
							   share:(NSString *)share
						   workgroup:(NSString *)workgroup
							username:(NSString *)username
{
	if ([share isEqualToString:@"IPC$"] ||
		[share hasSuffix:@"$"])
	{
		// return nil;
	}
	
	KxSMBAuth *auth = _cachedAuths[server.uppercaseString];
	if (auth) {
		
		// NSLog(@"cached auth for %@ -> %@ (%@) %@:%@", server, share, auth.workgroup, auth.username, auth.password);
		return auth;
	}
	
	NSLog(@"ask auth for %@/%@ (%@)", server, share, workgroup);
	
	dispatch_async(dispatch_get_main_queue(), ^{
	
		[self presentSmbAuthViewControllerForServer:server
											  share:share
										  workgroup:workgroup
										   username:username];
	});
	
	return nil;
}

@end
