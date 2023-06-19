//
//  Created by Andrew Podkovyrin
//  Copyright © 2019 Dash Core Group. All rights reserved.
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

#import "DWModalPopupTransition.h"

#import "DWModalDismissalAnimation.h"
#import "DWModalInteractiveTransition.h"
#import "DWModalPopupPresentationController.h"
#import "DWModalPresentationAnimation.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWModalPopupTransition ()

@property (readonly, nonatomic, strong) DWModalInteractiveTransition *interactiveTransition;

@end

@implementation DWModalPopupTransition

- (instancetype)init {
    return [self initWithInteractiveTransitionAllowed:YES];
}

- (instancetype)initWithInteractiveTransitionAllowed:(BOOL)interactiveTransitionAllowed {
    self = [super init];
    if (self) {
        _interactiveTransition = [[DWModalInteractiveTransition alloc] init];
        _interactiveTransition.interactiveTransitionAllowed = interactiveTransitionAllowed;
    }
    return self;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (nullable id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [[DWModalPresentationAnimation alloc] initWithStyle:DWModalAnimationStyle_Fullscreen];
}

- (nullable id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return [[DWModalDismissalAnimation alloc] initWithStyle:DWModalAnimationStyle_Fullscreen];
}

- (nullable id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator {
    return self.interactiveTransition;
}

- (nullable id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    return self.interactiveTransition;
}

- (nullable UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(nullable UIViewController *)presenting sourceViewController:(UIViewController *)source {
    self.interactiveTransition.presentedController = (id)presented;

    DWModalPopupPresentationController *presentationController =
        [[DWModalPopupPresentationController alloc] initWithPresentedViewController:presented
                                                           presentingViewController:presenting];
    presentationController.interactiveTransition = self.interactiveTransition;
    presentationController.appearanceStyle = self.appearanceStyle;

    return presentationController;
}

@end

NS_ASSUME_NONNULL_END
