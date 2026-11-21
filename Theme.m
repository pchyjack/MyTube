#import "Theme.h"

#define RGB(r, g, b) [UIColor colorWithRed:(r) green:(g) blue:(b) alpha:1.0]

// Vertical gradient with optional 1px lines at the top and bottom.
static UIImage *GradientImage(CGSize size, NSArray<UIColor *> *colors, NSArray<NSNumber *> *locs,
                              UIColor *topLine, UIColor *bottomLine) {
    UIGraphicsImageRendererFormat *fmt = [UIGraphicsImageRendererFormat preferredFormat];
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:size format:fmt];
    UIImage *img = [r imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGContextRef c = ctx.CGContext;
        NSMutableArray *cg = [NSMutableArray array];
        for (UIColor *col in colors) [cg addObject:(id)col.CGColor];
        CGFloat l[8] = {0};
        for (NSUInteger i = 0; i < locs.count && i < 8; i++) l[i] = locs[i].doubleValue;
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGGradientRef g = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)cg, l);
        CGContextDrawLinearGradient(c, g, CGPointMake(0, 0), CGPointMake(0, size.height), 0);
        CGGradientRelease(g);
        CGColorSpaceRelease(cs);
        if (topLine) {
            [topLine setFill];
            CGContextFillRect(c, CGRectMake(0, 0, size.width, 1));
        }
        if (bottomLine) {
            [bottomLine setFill];
            CGContextFillRect(c, CGRectMake(0, size.height - 1, size.width, 1));
        }
    }];
    return [img resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
}

@implementation Theme

+ (UIColor *)barBlue  { return RGB(0.36, 0.47, 0.64); }
+ (UIColor *)linkBlue { return RGB(0.20, 0.33, 0.55); }

+ (UIImage *)navBarImage {
    return GradientImage(CGSizeMake(4, 64),
        @[RGB(0.66, 0.73, 0.82), RGB(0.47, 0.58, 0.72), RGB(0.40, 0.51, 0.67), RGB(0.34, 0.45, 0.61)],
        @[@0, @0.5, @0.5, @1],
        RGB(0.78, 0.84, 0.90), RGB(0.18, 0.25, 0.37));
}

+ (UIImage *)tabBarImage {
    return GradientImage(CGSizeMake(4, 49),
        @[RGB(0.30, 0.30, 0.32), RGB(0.12, 0.12, 0.13), RGB(0.02, 0.02, 0.03), RGB(0.07, 0.07, 0.08)],
        @[@0, @0.5, @0.5, @1],
        RGB(0.05, 0.05, 0.05), nil);
}

+ (UIImage *)tabSelectedImage {
    return GradientImage(CGSizeMake(4, 49),
        @[RGB(0.26, 0.32, 0.42), RGB(0.16, 0.20, 0.28), RGB(0.08, 0.10, 0.16), RGB(0.12, 0.16, 0.24)],
        @[@0, @0.5, @0.5, @1],
        nil, nil);
}

+ (UIColor *)pinstripe {
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(7, 7)];
    UIImage *img = [r imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [RGB(0.773, 0.800, 0.831) setFill];
        CGContextFillRect(ctx.CGContext, CGRectMake(0, 0, 7, 7));
        [RGB(0.812, 0.835, 0.863) setFill];
        CGContextFillRect(ctx.CGContext, CGRectMake(0, 0, 3, 7));
    }];
    return [UIColor colorWithPatternImage:img];
}

+ (void)apply {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = CGSizeMake(0, -1);
    shadow.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];

    UINavigationBarAppearance *nav = [[UINavigationBarAppearance alloc] init];
    [nav configureWithOpaqueBackground];
    nav.backgroundImage = [self navBarImage];
    nav.shadowColor = nil;
    nav.titleTextAttributes = @{
        NSForegroundColorAttributeName: UIColor.whiteColor,
        NSFontAttributeName: [UIFont boldSystemFontOfSize:20],
        NSShadowAttributeName: shadow,
    };
    UINavigationBar *nb = [UINavigationBar appearance];
    nb.standardAppearance = nav;
    nb.scrollEdgeAppearance = nav;
    nb.compactAppearance = nav;
    nb.tintColor = UIColor.whiteColor;

    UITabBarAppearance *tab = [[UITabBarAppearance alloc] init];
    [tab configureWithOpaqueBackground];
    tab.backgroundImage = [self tabBarImage];
    tab.shadowColor = nil;
    tab.selectionIndicatorImage = [self tabSelectedImage];
    UIColor *normal = RGB(0.62, 0.62, 0.64);
    UIColor *selected = RGB(0.35, 0.65, 1.0);
    for (UITabBarItemAppearance *item in @[tab.stackedLayoutAppearance,
                                           tab.inlineLayoutAppearance,
                                           tab.compactInlineLayoutAppearance]) {
        item.normal.iconColor = normal;
        item.normal.titleTextAttributes = @{NSForegroundColorAttributeName: normal};
        item.selected.iconColor = selected;
        item.selected.titleTextAttributes = @{NSForegroundColorAttributeName: selected};
    }
    UITabBar *tb = [UITabBar appearance];
    tb.standardAppearance = tab;
    tb.scrollEdgeAppearance = tab;

    [UISearchBar appearance].barTintColor = RGB(0.47, 0.58, 0.72);
    [UISearchBar appearance].tintColor = UIColor.whiteColor;
}

+ (UIImage *)playButtonImage {
    CGSize s = CGSizeMake(64, 64);
    UIGraphicsImageRenderer *r = [[UIGraphicsImageRenderer alloc] initWithSize:s];
    return [r imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGContextRef c = ctx.CGContext;
        CGRect rect = CGRectMake(2, 2, 60, 60);
        [[UIColor colorWithWhite:0 alpha:0.6] setFill];
        CGContextFillEllipseInRect(c, rect);
        [[UIColor colorWithWhite:1 alpha:0.9] setStroke];
        CGContextSetLineWidth(c, 3);
        CGContextStrokeEllipseInRect(c, rect);
        [[UIColor whiteColor] setFill];
        CGContextMoveToPoint(c, 26, 18);
        CGContextAddLineToPoint(c, 26, 46);
        CGContextAddLineToPoint(c, 48, 32);
        CGContextClosePath(c);
        CGContextFillPath(c);
    }];
}

+ (UIButton *)glossButtonWithTitle:(NSString *)title {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *normal = GradientImage(CGSizeMake(4, 44),
        @[RGB(0.60, 0.69, 0.80), RGB(0.38, 0.52, 0.71), RGB(0.28, 0.43, 0.64), RGB(0.33, 0.48, 0.70)],
        @[@0, @0.5, @0.5, @1], nil, nil);
    UIImage *pressed = GradientImage(CGSizeMake(4, 44),
        @[RGB(0.38, 0.46, 0.58), RGB(0.24, 0.34, 0.50), RGB(0.17, 0.28, 0.45), RGB(0.21, 0.32, 0.50)],
        @[@0, @0.5, @0.5, @1], nil, nil);
    [b setBackgroundImage:normal forState:UIControlStateNormal];
    [b setBackgroundImage:pressed forState:UIControlStateHighlighted];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [b setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.5] forState:UIControlStateNormal];
    b.titleLabel.shadowOffset = CGSizeMake(0, -1);
    b.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    b.layer.cornerRadius = 7;
    b.layer.masksToBounds = YES;
    b.layer.borderWidth = 1;
    b.layer.borderColor = RGB(0.20, 0.30, 0.45).CGColor;
    return b;
}

@end
