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

#import "DWRecoverContentView.h"

#import <DashSync/DashSync.h>

#import "DWRecoverModel.h"
#import "DWRecoverTextView.h"
#import "DWSeedUIConstants.h"
#import "DWUIKit.h"
#import "dashwallet-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWRecoverContentView () <UITextViewDelegate>

@property (readonly, nonatomic, strong) UILabel *titleLabel;
@property (readonly, nonatomic, strong) DWRecoverTextView *textView;

@property (readonly, nonatomic, strong) NSLayoutConstraint *topConstraint;
@property (readonly, nonatomic, strong) NSLayoutConstraint *textViewMinHeightConstraint;

@end

@implementation DWRecoverContentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor dw_secondaryBackgroundColor];

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.backgroundColor = self.backgroundColor;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont dw_fontForTextStyle:UIFontTextStyleTitle2];
        titleLabel.textColor = [UIColor dw_darkTitleColor];
        titleLabel.adjustsFontForContentSizeCategory = YES;
        titleLabel.numberOfLines = 0;
        [self addSubview:titleLabel];
        _titleLabel = titleLabel;

        DWRecoverTextView *textView = [[DWRecoverTextView alloc] initWithFrame:CGRectZero];
        textView.translatesAutoresizingMaskIntoConstraints = NO;
        textView.delegate = self;
        [self addSubview:textView];
        _textView = textView;

        UIView *dummyView = [[UIView alloc] initWithFrame:CGRectZero];
        dummyView.translatesAutoresizingMaskIntoConstraints = NO;
        dummyView.backgroundColor = self.backgroundColor;
        [self addSubview:dummyView];

        [titleLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                      forAxis:UILayoutConstraintAxisVertical];
        [textView setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                  forAxis:UILayoutConstraintAxisVertical];

        _topConstraint = [titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor
                                                              constant:DW_TOP_COMPACT_PADDING];
        _textViewMinHeightConstraint = [textView.heightAnchor constraintGreaterThanOrEqualToConstant:0.0];

        [NSLayoutConstraint activateConstraints:@[
            _topConstraint,
            [titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],

            [textView.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor
                                               constant:DWTitleSeedPhrasePadding()],
            [textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            _textViewMinHeightConstraint,

            [dummyView.topAnchor constraintEqualToAnchor:textView.bottomAnchor],
            [dummyView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [dummyView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [dummyView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        ]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (!CGSizeEqualToSize(self.bounds.size, [self intrinsicContentSize])) {
        [self invalidateIntrinsicContentSize];
    }
}

- (CGSize)intrinsicContentSize {
    const CGFloat height = self.topConstraint.constant +
                           [self minimumContentHeightWithoutTopPadding];

    return CGSizeMake(self.visibleSize.width, MAX(height, self.visibleSize.height));
}

- (void)setVisibleSize:(CGSize)visibleSize {
    _visibleSize = visibleSize;

    self.textViewMinHeightConstraint.constant = [self.textView minimumHeight];

    [self setNeedsLayout];
}

- (nullable NSString *)title {
    return self.titleLabel.text;
}

- (void)setTitle:(nullable NSString *)title {
    self.titleLabel.text = title;
}

- (void)activateTextView {
    [self.textView becomeFirstResponder];
}

- (void)continueAction {
    [self recoverWalletWithCurrentSeedPhrase];
}

- (void)appendText:(NSString *)text {
    self.textView.text = [self.textView.text stringByAppendingFormat:@" %@", text];
}

- (void)replaceText:(NSString *)target replacement:(NSString *)replacement {
    self.textView.text = [self.textView.text stringByReplacingOccurrencesOfString:target
                                                                       withString:replacement
                                                                          options:NSCaseInsensitiveSearch
                                                                            range:NSMakeRange(0, self.textView.text.length)];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self.delegate recoverContentView:self phraseDidChange:textView.text];
}

- (BOOL)textView:(UITextView *)textView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text {
    if ([text isEqual:@"\n"]) {
        [self recoverWalletWithCurrentSeedPhrase];
        return NO;
    }
    else {
        return YES;
    }
}

#pragma mark - Private

- (void)recoverWalletWithCurrentSeedPhrase {
    NSUInteger count = [self.textView.text wordsCount];
    if (count < 10) { return; }
    
    @autoreleasepool { // @autoreleasepool ensures sensitive data will be deallocated immediately
        UITextView *textView = self.textView;
        NSString *phrase = textView.text;

        NSString *incorrectWord = nil;
        uint32_t incorrectWordCount = 0;

        if (![phrase isEqualToString:DW_WIPE_STRONG]) {
            phrase = [self.model cleanupPhrase:phrase];


            if (![textView.text hasPrefix:DW_WATCH] && ![phrase isEqual:textView.text]) {
                textView.text = phrase;
            }
            phrase = [self.model normalizePhrase:phrase];
        }

        NSArray<NSString *> *words = CFBridgingRelease(
            CFStringCreateArrayBySeparatingStrings(
                SecureAllocator(), (CFStringRef)phrase,
                CFSTR(" ")));

        for (NSString *word in words) {
            if (![[DSBIP39Mnemonic sharedInstance] wordIsValid:word]) {
                if (incorrectWord == nil) {
                    incorrectWord = word;
                }
                incorrectWordCount++;
            }
        }

        if ([phrase isEqualToString:DW_WIPE] || [phrase isEqualToString:DW_WIPE_STRONG] ||
            [[phrase lowercaseString] isEqualToString:[self.model.wipeAcceptPhrase lowercaseString]]) {
            [self wipeWithPhrase:phrase];
        }
        else if (incorrectWord && incorrectWordCount > 1) {
            textView.selectedRange = [textView.text.lowercaseString rangeOfString:incorrectWord];
            [self.delegate recoverContentView:self showIncorrectWord:incorrectWord];
        }
        else if (incorrectWord && incorrectWordCount == 1 && self.model.action == DWRecoverAction_Recover) {
            [self.delegate recoverContentView:self offerToReplaceIncorrectWord:incorrectWord inPhrase:phrase];
        }
        else if (self.model.action == DWRecoverAction_Recover && (words.count < DW_PHRASE_MIN_LENGTH || words.count % DW_PHRASE_MULTIPLE)) {
            [self.delegate recoverContentView:self usedWordsHaveInvalidCount:words];
        }
        else if (![self.model phraseIsValid:phrase]) {
            [self.delegate recoverContentViewBadRecoveryPhrase:self];
        }
        else if ([self.model hasWallet]) {
            [self wipeWithPhrase:phrase];
        }
        else {
            if (self.model.action == DWRecoverAction_Recover) {
                [self.delegate recoverContentViewDidRecoverWallet:self phrase:phrase];
            }
            else {
                [self wipeWithPhrase:phrase];
            }
        }
    }
}

- (void)wipeWithPhrase:(NSString *)phrase {
    @autoreleasepool {
        if ([phrase isEqualToString:DW_WIPE]) {
            if ([self.model isWalletEmpty]) {
                [self.delegate recoverContentViewPerformWipe:self];
            }
            else {
                [self.delegate recoverContentViewWipeNotAllowed:self];
            }
        }
        else if ([phrase isEqualToString:DW_WIPE_STRONG] || [phrase.lowercaseString isEqualToString:self.model.wipeAcceptPhrase.lowercaseString]) {
            [self.delegate recoverContentViewPerformWipe:self];
        }
        else {
            if ([self.model canWipeWithPhrase:phrase]) {
                [self.delegate recoverContentViewPerformWipe:self];
            }
            else if (phrase) {
                [self.delegate recoverContentViewWipeNotAllowedPhraseMismatch:self];
            }
        }
    }
}

- (CGFloat)minimumContentHeightWithoutTopPadding {
    const CGFloat textViewMinimumHeight = self.textViewMinHeightConstraint.constant;
    const CGFloat textViewHeight = self.textView.intrinsicContentSize.height;

    const CGFloat height = self.titleLabel.intrinsicContentSize.height +
                           DWTitleSeedPhrasePadding() +
                           MAX(textViewMinimumHeight, textViewHeight) +
                           DW_BOTTOM_PADDING;

    return height;
}

@end

NS_ASSUME_NONNULL_END
