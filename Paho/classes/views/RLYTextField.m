#import "RLYTextField.h"

@implementation RLYTextField

#pragma mark - Public API

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectInset([super textRectForBounds:bounds], 2.0f*_widthInset, 0.0f);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectInset([super editingRectForBounds:bounds], 2.0f*_widthInset, 0.0f);
}

- (CGSize)intrinsicContentSize
{
    CGSize result = [super intrinsicContentSize];
    result.width += 2.0f*_widthInset;
    result.height += 2.0f*_heightInset;
    return result;
}

@end
