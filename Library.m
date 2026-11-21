#import "Library.h"
#import <AVFoundation/AVFoundation.h>

NSString *const LibraryDidReloadNotification = @"MyTubeLibraryDidReload";

static NSString *const kBookmarksKey = @"bookmarks";
static NSString *const kViewsKey = @"localViews";

@implementation LocalVideo
- (NSString *)durationString {
    NSInteger t = (NSInteger)llround(self.duration);
    NSInteger h = t / 3600, m = (t % 3600) / 60, s = t % 60;
    if (h > 0) return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)h, (long)m, (long)s];
    return [NSString stringWithFormat:@"%ld:%02ld", (long)m, (long)s];
}
@end

@interface Library ()
@property (nonatomic, strong) NSArray<LocalVideo *> *videos;
@property (nonatomic, strong) NSCache<NSString *, UIImage *> *thumbCache;
@property (nonatomic, strong) dispatch_queue_t thumbQueue;
@end

@implementation Library

+ (instancetype)shared {
    static Library *lib;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ lib = [[Library alloc] init]; });
    return lib;
}

- (instancetype)init {
    if ((self = [super init])) {
        _videos = @[];
        _thumbCache = [[NSCache alloc] init];
        _thumbQueue = dispatch_queue_create("mytube.thumbs", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (BOOL)authorized {
    return [MPMediaLibrary authorizationStatus] == MPMediaLibraryAuthorizationStatusAuthorized;
}

- (NSArray<LocalVideo *> *)allVideos { return self.videos; }

- (NSTimeInterval)totalDuration {
    NSTimeInterval t = 0;
    for (LocalVideo *v in self.videos) t += v.duration;
    return t;
}

- (void)requestAccessAndLoad {
    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self reload]; });
    }];
}

- (NSDictionary *)localViews {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:kViewsKey] ?: @{};
}

- (void)reload {
    NSMutableArray<LocalVideo *> *out = [NSMutableArray array];
    if (self.authorized) {
        MPMediaQuery *q = [[MPMediaQuery alloc] init];
        [q addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:@(MPMediaTypeAnyVideo)
                                                               forProperty:MPMediaItemPropertyMediaType]];
        NSDictionary *local = [self localViews];
        for (MPMediaItem *it in q.items) {
            NSURL *url = it.assetURL;
            if (!url) continue; // DRM-protected or not playable locally
            LocalVideo *v = [[LocalVideo alloc] init];
            v.item = it;
            v.url = url;
            v.identifier = [NSString stringWithFormat:@"%llu", it.persistentID];
            v.title = it.title.length ? it.title : url.lastPathComponent;
            v.artist = it.artist.length ? it.artist : it.albumArtist;
            v.comments = it.comments;
            v.dateAdded = it.dateAdded ?: [NSDate dateWithTimeIntervalSince1970:0];
            v.duration = it.playbackDuration;
            v.views = it.playCount + [local[v.identifier] unsignedIntegerValue];
            [out addObject:v];
        }
    }
    self.videos = out;
    [[NSNotificationCenter defaultCenter] postNotificationName:LibraryDidReloadNotification object:self];
}

#pragma mark - Lists

- (NSArray<LocalVideo *> *)featured {
    return [self.videos sortedArrayUsingComparator:^NSComparisonResult(LocalVideo *a, LocalVideo *b) {
        return [b.dateAdded compare:a.dateAdded];
    }];
}

- (NSArray<LocalVideo *> *)mostViewed {
    return [self.videos sortedArrayUsingComparator:^NSComparisonResult(LocalVideo *a, LocalVideo *b) {
        if (a.views != b.views) return a.views > b.views ? NSOrderedAscending : NSOrderedDescending;
        return [a.title localizedCaseInsensitiveCompare:b.title];
    }];
}

- (NSArray<LocalVideo *> *)search:(NSString *)query {
    NSString *q = [query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (!q.length) return @[];
    NSMutableArray *out = [NSMutableArray array];
    for (LocalVideo *v in [self featured]) {
        if ([v.title rangeOfString:q options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [v.artist rangeOfString:q options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [v.comments rangeOfString:q options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [out addObject:v];
        }
    }
    return out;
}

- (NSArray<LocalVideo *> *)videosByArtist:(NSString *)artist excluding:(LocalVideo *)video {
    if (!artist.length) return @[];
    NSMutableArray *out = [NSMutableArray array];
    for (LocalVideo *v in [self featured]) {
        if ([v.artist isEqualToString:artist] && ![v.identifier isEqualToString:video.identifier]) {
            [out addObject:v];
        }
    }
    return out;
}

#pragma mark - Views and bookmarks

- (void)recordViewFor:(LocalVideo *)video {
    NSMutableDictionary *d = [[self localViews] mutableCopy];
    d[video.identifier] = @([d[video.identifier] unsignedIntegerValue] + 1);
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:kViewsKey];
    video.views += 1;
}

- (NSArray<NSString *> *)bookmarkIDs {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kBookmarksKey] ?: @[];
}

- (BOOL)isBookmarked:(LocalVideo *)video {
    return [[self bookmarkIDs] containsObject:video.identifier];
}

- (void)toggleBookmark:(LocalVideo *)video {
    NSMutableArray *ids = [[self bookmarkIDs] mutableCopy];
    if ([ids containsObject:video.identifier]) [ids removeObject:video.identifier];
    else [ids addObject:video.identifier];
    [[NSUserDefaults standardUserDefaults] setObject:ids forKey:kBookmarksKey];
}

- (NSArray<LocalVideo *> *)bookmarks {
    NSArray *ids = [self bookmarkIDs];
    NSMutableArray *out = [NSMutableArray array];
    for (NSString *ident in ids.reverseObjectEnumerator) {
        for (LocalVideo *v in self.videos) {
            if ([v.identifier isEqualToString:ident]) { [out addObject:v]; break; }
        }
    }
    return out;
}

- (void)clearBookmarks {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kBookmarksKey];
}

#pragma mark - Thumbnails

- (void)thumbnailForVideo:(LocalVideo *)video size:(CGSize)size completion:(void (^)(UIImage *))completion {
    NSString *key = [NSString stringWithFormat:@"%@-%.0fx%.0f", video.identifier, size.width, size.height];
    UIImage *cached = [self.thumbCache objectForKey:key];
    if (cached) { completion(cached); return; }

    dispatch_async(self.thumbQueue, ^{
        UIImage *img = [video.item.artwork imageWithSize:CGSizeMake(size.width * 2, size.height * 2)];
        if (!img) {
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:video.url options:nil];
            AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
            gen.appliesPreferredTrackTransform = YES;
            gen.maximumSize = CGSizeMake(size.width * 3, size.height * 3);
            NSTimeInterval t = MIN(video.duration * 0.1, 10.0);
            CGImageRef cg = [gen copyCGImageAtTime:CMTimeMakeWithSeconds(t, 600) actualTime:NULL error:NULL];
            if (cg) { img = [UIImage imageWithCGImage:cg]; CGImageRelease(cg); }
        }
        if (img) [self.thumbCache setObject:img forKey:key];
        dispatch_async(dispatch_get_main_queue(), ^{ completion(img); });
    });
}

@end
