#import <UIKit/UIKit.h>

// iOS 6-era look: glossy blue bars, black glossy tab bar, blue-grey pinstripes.
@interface Theme : NSObject
+ (void)apply;
+ (UIColor *)pinstripe;
+ (UIColor *)barBlue;
+ (UIColor *)linkBlue;
+ (UIImage *)playButtonImage;
+ (UIButton *)glossButtonWithTitle:(NSString *)title;
@end
