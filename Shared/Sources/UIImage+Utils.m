//
//  UIImage+Utils.m
//  DashWallet
//
//  Created by Aaron Voisine for BreadWallet on 11/8/14.
//  Copyright (c) 2014 Aaron Voisine <voisine@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "UIImage+Utils.h"
#import <Accelerate/Accelerate.h>

@implementation UIImage (Utils)

+ (instancetype)dw_imageWithQRCodeData:(NSData *)data color:(CIColor *)color {
    UIImage *image;
    CGImageRef cgImg;
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"],
             *maskFilter = [CIFilter filterWithName:@"CIMaskToAlpha"],
             *invertFilter = [CIFilter filterWithName:@"CIColorInvert"],
             *colorFilter = [CIFilter filterWithName:@"CIFalseColor"],
             *filter = colorFilter;

    [qrFilter setValue:data forKey:@"inputMessage"];
    [qrFilter setValue:@"Q" forKey:@"inputCorrectionLevel"];

    if (color.alpha > DBL_EPSILON) {
        [invertFilter setValue:qrFilter.outputImage forKey:@"inputImage"];
        [maskFilter setValue:invertFilter.outputImage forKey:@"inputImage"];
        [invertFilter setValue:maskFilter.outputImage forKey:@"inputImage"];
        [colorFilter setValue:invertFilter.outputImage forKey:@"inputImage"];
        [colorFilter setValue:color forKey:@"inputColor0"];
    }
    else {
        [maskFilter setValue:qrFilter.outputImage forKey:@"inputImage"];
        filter = maskFilter;
    }

    @synchronized([CIContext class]) {
        // force software rendering for security (GPU rendering causes image artifacts on iOS 7 and is generally crashy)
        CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)}];

        if (!context) {
            context = [CIContext context];
        }
        cgImg = [context createCGImage:filter.outputImage fromRect:filter.outputImage.extent];
    }

    image = [UIImage imageWithCGImage:cgImg];
    CGImageRelease(cgImg);
    return image;
}

- (UIImage *)dw_resize:(CGSize)size withInterpolationQuality:(CGInterpolationQuality)quality {
    UIGraphicsBeginImageContext(size);

    CGContextRef context = UIGraphicsGetCurrentContext();
    UIImage *image = nil;

    if (context) {
        CGContextSetInterpolationQuality(context, quality);
        CGContextRotateCTM(context, M_PI);     // flip
        CGContextScaleCTM(context, -1.0, 1.0); // mirror
        CGContextDrawImage(context, CGContextGetClipBoundingBox(context), self.CGImage);
        image = UIGraphicsGetImageFromCurrentImageContext();
    }

    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)dw_blurWithRadius:(CGFloat)radius {
    UIGraphicsBeginImageContext(self.size);

    CGContextRef context = UIGraphicsGetCurrentContext();
    uint32_t r = floor(radius * [UIScreen mainScreen].scale * 3.0 * sqrt(2.0 * M_PI) / 4.0 + 0.5);
    CGRect rect = {CGPointZero, self.size};
    vImage_Buffer inbuf, outbuf;
    UIImage *image = NULL;

    if (context) {
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextTranslateCTM(context, 0.0, -self.size.height);
        CGContextDrawImage(context, rect, self.CGImage);

        inbuf = (vImage_Buffer){
            CGBitmapContextGetData(context),
            CGBitmapContextGetHeight(context),
            CGBitmapContextGetWidth(context),
            CGBitmapContextGetBytesPerRow(context)};

        UIGraphicsBeginImageContext(self.size);
        context = UIGraphicsGetCurrentContext();
    }

    if (context) {
        outbuf = (vImage_Buffer){
            CGBitmapContextGetData(context),
            CGBitmapContextGetHeight(context),
            CGBitmapContextGetWidth(context),
            CGBitmapContextGetBytesPerRow(context)};

        if (r % 2 == 0) {
            r++; // make sure radius is odd for three box-blur method
        }
        vImageBoxConvolve_ARGB8888(&inbuf, &outbuf, NULL, 0, 0, r, r, 0, kvImageEdgeExtend);
        vImageBoxConvolve_ARGB8888(&outbuf, &inbuf, NULL, 0, 0, r, r, 0, kvImageEdgeExtend);
        vImageBoxConvolve_ARGB8888(&inbuf, &outbuf, NULL, 0, 0, r, r, 0, kvImageEdgeExtend);

        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        UIGraphicsBeginImageContext(self.size);
        context = UIGraphicsGetCurrentContext();
    }

    if (context) {
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextTranslateCTM(context, 0.0, -self.size.height);
        CGContextDrawImage(context, rect, self.CGImage); // draw base image
        CGContextSaveGState(context);
        CGContextDrawImage(context, rect, image.CGImage); // draw effect image
        CGContextRestoreGState(context);
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    return image;
}

- (UIImage *)dw_imageByMergingWithImage:(UIImage *)secondImage {
    CGRect r = CGRectMake(roundf((self.size.width - secondImage.size.width) / 2.0),
                          roundf((self.size.height - secondImage.size.height) / 2.0),
                          secondImage.size.width,
                          secondImage.size.height);

    return [self dw_imageByMergingWithImage:secondImage secondImageRect:r];
}

- (UIImage *)dw_imageByMergingWithImage:(UIImage *)secondImage secondImageRect:(CGRect)secondImageRect {
    UIImage *firstImage = self;
    CGSize imageSize = self.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, [UIScreen mainScreen].scale);
    [firstImage drawAtPoint:CGPointMake(roundf((imageSize.width - firstImage.size.width) / 2.0),
                                        roundf((imageSize.height - firstImage.size.height) / 2.0))];
    [secondImage drawInRect:secondImageRect];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return result;
}

- (UIImage *)dw_imageByCuttingHoleInCenterWithSize:(CGSize)holeSize {
    CGSize size = self.size;
    CGFloat radius = ceil(holeSize.width / 2.0);
    CGPoint centerPoint = CGPointMake(ceil(size.width / 2.0), ceil(size.height / 2.0));

    UIBezierPath *currentPath = [UIBezierPath bezierPath];
    [currentPath addArcWithCenter:centerPoint radius:radius startAngle:0.0 endAngle:2.0 * M_PI clockwise:YES];
    [currentPath closePath];

    UIGraphicsBeginImageContext(size);
    [self drawAtPoint:CGPointZero];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddPath(context, currentPath.CGPath);
    CGContextClip(context);
    CGContextClearRect(context, CGRectMake(0.0, 0.0, size.width, size.height));

    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return result;
}

@end
