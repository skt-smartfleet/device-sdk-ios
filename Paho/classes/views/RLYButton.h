@import UIKit;      // Apple

/*!
 *  @abstract Custom button that you can set the inset and different state variables.
 */
IB_DESIGNABLE
@interface RLYButton : UIButton

/*!
 *  @abstract The height inset for the top and bottom of the button.
 */
@property (readonly,nonatomic) IBInspectable CGFloat heightInset;

/*!
 *  @abstract The width inset for the left and right side of the button.
 */
@property (readonly,nonatomic) IBInspectable CGFloat widthInset;

/*!
 *  @abstract The background color shown on the default state.
 */
@property (readonly,nonatomic) IBInspectable UIColor* defaultBackgroundColor;

/*!
 *  @abstract The background color shown on the highlighted state.
 */
@property (readonly,nonatomic) IBInspectable UIColor* highlightBackgroundColor;

/*!
 *  @abstract The background color shown on the selected state.
 */
@property (readonly,nonatomic) IBInspectable UIColor* selectedBackgroundColor;

/*!
 *  @abstract The background color shown on the disabled state.
 */
@property (readonly,nonatomic) IBInspectable UIColor* disabledBackgroundColor;

@end
