#import <UIKit/UIKit.h>
#import "Library.h"

typedef NS_ENUM(NSInteger, ListMode) {
    ListModeFeatured,
    ListModeMostViewed,
    ListModeSearch,
    ListModeBookmarks,
    ListModeChannel,
};

@interface VideoListViewController : UITableViewController
@property (nonatomic, copy) NSString *channel;   // for ListModeChannel
@property (nonatomic, strong) LocalVideo *excluded;
- (instancetype)initWithMode:(ListMode)mode;
@end

@interface VideoDetailViewController : UIViewController
- (instancetype)initWithVideo:(LocalVideo *)video;
@end

@interface MoreViewController : UITableViewController
@end
