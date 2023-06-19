//
//  Created by Andrew Podkovyrin
//  Copyright © 2020 Dash Core Group. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "DWUsernameHeaderView.h"

#import "DWDPAvatarView.h"
#import "DWPlanetarySystemView.h"
#import "DWUIKit.h"

static CGFloat const BottomSpacing(void) {
    if (IS_IPHONE_5_OR_LESS || IS_IPHONE_6) {
        return 4.0;
    }
    else {
        return 16.0;
    }
}

static CGFloat SmallCircleRadius(void) {
    if (IS_IPHONE_5_OR_LESS || IS_IPHONE_6) {
        return 106.0;
    }
    else {
        return 78.0;
    }
}

static CGFloat PlanetarySize(void) {
    if (IS_IPHONE_5_OR_LESS || IS_IPHONE_6) {
        return 260.0;
    }
    else {
        const CGSize screenSize = [UIScreen mainScreen].bounds.size;
        const CGFloat side = MIN(screenSize.width, screenSize.height);
        return MIN(375.0, side);
    }
}

static NSArray<UIColor *> *OrbitColors(void) {
    // Luckily, DashBlueColor doesn't have DarkMode counterpart
    // and we don't need to reset colors on traitCollectionDidChange:
    UIColor *color = [UIColor dw_dashBlueColor];

    if (IS_IPHONE_5_OR_LESS || IS_IPHONE_6) {
        return @[
            [color colorWithAlphaComponent:0.3],
            [color colorWithAlphaComponent:0.1],
            [color colorWithAlphaComponent:0.07],
        ];
    }
    else {
        return @[
            [color colorWithAlphaComponent:0.5],
            [color colorWithAlphaComponent:0.3],
            [color colorWithAlphaComponent:0.1],
            [color colorWithAlphaComponent:0.07],
        ];
    }
}

static NSArray<DWPlanetObject *> *Planets(NSString *_Nullable username) {
    CGSize size;
    CGSize avatarSize;
    if (IS_IPHONE_5_OR_LESS || IS_IPHONE_6) {
        size = CGSizeMake(28.0, 28.0);
        avatarSize = CGSizeMake(46.0, 46.0);
    }
    else {
        size = CGSizeMake(36.0, 36.0);
        avatarSize = CGSizeMake(60.0, 60.0);
    }

    NSMutableArray<DWPlanetObject *> *planets = [NSMutableArray array];

    if (IS_IPHONE_5_OR_LESS || IS_IPHONE_6) {
        {
            DWPlanetObject *planet = [[DWPlanetObject alloc] init];
            planet.image = [UIImage imageNamed:@"dp_user_2"];
            planet.speed = 1.55;
            planet.duration = 0.75;
            planet.offset = 255.0 / 360.0;
            planet.size = size;
            planet.orbit = 0;
            planet.rotateClockwise = YES;
            [planets addObject:planet];
        }

        {
            DWPlanetObject *planet = [[DWPlanetObject alloc] init];
            planet.image = [UIImage imageNamed:@"dp_user_3"];
            planet.speed = 1.3;
            planet.duration = 0.75;
            planet.offset = 230.0 / 360.0;
            planet.size = size;
            planet.orbit = 1;
            planet.rotateClockwise = YES;
            [planets addObject:planet];
        }

        {
            DWPlanetObject *planet = [[DWPlanetObject alloc] init];
            if (username.length > 0) {
                DWDPAvatarView *avatarView = [[DWDPAvatarView alloc] initWithFrame:(CGRect){{0.0, 0.0}, avatarSize}];
                [avatarView configureWithUsername:username];
                planet.customView = avatarView;
            }
            else {
                planet.image = [UIImage imageNamed:@"dp_user_generic"];
            }
            planet.speed = 1.0;
            planet.duration = 0.75;
            planet.offset = 250.0 / 360.0;
            planet.size = size;
            planet.orbit = 2;
            planet.rotateClockwise = YES;
            [planets addObject:planet];
        }
    }
    else {
        {
            DWPlanetObject *planet = [[DWPlanetObject alloc] init];
            planet.image = [UIImage imageNamed:@"dp_user_1"];
            planet.speed = 2.1;
            planet.duration = 0.75;
            planet.offset = 245.0 / 360.0;
            planet.size = size;
            planet.orbit = 0;
            planet.rotateClockwise = YES;
            [planets addObject:planet];
        }

        {
            DWPlanetObject *planet = [[DWPlanetObject alloc] init];
            planet.image = [UIImage imageNamed:@"dp_user_2"];
            planet.speed = 1.8;
            planet.duration = 0.75;
            planet.offset = 255.0 / 360.0;
            planet.size = size;
            planet.orbit = 1;
            planet.rotateClockwise = YES;
            [planets addObject:planet];
        }

        {
            DWPlanetObject *planet = [[DWPlanetObject alloc] init];
            planet.image = [UIImage imageNamed:@"dp_user_3"];
            planet.speed = 1.55;
            planet.duration = 0.75;
            planet.offset = 230.0 / 360.0;
            planet.size = size;
            planet.orbit = 2;
            planet.rotateClockwise = YES;
            [planets addObject:planet];
        }

        {
            DWPlanetObject *planet = [[DWPlanetObject alloc] init];
            planet.image = [UIImage imageNamed:@"dp_user_2"]; // TODO: fix image
            planet.speed = 1.3;
            planet.duration = 0.75;
            planet.offset = 200.0 / 360.0;
            planet.size = size;
            planet.orbit = 3;
            planet.rotateClockwise = YES;
            [planets addObject:planet];
        }

        {
            DWPlanetObject *planet = [[DWPlanetObject alloc] init];
            if (username.length > 0) {
                DWDPAvatarView *avatarView = [[DWDPAvatarView alloc] initWithFrame:(CGRect){{0.0, 0.0}, avatarSize}];
                [avatarView configureWithUsername:username];
                planet.customView = avatarView;
            }
            else {
                planet.image = [UIImage imageNamed:@"dp_user_generic"];
            }
            planet.speed = 1.0;
            planet.duration = 0.75;
            planet.offset = 250.0 / 360.0;
            planet.size = size;
            planet.orbit = 3;
            planet.rotateClockwise = YES;
            [planets addObject:planet];
        }
    }

    return [planets copy];
}

NS_ASSUME_NONNULL_BEGIN

@interface DWUsernameHeaderView ()

@property (strong, nonatomic) DWPlanetarySystemView *planetaryView;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, copy) NSArray<NSLayoutConstraint *> *portraitConstraints;
@property (nonatomic, copy) NSArray<NSLayoutConstraint *> *landscapeConstraints;

@end

NS_ASSUME_NONNULL_END

@implementation DWUsernameHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor dw_backgroundColor];

        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
        [cancelButton setImage:[UIImage imageNamed:@"payments_nav_cross"] forState:UIControlStateNormal];
        [self addSubview:cancelButton];
        _cancelButton = cancelButton;

        NSArray<UIColor *> *colors = OrbitColors();

        DWPlanetarySystemView *planetaryView = [[DWPlanetarySystemView alloc] initWithFrame:CGRectZero];
        planetaryView.translatesAutoresizingMaskIntoConstraints = NO;
        planetaryView.centerOffset = SmallCircleRadius();
        planetaryView.colors = colors;
        planetaryView.lineWidth = 1.0;
        planetaryView.numberOfOrbits = colors.count;
        planetaryView.planets = Planets(nil);
        [self addSubview:planetaryView];
        _planetaryView = planetaryView;

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.numberOfLines = 3;
        [self addSubview:titleLabel];
        _titleLabel = titleLabel;

        const CGFloat buttonSize = 44.0;
        const CGFloat side = PlanetarySize();
        CGPoint planetOffest = CGPointZero;
        if (IS_IPHONE_5_OR_LESS || IS_IPHONE_6) {
            planetOffest = CGPointMake(16.0, -66.0);
        }

        _landscapeConstraints = @[
            [titleLabel.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor],
            [titleLabel.leadingAnchor constraintEqualToAnchor:cancelButton.trailingAnchor
                                                     constant:16.0],
        ];

        _portraitConstraints = @[
            [titleLabel.topAnchor constraintGreaterThanOrEqualToAnchor:cancelButton.bottomAnchor],
            [titleLabel.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
        ];

        [NSLayoutConstraint activateConstraints:_portraitConstraints];

        [NSLayoutConstraint activateConstraints:@[
            [cancelButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor],
            [cancelButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [cancelButton.widthAnchor constraintEqualToConstant:buttonSize],
            [cancelButton.heightAnchor constraintEqualToConstant:buttonSize],

            [planetaryView.centerXAnchor constraintEqualToAnchor:self.trailingAnchor
                                                        constant:planetOffest.x],
            [planetaryView.centerYAnchor constraintEqualToAnchor:self.topAnchor
                                                        constant:planetOffest.y],
            [planetaryView.widthAnchor constraintEqualToConstant:side],
            [planetaryView.heightAnchor constraintEqualToConstant:side],


            [self.layoutMarginsGuide.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],
            [self.bottomAnchor constraintEqualToAnchor:titleLabel.bottomAnchor
                                              constant:BottomSpacing()],
        ]];
    }
    return self;
}

- (void)setTitleBuilder:(DWTitleStringBuilder)titleBuilder {
    _titleBuilder = [titleBuilder copy];

    [self updateTitle];
}

- (void)configurePlanetsViewWithUsername:(NSString *)username {
    self.planetaryView.planets = Planets(username);
}

- (void)showInitialAnimation {
    [self.planetaryView showInitialAnimation];
}

- (void)setLandscapeMode:(BOOL)landscapeMode {
    _landscapeMode = landscapeMode;

    self.planetaryView.alpha = landscapeMode ? 0.0 : 1.0;
    if (landscapeMode) {
        [NSLayoutConstraint deactivateConstraints:self.portraitConstraints];
        [NSLayoutConstraint activateConstraints:self.landscapeConstraints];
    }
    else {
        [NSLayoutConstraint deactivateConstraints:self.landscapeConstraints];
        [NSLayoutConstraint activateConstraints:self.portraitConstraints];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    [self updateTitle];
}

#pragma mark - Private

- (void)updateTitle {
    if (self.titleBuilder) {
        self.titleLabel.attributedText = self.titleBuilder();
    }
    else {
        self.titleLabel.attributedText = nil;
    }
}

@end
