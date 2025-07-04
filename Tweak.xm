#import <UIKit/UIKit.h>
#import "Headers/NSTask.h"


@interface MTMaterialLayer : CALayer
@property (nonatomic, copy, readwrite) NSString *recipeName;
@property (atomic, assign, readonly) CGRect visibleRect;
@end

@interface MTMaterialView : UIView
@end

@interface CCUISteppedSliderView : UIControl
@end

@interface MRUNowPlayingView : UIView
@end

@interface MRUNowPlayingTransportControlsView : UIView
@end

@interface CCUIModularControlCenterViewController : UIViewController
@end

@interface CCUIContentModuleContentContainerView : UIView
@end

@interface CCUIOverlayViewController : UIViewController
@end

@interface CCUIModularControlCenterOverlayViewController : CCUIOverlayViewController
@end

@interface UIView (PrivateHierarchy)
- (UIViewController *)_viewControllerForAncestor;
@end

@interface CALayer (Private)
@property (assign) BOOL continuousCorners;
@property (atomic, assign, readwrite) id unsafeUnretainedDelegate;
@end

@class MTMaterialSettingsInterpolator;

@protocol MTRecipeMaterialSettingsProviding
- (id)baseMaterialSettings;
@end

@interface MTMaterialSettingsInterpolator : NSObject
@property (nonatomic, retain) id<MTRecipeMaterialSettingsProviding> finalSettings;
@end




#pragma mark - Calculation of border radius for different modules

CGFloat calculateArea(CGRect visibleRect) {
    return visibleRect.size.width * visibleRect.size.height;
}

CGFloat calculateAspect(CGRect visibleRect) {
    CGFloat width = visibleRect.size.width;
    CGFloat height = visibleRect.size.height;
    return (width > 0 && height > 0) ? (width / height) : 1.0;
}

CGFloat roundedToTwoDecimals(CGFloat value) {
    return round(value * 100.0) / 100.0;
}

CGFloat calculatedRadius(CGRect visibleRect, CGFloat fallbackRadius) {
    CGFloat width = visibleRect.size.width;
    CGFloat height = visibleRect.size.height;
    CGFloat aspect = roundedToTwoDecimals(calculateAspect(visibleRect));
    CGFloat area = calculateArea(visibleRect);

    // 💡 Logging (optional)
    // NSLog(@"[Radius] w:%.1f h:%.1f aspect:%.2f area:%.0f", width, height, aspect, area);

    if (CGSizeEqualToSize(visibleRect.size, [UIScreen mainScreen].bounds.size) || width <= 60 || height <= 60)
        return fallbackRadius;

    if (aspect == 1.00 && height <= 73)
        return fminf(width, height) / 2.0;

    if (aspect == 1.00 && width == height)
        return fminf(width, height) / 4.0;   

    //Slider vertical
   if (aspect >= 0.44 && aspect <= 0.54)
       return fminf(width, height) / 2.0;

    //Slider horizontal
    if (aspect >= 0.28 && aspect <= 0.32)
        return fminf(width, height) / 2.0;    

    if (aspect >= 2.18 && aspect <= 2.22)
        return fminf(width, height) / 2.0;    

    if (aspect >= 2.15 && aspect <= 2.17 )
        return fminf(width, height) / 2.0;      

    if (area == 48600 || area == 38745)
        return fminf(width, height) / 2.0;

    if (aspect >= 3.50 && aspect <= 4.00)    
        return fminf(width, height) / 4.0;

    if (width == height && height <= 85)
        return fminf(width, height) / 4.0;

    return 65.0;
}

CGFloat getModuleRadius(UIView *moduleView) {
    CGFloat width = moduleView.frame.size.width;
    CGFloat height = moduleView.frame.size.height;
    if ((width < 100 && height < 100) && width == height) { // 1x1 module
        return width / 2;
    } else if ((width > height) || (height > width)) {
        return fminf(width, height) / 2; // Rectangular module
    } else if ((width > 100 && height > 100) && width == height) { // large square module
        return width / 4;
    }
    return 0; // may need more cases for odd shaped modules such as CCSupport's 2x4 module
}

UIView *findSubviewOfClass(UIView *view, Class cls) {
    if ([view isKindOfClass:cls]) return view;
    for (UIView *subview in view.subviews) {
        UIView *match = findSubviewOfClass(subview, cls);
        if (match) return match;
    }
    return nil;
}

CGFloat calculatedRadiusForLayer(CALayer *layer, CGFloat fallbackRadius) {
    CGRect rect = layer.bounds;
    if (CGRectIsEmpty(rect)) {
        rect = layer.frame;
    }
    return calculatedRadius(rect, fallbackRadius);
}



#pragma mark - iOS 26 border

void applyPrismToLayer(CALayer *layer) {
    CAGradientLayer *gradient = nil;

    for (CALayer *sublayer in layer.sublayers) {
        if ([sublayer.name isEqualToString:@"iOS26PrismBorder"] && [sublayer isKindOfClass:[CAGradientLayer class]]) {
            gradient = (CAGradientLayer *)sublayer;
            break;
        }
    }

    if (!gradient) {
        gradient = [CAGradientLayer layer];
        gradient.name = @"iOS26PrismBorder";
        gradient.colors = @[
            (id)[[UIColor colorWithRed:0.8 green:0.75 blue:0.95 alpha:0.30] CGColor],
            (id)[[UIColor colorWithWhite:1.0 alpha:0.08] CGColor],
            (id)[[UIColor colorWithRed:0.9 green:0.85 blue:1.0 alpha:0.20] CGColor]
        ];
        gradient.locations = @[@0.0, @0.5, @1.0];
        gradient.startPoint = CGPointMake(0.0, 0.0);
        gradient.endPoint = CGPointMake(1.0, 1.0);
        gradient.contentsScale = [UIScreen mainScreen].scale;

        [layer insertSublayer:gradient atIndex:0];
    }

    gradient.frame = layer.bounds;
    gradient.masksToBounds = YES;
    gradient.cornerRadius = layer.cornerRadius;
}



%hook MTMaterialLayer

- (void)_configureIfNecessaryWithSettingsInterpolator:(MTMaterialSettingsInterpolator *)interpolator {
    %orig;
    id<MTRecipeMaterialSettingsProviding> settings = interpolator.finalSettings;
    id base = [settings baseMaterialSettings];
    if (![base respondsToSelector:@selector(setValue:forKey:)]) return;

    if ([self.recipeName isEqualToString:@"modules"]) {
        [base setValue:@(-0.04) forKey:@"brightness"];
        [base setValue:@(0.6) forKey:@"blurRadius"];
        [base setValue:@(-0.045) forKey:@"zoom"];
        [base setValue:@(1.0) forKey:@"saturation"];
        [base setValue:@(0) forKey:@"luminanceAmount"];
    } else if ([self.recipeName isEqualToString:@"modulesBackground"]) {
        [base setValue:@(0.0) forKey:@"zoom"];
        [base setValue:@(4.3) forKey:@"blurRadius"];
        [base setValue:@(-0.14) forKey:@"brightness"];
        [base setValue:@(1.1) forKey:@"saturation"];
    } else if ([self.recipeName isEqualToString:@"auxiliary"]) {
        [base setValue:@(2.3) forKey:@"blurRadius"];
    }
}

- (void)layoutSublayers {
    %orig;
    NSArray<NSString *> *titles = @[@"modules", @"moduleFill.highlight.generatedRecipe"];
    if (![titles containsObject:self.recipeName]) return;
        applyPrismToLayer(self);
}

%end

%hook MRUNowPlayingView

- (void)layoutSubviews {
    %orig;

    // Verhindere Änderungen außerhalb des Control Centers
    BOOL isInsideCC = NO;
    UIView *v = self;
    while (v.superview) {
        if ([v isKindOfClass:%c(CCUIContentModuleContentContainerView)]) {
            isInsideCC = YES;
            break;
        }
        v = v.superview;
    }
    if (!isInsideCC) return;

    NSInteger layout = ((NSNumber *)[self valueForKey:@"_layout"]).integerValue;
    if (layout == 2) return;

    UIView *artworkView = findSubviewOfClass(self, %c(MRUArtworkView));
    if (!artworkView) return;

    artworkView.frame = CGRectMake(16, 12, 50, 50);
    artworkView.alpha = 1.0;
    artworkView.layer.cornerRadius = 15;
    artworkView.layer.masksToBounds = YES;

    UIView *headerView = findSubviewOfClass(self, %c(MRUNowPlayingHeaderView));
    if (!headerView) return;

    CGFloat padding = 1.0;
    CGFloat headerX = padding;
    CGFloat headerY = CGRectGetMaxY(artworkView.frame) + 8;
    CGFloat headerWidth = self.bounds.size.width - 2 * padding;
    CGFloat headerHeight = 40;

    headerView.frame = CGRectMake(headerX, headerY, headerWidth, headerHeight);

    [headerView setValue:@(NSTextAlignmentLeft) forKey:@"textAlignment"];

    // Transport Controls nach unten verschieben
    UIView *transportControlsView = findSubviewOfClass(self, %c(MRUNowPlayingTransportControlsView));
    if (transportControlsView) {
        CGFloat controlsWidth = transportControlsView.frame.size.width;
        CGFloat controlsHeight = transportControlsView.frame.size.height;

        CGFloat x = (self.bounds.size.width - controlsWidth) / 2.0;
        CGFloat y = self.bounds.size.height - controlsHeight;

        transportControlsView.frame = CGRectMake(x, y, controlsWidth, controlsHeight);
    }
}

%end

%hook MRUNowPlayingTransportControlsView

- (void)layoutSubviews {
    %orig;

    // Kontrolle: Ist das Control Center aktiv?
    BOOL isInsideCC = NO;
    UIView *v = self;
    while (v.superview) {
        if ([v isKindOfClass:%c(CCUIContentModuleContentContainerView)]) {
            isInsideCC = YES;
            break;
        }
        v = v.superview;
    }
    if (!isInsideCC) return;

    // Optional: Kompaktmodus prüfen (Layout 0)
    MRUNowPlayingView *npView = (MRUNowPlayingView *)self.superview;
    NSInteger layout = [[npView valueForKey:@"_layout"] integerValue];
    if (layout == 2) return;

    // Buttons enger setzen
    UIButton *leftButton = [self valueForKey:@"leftButton"];
    UIButton *rightButton = [self valueForKey:@"rightButton"];
    UIButton *centerButton = [self valueForKey:@"centerButton"];

    if (leftButton && rightButton && centerButton) {
        CGPoint center = centerButton.center;
        CGFloat spacing = 40.0;

        leftButton.center = CGPointMake(center.x - spacing, center.y);
        rightButton.center = CGPointMake(center.x + spacing, center.y);
    }
}

%end



%hook CCUIContentModuleContentContainerView

- (void)layoutSubviews { // Hate to use this method, but only one that doesn't cause visual glitches
    BOOL opened = MSHookIvar<BOOL>(self, "_expanded");
    int radius = opened ? 65 : getModuleRadius(self); 
    self.clipsToBounds = YES;
    self.layer.cornerRadius = radius;
    self.layer.continuousCorners = YES; // Smooth corner into straight edges!!
    self.layer.borderWidth = 2.0;
    self.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;
    if (self.subviews.count == 1) {
        UIView *subview1 = [self subviews][0];
        if ([[subview1 subviews] count] >= 1) {
            UIView *subview2 = [subview1 subviews][0];
            if ([subview2 isKindOfClass:%c(CCUIContinuousSliderView)]) { // Volume Slider
                [subview2 setClipsToBounds:YES];
                [[subview2 layer] setCornerRadius:radius];
                subview2.layer.continuousCorners = YES;            
            } else {
                if ([[subview2 subviews] count] > 0) {
                    UIView *subview3 = [subview2 subviews][0];
                    if ([[subview3 subviews] count] > 0) {
                        UIView *subview4 = [subview3 subviews][0];
                        if ([[subview4 subviews] count] > 0) {
                            UIView *subview5 = [subview4 subviews][0];
                            if ([subview5 isKindOfClass: %c(MTMaterialView)]) {
                                [[subview5 layer] setCornerRadius:radius];
                                subview5.layer.continuousCorners = YES;
                            }
                        }
                    }
                }
            }
        }
    } else if (self.subviews.count > 1) {
        UIView *subview = [self subviews][1];
        if ([subview isKindOfClass: %c(CCUIContinuousSliderView)]) {
            [[subview layer] setCornerRadius:radius];
            subview.layer.continuousCorners = YES;
            subview.clipsToBounds = NO;
        }
    }
}

%end

%hook CCUIModularControlCenterOverlayViewController

- (void)setPresentationState:(NSInteger)state {
    %orig;

    UIView *view = self.view;
    CGFloat iconSize = 14; // Kleinere Icons
    CGFloat buttonPadding = 6; // Button etwas größer für Touchfläche
    CGFloat buttonSize = iconSize + buttonPadding;
    CGFloat yOffset = 23;
    CGFloat safeLeft = view.window.safeAreaInsets.left ?: 36;
    CGFloat safeRight = view.window.safeAreaInsets.right ?: 36;

    UIButton *plus = [view viewWithTag:999];
    if (!plus) {
        plus = [UIButton buttonWithType:UIButtonTypeSystem];
        plus.tag = 999;

        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:iconSize weight:UIImageSymbolWeightRegular];
        UIImage *plusImage = [[UIImage systemImageNamed:@"plus"] imageByApplyingSymbolConfiguration:config];

        [plus setImage:plusImage forState:UIControlStateNormal];
        plus.tintColor = [UIColor whiteColor];
        plus.alpha = 0.0;
        plus.transform = CGAffineTransformMakeScale(0.6, 0.6);
        plus.frame = CGRectMake(safeLeft, yOffset - 10, buttonSize, buttonSize);

        [plus addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
            UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
            [gen impactOccurred];
            NSLog(@"[+] Plus tapped");
        }] forControlEvents:UIControlEventTouchUpInside];

        [view addSubview:plus];
    }

    UIButton *power = [view viewWithTag:998];
    if (!power) {
        power = [UIButton buttonWithType:UIButtonTypeSystem];
        power.tag = 998;

        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:iconSize weight:UIImageSymbolWeightRegular];
        UIImage *powerImage = [[UIImage systemImageNamed:@"power"] imageByApplyingSymbolConfiguration:config];

        [power setImage:powerImage forState:UIControlStateNormal];
        power.tintColor = [UIColor redColor];
        power.alpha = 0.0;
        power.transform = CGAffineTransformMakeScale(0.6, 0.6);
        power.frame = CGRectMake(view.bounds.size.width - safeRight - buttonSize , yOffset - 10, buttonSize, buttonSize);

        if (@available(iOS 14.0, *)) {
            UIAction *respringAction = [UIAction actionWithTitle:@"Respring"
                                                           image:[UIImage systemImageNamed:@"arrow.clockwise.circle"]
                                                      identifier:nil
                                                         handler:^(__kindof UIAction *action) {
                NSTask *task = [[NSTask alloc] init];
                [task setLaunchPath:@"/usr/bin/sbreload"];
                [task launch];
            }];

            UIAction *uicacheAction = [UIAction actionWithTitle:@"UICache"
                                                          image:[UIImage systemImageNamed:@"paintbrush.fill"]
                                                     identifier:nil
                                                        handler:^(__kindof UIAction *action) {
                NSTask *task = [[NSTask alloc] init];
                [task setLaunchPath:@"/usr/bin/uicache"];
                [task setArguments:@[@"-a"]];
                [task launch];
            }];

            UIAction *userspaceAction = [UIAction actionWithTitle:@"Userspace Reboot"
                                                            image:[UIImage systemImageNamed:@"bolt.fill"]
                                                       identifier:nil
                                                          handler:^(__kindof UIAction *action) {
                NSTask *task = [[NSTask alloc] init];
                [task setLaunchPath:@"/bin/launchctl"];
                [task setArguments:@[@"reboot", @"userspace"]];
                [task launch];
            }];

            UIMenu *menu = [UIMenu menuWithTitle:@"Choose Action"
                                          children:@[respringAction, uicacheAction, userspaceAction]];
            [power setMenu:menu];
            [power setShowsMenuAsPrimaryAction:YES];

            [power addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
                UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
                [gen impactOccurred];
            }] forControlEvents:UIControlEventPrimaryActionTriggered];
        }

        [view addSubview:power];
    }

    // Update Frames (z. B. bei Rotation)
    plus.frame = CGRectMake(safeLeft - 10, yOffset - 10, buttonSize + 15, buttonSize + 15);
    power.frame = CGRectMake(view.bounds.size.width - safeRight - buttonSize - 10, yOffset - 10, buttonSize + 15, buttonSize + 15);

    switch (state) {
        case 1: {
            plus.transform = CGAffineTransformMakeScale(0.6, 0.6);
            power.transform = CGAffineTransformMakeScale(0.6, 0.6);
            [UIView animateWithDuration:0.45
                                  delay:0.0
                 usingSpringWithDamping:0.7
                  initialSpringVelocity:0.5
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                plus.alpha = 1.0;
                plus.transform = CGAffineTransformIdentity;
                power.alpha = 1.0;
                power.transform = CGAffineTransformIdentity;
            } completion:nil];
            break;
        }
        case 3: {
            [UIView animateWithDuration:0.2 animations:^{
                plus.alpha = 0.0;
                plus.transform = CGAffineTransformMakeScale(0.6, 0.6);
                power.alpha = 0.0;
                power.transform = CGAffineTransformMakeScale(0.6, 0.6);
            }];
            break;
        }
        default:
            break;
    }
}

%end
