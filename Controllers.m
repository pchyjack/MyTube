#import "Controllers.h"
#import "Theme.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

#define RGB(r, g, b) [UIColor colorWithRed:(r) green:(g) blue:(b) alpha:1.0]

static NSString *ViewsString(NSUInteger n) {
    return [NSString stringWithFormat:@"%lu view%@", (unsigned long)n, n == 1 ? @"" : @"s"];
}

static NSString *DateString(NSDate *d) {
    static NSDateFormatter *f;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        f = [[NSDateFormatter alloc] init];
        f.dateStyle = NSDateFormatterMediumStyle;
        f.timeStyle = NSDateFormatterNoStyle;
    });
    return [f stringFromDate:d];
}

#pragma mark - Row cell (old-style YouTube list row)

@interface VideoCell : UITableViewCell
@property (nonatomic, strong) UIImageView *thumb;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *channelLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@property (nonatomic, copy) NSString *representedID;
- (void)configureWithVideo:(LocalVideo *)video;
@end

@implementation VideoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        _thumb = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 96, 72)];
        _thumb.contentMode = UIViewContentModeScaleAspectFill;
        _thumb.clipsToBounds = YES;
        _thumb.backgroundColor = UIColor.blackColor;
        _thumb.layer.borderWidth = 1;
        _thumb.layer.borderColor = RGB(0.6, 0.6, 0.6).CGColor;
        [self.contentView addSubview:_thumb];

        _durationLabel = [[UILabel alloc] init];
        _durationLabel.font = [UIFont boldSystemFontOfSize:11];
        _durationLabel.textColor = UIColor.whiteColor;
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        [self.contentView addSubview:_durationLabel];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:15];
        _titleLabel.textColor = RGB(0.08, 0.08, 0.08);
        _titleLabel.numberOfLines = 2;
        [self.contentView addSubview:_titleLabel];

        _channelLabel = [[UILabel alloc] init];
        _channelLabel.font = [UIFont systemFontOfSize:13];
        _channelLabel.textColor = [Theme linkBlue];
        [self.contentView addSubview:_channelLabel];

        _metaLabel = [[UILabel alloc] init];
        _metaLabel.font = [UIFont systemFontOfSize:12];
        _metaLabel.textColor = RGB(0.5, 0.5, 0.5);
        [self.contentView addSubview:_metaLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat x = 114;
    CGFloat w = MAX(40, self.contentView.bounds.size.width - x - 6);
    self.titleLabel.frame = CGRectMake(x, 8, w, 38);
    self.channelLabel.frame = CGRectMake(x, 48, w, 16);
    self.metaLabel.frame = CGRectMake(x, 64, w, 16);

    [self.durationLabel sizeToFit];
    CGFloat dw = self.durationLabel.bounds.size.width + 8;
    CGRect tf = self.thumb.frame;
    self.durationLabel.frame = CGRectMake(CGRectGetMaxX(tf) - dw - 1, CGRectGetMaxY(tf) - 16, dw, 15);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.thumb.image = nil;
    self.representedID = nil;
}

- (void)configureWithVideo:(LocalVideo *)video {
    self.representedID = video.identifier;
    self.titleLabel.text = video.title;
    self.channelLabel.text = video.artist.length ? video.artist : @"Unknown channel";
    self.metaLabel.text = [NSString stringWithFormat:@"%@ • %@", ViewsString(video.views), DateString(video.dateAdded)];
    self.durationLabel.text = [video durationString];
    [self setNeedsLayout];

    __weak VideoCell *weak = self;
    NSString *ident = video.identifier;
    [[Library shared] thumbnailForVideo:video size:CGSizeMake(96, 72) completion:^(UIImage *image) {
        if ([weak.representedID isEqualToString:ident]) weak.thumb.image = image;
    }];
}

@end

#pragma mark - Lists (Featured / Most Viewed / Search / Bookmarks / Channel)

@interface VideoListViewController () <UISearchBarDelegate>
@property (nonatomic) ListMode mode;
@property (nonatomic, strong) NSArray<LocalVideo *> *rows;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UILabel *emptyLabel;
@end

@implementation VideoListViewController

- (instancetype)initWithMode:(ListMode)mode {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        _mode = mode;
        _rows = @[];
        switch (mode) {
            case ListModeFeatured:   self.title = @"Featured"; break;
            case ListModeMostViewed: self.title = @"Most Viewed"; break;
            case ListModeSearch:     self.title = @"Search"; break;
            case ListModeBookmarks:  self.title = @"Bookmarks"; break;
            case ListModeChannel:    self.title = @"Channel"; break;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 88;
    self.tableView.backgroundColor = UIColor.whiteColor;
    self.tableView.separatorColor = RGB(0.82, 0.82, 0.82);

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.font = [UIFont systemFontOfSize:16];
    self.emptyLabel.textColor = RGB(0.45, 0.48, 0.55);
    self.tableView.backgroundView = self.emptyLabel;

    if (self.mode == ListModeSearch) {
        self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        self.searchBar.placeholder = @"Search your videos";
        self.searchBar.delegate = self;
        self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.tableView.tableHeaderView = self.searchBar;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh)
                                                 name:LibraryDidReloadNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)refresh {
    Library *lib = [Library shared];
    switch (self.mode) {
        case ListModeFeatured:   self.rows = [lib featured]; break;
        case ListModeMostViewed: self.rows = [lib mostViewed]; break;
        case ListModeSearch:     self.rows = [lib search:self.searchBar.text]; break;
        case ListModeBookmarks:  self.rows = [lib bookmarks]; break;
        case ListModeChannel:    self.rows = [lib videosByArtist:self.channel excluding:self.excluded]; break;
    }

    NSString *msg = nil;
    if (self.rows.count == 0) {
        if (!lib.authorized) {
            msg = @"MyTube can't see your videos yet.\nAllow access to Media & Apple Music in Settings › MyTube.";
        } else if (self.mode == ListModeSearch) {
            msg = self.searchBar.text.length ? @"No videos found." : @"Search the videos on this device.";
        } else if (self.mode == ListModeBookmarks) {
            msg = @"No bookmarks yet.\nOpen a video and tap Add to Bookmarks.";
        } else {
            msg = @"No videos found.\nAdd videos to the Videos app and reopen MyTube.";
        }
    }
    self.emptyLabel.text = msg;
    self.emptyLabel.hidden = (msg == nil);
    [self.tableView reloadData];
}

#pragma mark Table

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    return self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    VideoCell *cell = [tv dequeueReusableCellWithIdentifier:@"video"];
    if (!cell) cell = [[VideoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"video"];
    [cell configureWithVideo:self.rows[ip.row]];
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    [self.searchBar resignFirstResponder];
    VideoDetailViewController *d = [[VideoDetailViewController alloc] initWithVideo:self.rows[ip.row]];
    [self.navigationController pushViewController:d animated:YES];
}

- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip {
    return self.mode == ListModeBookmarks;
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip {
    if (style == UITableViewCellEditingStyleDelete) {
        [[Library shared] toggleBookmark:self.rows[ip.row]];
        [self refresh];
    }
}

#pragma mark Search

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText { [self refresh]; }
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar { [searchBar resignFirstResponder]; }

@end

#pragma mark - Video detail page

@interface VideoDetailViewController ()
@property (nonatomic, strong) LocalVideo *video;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UIImageView *poster;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UILabel *titleL, *channelL, *metaL, *descL;
@property (nonatomic, strong) UIButton *bookmarkButton, *moreButton;
@end

@implementation VideoDetailViewController

- (instancetype)initWithVideo:(LocalVideo *)video {
    if ((self = [super init])) {
        _video = video;
        self.title = @"Video";
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [Theme pinstripe];

    self.scroll = [[UIScrollView alloc] init];
    self.scroll.alwaysBounceVertical = YES;
    [self.view addSubview:self.scroll];

    self.poster = [[UIImageView alloc] init];
    self.poster.backgroundColor = UIColor.blackColor;
    self.poster.contentMode = UIViewContentModeScaleAspectFit;
    self.poster.userInteractionEnabled = YES;
    [self.poster addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(play)]];
    [self.scroll addSubview:self.poster];

    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playButton setImage:[Theme playButtonImage] forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    [self.scroll addSubview:self.playButton];

    self.panel = [[UIView alloc] init];
    self.panel.backgroundColor = UIColor.whiteColor;
    self.panel.layer.cornerRadius = 8;
    self.panel.layer.borderWidth = 1;
    self.panel.layer.borderColor = RGB(0.68, 0.70, 0.74).CGColor;
    [self.scroll addSubview:self.panel];

    self.titleL = [self labelWithFont:[UIFont boldSystemFontOfSize:17] color:RGB(0.08, 0.08, 0.08) lines:0];
    self.channelL = [self labelWithFont:[UIFont systemFontOfSize:14] color:[Theme linkBlue] lines:1];
    self.metaL = [self labelWithFont:[UIFont systemFontOfSize:12] color:RGB(0.5, 0.5, 0.5) lines:1];
    self.descL = [self labelWithFont:[UIFont systemFontOfSize:14] color:RGB(0.25, 0.25, 0.25) lines:0];

    self.bookmarkButton = [Theme glossButtonWithTitle:@""];
    [self.bookmarkButton addTarget:self action:@selector(toggleBookmark) forControlEvents:UIControlEventTouchUpInside];
    [self.scroll addSubview:self.bookmarkButton];

    if (self.video.artist.length) {
        self.moreButton = [Theme glossButtonWithTitle:[NSString stringWithFormat:@"More from %@", self.video.artist]];
        [self.moreButton addTarget:self action:@selector(showChannel) forControlEvents:UIControlEventTouchUpInside];
        [self.scroll addSubview:self.moreButton];
    }

    [self refreshInfo];

    __weak VideoDetailViewController *weak = self;
    [[Library shared] thumbnailForVideo:self.video size:CGSizeMake(320, 180) completion:^(UIImage *image) {
        weak.poster.image = image;
    }];
}

- (UILabel *)labelWithFont:(UIFont *)font color:(UIColor *)color lines:(NSInteger)lines {
    UILabel *l = [[UILabel alloc] init];
    l.font = font;
    l.textColor = color;
    l.numberOfLines = lines;
    [self.panel addSubview:l];
    return l;
}

- (void)refreshInfo {
    self.titleL.text = self.video.title;
    self.channelL.text = self.video.artist.length ? self.video.artist : @"Unknown channel";
    self.metaL.text = [NSString stringWithFormat:@"%@ • %@ • %@", ViewsString(self.video.views),
                       [self.video durationString], DateString(self.video.dateAdded)];
    self.descL.text = self.video.comments.length ? self.video.comments : @"No description.";
    [self.bookmarkButton setTitle:([[Library shared] isBookmarked:self.video] ? @"Remove from Bookmarks" : @"Add to Bookmarks")
                         forState:UIControlStateNormal];
    [self.view setNeedsLayout];
}

- (CGFloat)heightOf:(NSString *)text font:(UIFont *)font width:(CGFloat)w {
    CGRect r = [text boundingRectWithSize:CGSizeMake(w, CGFLOAT_MAX)
                                  options:NSStringDrawingUsesLineFragmentOrigin
                               attributes:@{NSFontAttributeName: font} context:nil];
    return ceil(r.size.height);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat W = self.view.bounds.size.width;
    self.scroll.frame = self.view.bounds;

    CGFloat ph = floor(W * 9.0 / 16.0);
    self.poster.frame = CGRectMake(0, 0, W, ph);
    self.playButton.frame = CGRectMake((W - 64) / 2, (ph - 64) / 2, 64, 64);

    CGFloat pw = W - 20, inner = pw - 20, y = 10;
    CGFloat th = [self heightOf:self.titleL.text font:self.titleL.font width:inner];
    self.titleL.frame = CGRectMake(10, y, inner, th);   y += th + 4;
    self.channelL.frame = CGRectMake(10, y, inner, 18); y += 20;
    self.metaL.frame = CGRectMake(10, y, inner, 16);    y += 24;
    CGFloat dh = [self heightOf:self.descL.text font:self.descL.font width:inner];
    self.descL.frame = CGRectMake(10, y, inner, dh);    y += dh + 10;
    self.panel.frame = CGRectMake(10, ph + 12, pw, y);

    CGFloat by = CGRectGetMaxY(self.panel.frame) + 12;
    self.bookmarkButton.frame = CGRectMake(10, by, pw, 44); by += 54;
    if (self.moreButton) { self.moreButton.frame = CGRectMake(10, by, pw, 44); by += 54; }
    self.scroll.contentSize = CGSizeMake(W, by + 6);
}

- (void)play {
    AVPlayerViewController *pvc = [[AVPlayerViewController alloc] init];
    pvc.player = [AVPlayer playerWithURL:self.video.url];
    [[Library shared] recordViewFor:self.video];
    [self refreshInfo];
    [self presentViewController:pvc animated:YES completion:^{ [pvc.player play]; }];
}

- (void)toggleBookmark {
    [[Library shared] toggleBookmark:self.video];
    [self refreshInfo];
}

- (void)showChannel {
    VideoListViewController *list = [[VideoListViewController alloc] initWithMode:ListModeChannel];
    list.channel = self.video.artist;
    list.excluded = self.video;
    list.title = self.video.artist;
    [self.navigationController pushViewController:list animated:YES];
}

@end

#pragma mark - More tab

@implementation MoreViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        self.title = @"More";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *bg = [[UIView alloc] init];
    bg.backgroundColor = [Theme pinstripe];
    self.tableView.backgroundView = bg;
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData)
                                                 name:LibraryDidReloadNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 3; }

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return s == 0 ? 2 : (s == 1 ? 2 : 1);
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    return @[@"Library", @"Tools", @"About"][s];
}

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s {
    return s == 2 ? @"Plays the videos stored in the Videos app on this device. Nothing is sent over the network." : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    Library *lib = [Library shared];
    if (ip.section == 0) {
        if (ip.row == 0) {
            cell.textLabel.text = @"Videos";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)lib.allVideos.count];
        } else {
            NSInteger t = (NSInteger)lib.totalDuration;
            cell.textLabel.text = @"Total Length";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ldh %ldm", (long)(t / 3600), (long)((t % 3600) / 60)];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (ip.section == 1) {
        cell.textLabel.text = ip.row == 0 ? @"Rescan Library" : @"Clear Bookmarks";
        cell.textLabel.textColor = [Theme linkBlue];
    } else {
        cell.textLabel.text = @"MyTube";
        cell.detailTextLabel.text = @"1.0.0";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.section != 1) return;
    if (ip.row == 0) {
        [[Library shared] requestAccessAndLoad];
    } else {
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Clear Bookmarks?"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [a addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) {
            [[Library shared] clearBookmarks];
        }]];
        [self presentViewController:a animated:YES completion:nil];
    }
}

@end
