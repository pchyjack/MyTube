#import "AppDelegate.h"
#import "Theme.h"
#import "Library.h"
#import "Controllers.h"
#import <AVFoundation/AVFoundation.h>

@implementation AppDelegate

- (UINavigationController *)navWithRoot:(UIViewController *)root
                                  title:(NSString *)title
                                  image:(NSString *)symbol {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:root];
    UIImage *img = [UIImage systemImageNamed:symbol];
    nav.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:img tag:0];
    return nav;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Theme apply];

    // Let video audio play even with the silent switch on
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    VideoListViewController *featured  = [[VideoListViewController alloc] initWithMode:ListModeFeatured];
    VideoListViewController *viewed    = [[VideoListViewController alloc] initWithMode:ListModeMostViewed];
    VideoListViewController *search    = [[VideoListViewController alloc] initWithMode:ListModeSearch];
    VideoListViewController *bookmarks = [[VideoListViewController alloc] initWithMode:ListModeBookmarks];
    MoreViewController *more           = [[MoreViewController alloc] initWithStyle:UITableViewStyleGrouped];

    UITabBarController *tabs = [[UITabBarController alloc] init];
    tabs.viewControllers = @[
        [self navWithRoot:featured  title:@"Featured"    image:@"star.fill"],
        [self navWithRoot:viewed    title:@"Most Viewed" image:@"chart.bar.fill"],
        [self navWithRoot:search    title:@"Search"      image:@"magnifyingglass"],
        [self navWithRoot:bookmarks title:@"Bookmarks"   image:@"bookmark.fill"],
        [self navWithRoot:more      title:@"More"        image:@"ellipsis"],
    ];

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = tabs;
    [self.window makeKeyAndVisible];

    [[Library shared] requestAccessAndLoad];
    return YES;
}

@end
