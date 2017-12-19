#import "RLYButton.h"   // Header

@implementation RLYButton

#pragma mark - Public API

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (!_defaultBackgroundColor)   { _defaultBackgroundColor = self.backgroundColor;      }
    if (!_highlightBackgroundColor) { _highlightBackgroundColor = _defaultBackgroundColor; }
    if (!_selectedBackgroundColor)  { _selectedBackgroundColor = _defaultBackgroundColor;  }
    if (!_disabledBackgroundColor)  { _disabledBackgroundColor = _defaultBackgroundColor;  }
    [self setBackgroundColorDependingOnState];
}

- (CGSize)intrinsicContentSize
{
    CGSize result = [super intrinsicContentSize];
    result.width += 2.0f*_widthInset;
    result.height += 2.0f*_heightInset;
    return result;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setBackgroundColorDependingOnState];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self setBackgroundColorDependingOnState];
}

#pragma mark - Private functionality

- (void)setBackgroundColorDependingOnState
{
    self.backgroundColor =  (self.highlighted)  ? _highlightBackgroundColor :
                            (self.selected)     ? _selectedBackgroundColor  :
                            (!self.enabled)     ? _disabledBackgroundColor  :
                                                  _defaultBackgroundColor;
}

@end
