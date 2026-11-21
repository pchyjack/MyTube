#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

extern NSString *const LibraryDidReloadNotification;

@interface LocalVideo : NSObject
@property (nonatomic, strong) MPMediaItem *item;
@property (nonatomic, copy)   NSString *identifier;
@property (nonatomic, copy)   NSString *title;
@property (nonatomic, copy)   NSString *artist;     // shown as the "channel"
@property (nonatomic, copy)   NSString *comments;   // shown as the description
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSDate *dateAdded;
@property (nonatomic)         NSTimeInterval duration;
@property (nonatomic)         NSUInteger views;
- (NSString *)durationString;
@end

@interface Library : NSObject
+ (instancetype)shared;

@property (nonatomic, readonly) BOOL authorized;
@property (nonatomic, readonly) NSArray<LocalVideo *> *allVideos;
@property (nonatomic, readonly) NSTimeInterval totalDuration;

- (void)requestAccessAndLoad;
- (void)reload;

- (NSArray<LocalVideo *> *)featured;
- (NSArray<LocalVideo *> *)mostViewed;
- (NSArray<LocalVideo *> *)search:(NSString *)query;
- (NSArray<LocalVideo *> *)videosByArtist:(NSString *)artist excluding:(LocalVideo *)video;

- (void)recordViewFor:(LocalVideo *)video;

- (BOOL)isBookmarked:(LocalVideo *)video;
- (void)toggleBookmark:(LocalVideo *)video;
- (NSArray<LocalVideo *> *)bookmarks;
- (void)clearBookmarks;

- (void)thumbnailForVideo:(LocalVideo *)video size:(CGSize)size completion:(void (^)(UIImage *image))completion;
@end
