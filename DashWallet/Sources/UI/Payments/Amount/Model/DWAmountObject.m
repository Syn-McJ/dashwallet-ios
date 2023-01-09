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

#import "DWAmountObject.h"

#import <DashSync/DSCurrencyPriceObject.h>
#import <DashSync/DashSync.h>

#import "DWAmountInputValidator.h"
#import "UIColor+DWStyle.h"

NS_ASSUME_NONNULL_BEGIN

static CGSize const DashSymbolBigSize = {35.0, 27.0};
static CGSize const DashSymbolSmallSize = {14.0, 11.0};

typedef NS_ENUM(NSUInteger, DWAmountObjectInternalType) {
    DWAmountObjectInternalType_Dash,
    DWAmountObjectInternalType_Local,
};

@interface DWAmountObject ()

@property (readonly, assign, nonatomic) DWAmountObjectInternalType internalType;
@property (readonly, strong, nonatomic) NSNumberFormatter *localFormatter;
@property (nonatomic, copy) NSString *currencyCode;

@end

@implementation DWAmountObject

@synthesize dashAttributedString = _dashAttributedString;
@synthesize localCurrencyAttributedString = _localCurrencyAttributedString;

- (instancetype)initWithDashAmountString:(NSString *)dashAmountString
                          localFormatter:(NSNumberFormatter *)localFormatter
                            currencyCode:(NSString *)currencyCode {
    self = [super init];
    if (self) {
        _internalType = DWAmountObjectInternalType_Dash;
        _localFormatter = localFormatter;
        _currencyCode = currencyCode;

        _amountInternalRepresentation = [dashAmountString copy];

        if (dashAmountString.length == 0) {
            dashAmountString = @"0";
        }

        NSDecimalNumber *dashNumber = [NSDecimalNumber decimalNumberWithString:dashAmountString locale:[NSLocale currentLocale]];
        NSParameterAssert(dashNumber);
        NSDecimalNumber *duffsNumber = (NSDecimalNumber *)[NSDecimalNumber numberWithLongLong:DUFFS];
        int64_t plainAmount = [dashNumber decimalNumberByMultiplyingBy:duffsNumber].longLongValue;
        _plainAmount = plainAmount;

        DSPriceManager *priceManager = [DSPriceManager sharedInstance];
        NSString *dashFormatted = [priceManager.dashFormat stringFromNumber:dashNumber];
        _dashFormatted = dashFormatted;
        _dashFormatted = [self.class formattedAmountWithInputString:dashAmountString
                                                    formattedString:dashFormatted
                                                    numberFormatter:priceManager.dashFormat];
        NSNumber *localNum = [priceManager fiatCurrencyNumber:currencyCode forDashAmount:plainAmount];
        if (localNum == nil) {
            _localCurrencyFormatted = DSLocalizedString(@"Updating Price", @"Updating Price");
        }
        else {
            _localCurrencyFormatted = [localFormatter stringFromNumber:localNum];
        }

        [self reloadAttributedData];
    }
    return self;
}

- (nullable instancetype)initWithLocalAmountString:(NSString *)localAmountString
                                    localFormatter:(NSNumberFormatter *)localFormatter
                                      currencyCode:(NSString *)currencyCode {
    self = [super init];
    if (self) {
        _internalType = DWAmountObjectInternalType_Local;
        _localFormatter = localFormatter;
        _currencyCode = currencyCode;

        _amountInternalRepresentation = [localAmountString copy];

        if (localAmountString.length == 0) {
            localAmountString = @"0";
        }

        NSDecimalNumber *localNumber = [NSDecimalNumber decimalNumberWithString:localAmountString locale:[NSLocale currentLocale]];
        NSParameterAssert(localNumber);

        DSPriceManager *priceManager = [DSPriceManager sharedInstance];
        NSAssert(priceManager.localCurrencyDashPrice, @"Prices should be loaded");
        NSString *localCurrencyFormatted = [localFormatter stringFromNumber:localNumber];
        NSNumber *localPrice = [priceManager priceForCurrencyCode:currencyCode].price;
        uint64_t plainAmount = [priceManager amountForLocalCurrencyString:localCurrencyFormatted
                                                           localFormatter:localFormatter
                                                               localPrice:localPrice];
        if (plainAmount == 0 && ![localNumber isEqual:NSDecimalNumber.zero]) {
            return nil;
        }

        _plainAmount = plainAmount;
        _dashFormatted = [priceManager stringForDashAmount:plainAmount];
        _localCurrencyFormatted = [self.class formattedAmountWithInputString:localAmountString
                                                             formattedString:localCurrencyFormatted
                                                             numberFormatter:localFormatter];

        [self reloadAttributedData];
    }
    return self;
}

- (instancetype)initAsLocalWithPreviousAmount:(DWAmountObject *)previousAmount
                       localCurrencyValidator:(DWAmountInputValidator *)localCurrencyValidator
                               localFormatter:(NSNumberFormatter *)localFormatter
                                 currencyCode:(NSString *)currencyCode {
    self = [super init];
    if (self) {
        _internalType = DWAmountObjectInternalType_Local;
        _localFormatter = localFormatter;
        _currencyCode = currencyCode;

        DSPriceManager *priceManager = [DSPriceManager sharedInstance];
        _plainAmount = previousAmount.plainAmount;
        NSString *rawAmount = [self.class rawAmountStringFromFormattedString:previousAmount.localCurrencyFormatted
                                                             numberFormatter:localFormatter
                                                                   validator:localCurrencyValidator];
        NSParameterAssert(rawAmount);
        _amountInternalRepresentation = rawAmount;
        _dashFormatted = [previousAmount.dashFormatted copy];
        _localCurrencyFormatted = [previousAmount.localCurrencyFormatted copy];

        [self reloadAttributedData];
    }
    return self;
}

- (instancetype)initAsDashWithPreviousAmount:(DWAmountObject *)previousAmount
                               dashValidator:(DWAmountInputValidator *)dashValidator
                              localFormatter:(NSNumberFormatter *)localFormatter
                                currencyCode:(NSString *)currencyCode {
    self = [super init];
    if (self) {
        _internalType = DWAmountObjectInternalType_Dash;
        _localFormatter = localFormatter;
        _currencyCode = currencyCode;

        DSPriceManager *priceManager = [DSPriceManager sharedInstance];
        _plainAmount = previousAmount.plainAmount;
        NSString *rawAmount = [self.class rawAmountStringFromFormattedString:previousAmount.dashFormatted
                                                             numberFormatter:priceManager.dashFormat
                                                                   validator:dashValidator];
        NSParameterAssert(rawAmount);
        _amountInternalRepresentation = rawAmount;
        _dashFormatted = [previousAmount.dashFormatted copy];
        _localCurrencyFormatted = [previousAmount.localCurrencyFormatted copy];

        [self reloadAttributedData];
    }
    return self;
}

- (instancetype)initWithPlainAmount:(uint64_t)plainAmount
                     localFormatter:(NSNumberFormatter *)localFormatter
                       currencyCode:(NSString *)currencyCode {
    NSDecimalNumber *plainNumber = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedLongLong:plainAmount];
    NSDecimalNumber *duffsNumber = (NSDecimalNumber *)[NSDecimalNumber numberWithLongLong:DUFFS];
    NSDecimalNumber *dashNumber = [plainNumber decimalNumberByDividingBy:duffsNumber];
    NSString *dashAmountString = [dashNumber descriptionWithLocale:[NSLocale currentLocale]];

    return [self initWithDashAmountString:dashAmountString localFormatter:localFormatter currencyCode:currencyCode];
}

- (void)reloadAttributedData {
    NSParameterAssert(self.dashFormatted);
    NSParameterAssert(self.localCurrencyFormatted);

    const CGSize symbolSize = self.internalType == DWAmountObjectInternalType_Dash ? DashSymbolBigSize : DashSymbolSmallSize;
    UIColor *symbolTintColor = [UIColor dw_darkTitleColor];

    _dashAttributedString = [self.dashFormatted attributedStringForDashSymbolWithTintColor:symbolTintColor
                                                                            dashSymbolSize:symbolSize];
    _localCurrencyAttributedString = [self.class attributedStringForLocalCurrencyFormatted:self.localCurrencyFormatted];
}

+ (NSAttributedString *)attributedStringForLocalCurrencyFormatted:(NSString *)localCurrencyFormatted textColor:(UIColor *)textColor {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:localCurrencyFormatted];
    NSLocale *locale = [NSLocale currentLocale];
    NSString *decimalSeparator = locale.decimalSeparator;
    NSString *insufficientFractionDigits = [NSString stringWithFormat:@"%@00", decimalSeparator];
    NSRange insufficientFractionDigitsRange = [localCurrencyFormatted rangeOfString:insufficientFractionDigits];
    NSDictionary *defaultAttributes = @{NSForegroundColorAttributeName : textColor};
    [attributedString beginEditing];
    if (insufficientFractionDigitsRange.location != NSNotFound) {
        if (insufficientFractionDigitsRange.location > 0) {
            NSRange beforeFractionRange = NSMakeRange(0, insufficientFractionDigitsRange.location);
            [attributedString setAttributes:defaultAttributes range:beforeFractionRange];
        }
        [attributedString setAttributes:@{NSForegroundColorAttributeName : [textColor colorWithAlphaComponent:0.5]}
                                  range:insufficientFractionDigitsRange];
        NSUInteger afterFractionIndex = insufficientFractionDigitsRange.location + insufficientFractionDigitsRange.length;
        if (afterFractionIndex < localCurrencyFormatted.length) {
            NSRange afterFractionRange = NSMakeRange(afterFractionIndex, localCurrencyFormatted.length - afterFractionIndex);
            [attributedString setAttributes:defaultAttributes range:afterFractionRange];
        }
    }
    else {
        [attributedString setAttributes:defaultAttributes
                                  range:NSMakeRange(0, localCurrencyFormatted.length)];
    }
    [attributedString endEditing];

    return [attributedString copy];
}

#pragma mark - Private

+ (NSAttributedString *)attributedStringForLocalCurrencyFormatted:(NSString *)localCurrencyFormatted {
    return [self attributedStringForLocalCurrencyFormatted:localCurrencyFormatted textColor:[UIColor dw_darkTitleColor]];
}

+ (nullable NSString *)rawAmountStringFromFormattedString:(NSString *)formattedString
                                          numberFormatter:(NSNumberFormatter *)numberFormatter
                                                validator:(DWAmountInputValidator *)validator {
    NSLocale *locale = [NSLocale currentLocale];
    return [self rawAmountStringFromFormattedString:formattedString
                                    numberFormatter:numberFormatter
                                          validator:validator
                                             locale:locale];
}

+ (nullable NSString *)rawAmountStringFromFormattedString:(NSString *)formattedString
                                          numberFormatter:(NSNumberFormatter *)numberFormatter
                                                validator:(DWAmountInputValidator *)validator
                                                   locale:(NSLocale *)locale {
    NSNumber *number = [numberFormatter numberFromString:formattedString];
    NSParameterAssert(number);
    if (!number) {
        return nil;
    }

    NSString *result = [validator stringFromNumberUsingInternalFormatter:number];

    return result;
}

+ (NSString *)formattedAmountWithInputString:(NSString *)inputString
                             formattedString:(NSString *)formattedString
                             numberFormatter:(NSNumberFormatter *)numberFormatter {
    NSLocale *locale = [NSLocale currentLocale];
    return [self formattedAmountWithInputString:inputString
                                formattedString:formattedString
                                numberFormatter:numberFormatter
                                         locale:locale];
}

+ (NSString *)formattedAmountWithInputString:(NSString *)inputString
                             formattedString:(NSString *)formattedString
                             numberFormatter:(NSNumberFormatter *)numberFormatter
                                      locale:(NSLocale *)locale {
    NSAssert(numberFormatter.numberStyle == NSNumberFormatterCurrencyStyle, @"Invalid number formatter");

    NSString *decimalSeparator = locale.decimalSeparator;
    NSAssert([numberFormatter.decimalSeparator isEqualToString:decimalSeparator], @"Custom decimal separators are not supported");
    NSUInteger inputSeparatorIndex = [inputString rangeOfString:decimalSeparator].location;
    if (inputSeparatorIndex == NSNotFound) {
        return formattedString;
    }

    NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];

    NSString *currencySymbol = [self currencySymbolFromFormattedString:formattedString numberFormatter:numberFormatter];
    if (currencySymbol.length == 0) {
        // handle Dash number formatter as it has "DASH NARROW_NBSP" as currency symbol
        if ([numberFormatter.currencySymbol rangeOfString:DASH].location != NSNotFound) {
            currencySymbol = numberFormatter.currencySymbol;
        }
        else {
            // special case for countries with empty currency symbol (Cape Verde so far)
            return formattedString;
        }
    }

    NSRange currencySymbolRange = [formattedString rangeOfString:currencySymbol];
    NSAssert(currencySymbolRange.location != NSNotFound, @"Invalid formatted string");

    BOOL isCurrencySymbolAtTheBeginning = currencySymbolRange.location == 0;
    NSString *currencySymbolNumberSeparator = nil;
    if (isCurrencySymbolAtTheBeginning) {
        currencySymbolNumberSeparator = [formattedString substringWithRange:NSMakeRange(currencySymbolRange.length, 1)];
    }
    else {
        currencySymbolNumberSeparator = [formattedString substringWithRange:NSMakeRange(currencySymbolRange.location - 1, 1)];
    }
    if ([currencySymbolNumberSeparator rangeOfCharacterFromSet:whitespaceCharacterSet].location == NSNotFound) {
        currencySymbolNumberSeparator = @"";
    }

    NSString *formattedStringWithoutCurrency =
        [[formattedString stringByReplacingCharactersInRange:currencySymbolRange withString:@""]
            stringByTrimmingCharactersInSet:whitespaceCharacterSet];

    NSString *inputFractionPartWithSeparator = [inputString substringFromIndex:inputSeparatorIndex];
    NSUInteger formattedSeparatorIndex = [formattedStringWithoutCurrency rangeOfString:decimalSeparator].location;
    if (formattedSeparatorIndex == NSNotFound) {
        formattedSeparatorIndex = formattedStringWithoutCurrency.length;
        formattedStringWithoutCurrency = [formattedStringWithoutCurrency stringByAppendingString:decimalSeparator];
    }
    NSRange formattedFractionPartRange = NSMakeRange(formattedSeparatorIndex, formattedStringWithoutCurrency.length - formattedSeparatorIndex);

    NSString *formattedStringWithFractionInput = [formattedStringWithoutCurrency stringByReplacingCharactersInRange:formattedFractionPartRange withString:inputFractionPartWithSeparator];

    NSString *result = nil;
    if (isCurrencySymbolAtTheBeginning) {
        result = [NSString stringWithFormat:@"%@%@%@",
                                            currencySymbol,
                                            currencySymbolNumberSeparator,
                                            formattedStringWithFractionInput];
    }
    else {
        result = [NSString stringWithFormat:@"%@%@%@",
                                            formattedStringWithFractionInput,
                                            currencySymbolNumberSeparator,
                                            currencySymbol];
    }

    return result;
}

/**
 Extract currency symbol from string formatted by number formatter

 @discussion By default, `NSNumberFormatter` uses `[NSLocale currentLocale]` to determine `currencySymbol`.
 When we manually set `currencyCode`, `currencySymbol` is no longer valid.
 For instance, if user has *_RU locale: `numberFormatter.currencySymbol` is RUB but formatted string is "1.23 US$",
 because he selected US Dollars as local price. So we have to manually parse the correct currency symbol.
 */
+ (nullable NSString *)currencySymbolFromFormattedString:(NSString *)formattedString numberFormatter:(NSNumberFormatter *)numberFormatter {
    NSString *const CurrencySymbol = @"¤";

    NSString *format = numberFormatter.positiveFormat; // since we work only with positive numbers
    NSRange currencySymbolRange = [format rangeOfString:CurrencySymbol];
    NSAssert(currencySymbolRange.location != NSNotFound, @"Invalid formatted string");
    if (currencySymbolRange.location == NSNotFound) {
        return nil;
    }

    BOOL isCurrencySymbolAtTheBeginning = currencySymbolRange.location == 0;
    BOOL isCurrencySymbolAtTheEnd = (currencySymbolRange.location + currencySymbolRange.length) == format.length;

    if (!isCurrencySymbolAtTheBeginning && !isCurrencySymbolAtTheEnd) {
        // special case to deal with RTL languages
        if ([format hasPrefix:@"\U0000200e"] || [format hasPrefix:@"\U0000200f"]) {
            return numberFormatter.currencySymbol;
        }
    }

    NSMutableCharacterSet *digitAndWhitespaceSet = [NSMutableCharacterSet decimalDigitCharacterSet];
    [digitAndWhitespaceSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];

    NSArray<NSString *> *separatedString = [formattedString componentsSeparatedByCharactersInSet:digitAndWhitespaceSet];
    if (isCurrencySymbolAtTheBeginning) {
        return separatedString.firstObject;
    }
    else {
        return separatedString.lastObject;
    }
}

@end

NS_ASSUME_NONNULL_END
