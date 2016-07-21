//
//  BarCodeView.m
//  BarcodeEAN13GenDemo
//
//  Created by Strokin Alexey on 8/27/13.
//  Copyright (c) 2013 Strokin Alexey. All rights reserved.
//

#define kInvalidText @"Invalid barcode!"
#define kDigitLabelHeight 15.0f
#define kTotlaBarCodeLength 113

//static NSString *kInvalidText = @"Invalid barcode!";

//static const CGFloat kDigitLabelHeight = 15.0f;
//static const NSInteger kTotlaBarCodeLength = 113; //never change this


#import "BarCodeView.h"
#import "AppDelegate.h"
#import "BarCodeEAN13.h"

@interface BarCodeView ()
{
   CGFloat horizontalOffest;

	BOOL binaryCode[kTotlaBarCodeLength];
	BOOL validBarCode;
   
   UILabel *firstDigitLabel;
   UILabel *manufactureCodeLabel;
   UILabel *productCodeLabel;
   UILabel *checkSumLabel; // separate label because of sometime UI need it
}

-(BOOL)isValidBarCode:(NSString*)barCode;

-(void)createNumberLabels;

-(UILabel*)labelWithWidth:(CGFloat)aWidth andOffset:(CGFloat)offset
   andValue:(NSString*)aValue;

-(NSString*)firstDigitOfBarCode;
-(NSString*)manufactureCode;
-(NSString*)productCode;
-(NSString *)checkSum;

@end

@implementation BarCodeView

-(id)initWithFrame:(CGRect)frame
{
   NSAssert(frame.size.width >= kTotlaBarCodeLength, @"Incorrect BarCodeView frame.size.width!");
   self = [super initWithFrame:frame];
   if (self != nil)
   {
       [self commonInit];
   }
   return self;
}
-(void)awakeFromNib
{
    [super awakeFromNib];
    NSAssert(self.frame.size.width >= kTotlaBarCodeLength, @"Incorrect BarCodeView frame.size.width!");
    [self commonInit];
}
-(void)commonInit
{
    _bgColor = [UIColor whiteColor];
    _drawableColor = [UIColor blackColor];
    horizontalOffest = (self.frame.size.width-kTotlaBarCodeLength)/2;
    [self createNumberLabels];
}
-(void)setBarCode:(NSString *)newbarCode
{
   if (newbarCode != _barCode)
   {
      _barCode = newbarCode;
		validBarCode = [self isValidBarCode:_barCode];
      if (validBarCode)
      {
			CalculateBarCodeEAN13(_barCode, binaryCode);
         [self updateLables];
         [self setNeedsDisplay];
      }
   }
	if (!validBarCode)
	{
		memset(binaryCode, 0, sizeof(binaryCode));
      [self setNeedsDisplay];
	}
}
-(void)drawRect:(CGRect)rect
{
   CGContextRef c = UIGraphicsGetCurrentContext();
   CGContextClearRect(c, rect);
   if (!validBarCode)
   {
       //无效的条形码
//    draw error
      [_bgColor set];
      CGContextFillRect(c, rect);
 
      UIFont* font = [UIFont systemFontOfSize:15];
      UIColor* textColor = [UIColor clearColor];
   
      NSDictionary* stringAttrs = @{ NSFontAttributeName : font,
         NSForegroundColorAttributeName : textColor };
      NSAttributedString* attrStr = [[NSAttributedString alloc]
         initWithString:kInvalidText attributes:stringAttrs];

      [attrStr drawAtPoint:CGPointMake(3.f, rect.size.height/2-15/2)];
      return;
   }
//   draw barcode
	CGContextBeginPath(c);
	for (int i = 0; i < kTotlaBarCodeLength; i++)
	{
   
      [binaryCode[i] ? _drawableColor : _bgColor set];
		CGContextMoveToPoint(c, i+horizontalOffest, 0.0f);
		CGContextAddLineToPoint(c, i+horizontalOffest, self.bounds.size.height);
		CGContextStrokePath(c);
	}
//   stroke the last line
   [_bgColor set];
   CGContextMoveToPoint(c, kTotlaBarCodeLength, 0.0f);
   CGContextAddLineToPoint(c, kTotlaBarCodeLength, self.bounds.size.height);
   CGContextStrokePath(c);
}
-(BOOL)isValidBarCode:(NSString*)barCode
{
    
   BOOL valid = NO;
   NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
   NSCharacterSet *inStringSet = [NSCharacterSet
		characterSetWithCharactersInString:barCode];
   if ([alphaNums isSupersetOfSet:inStringSet] && barCode.length == 13)
   {
//      checksum validation
      int sum = 0;
      for (int i = 0; i < 12; i++)
      {
         int m = (i % 2) == 1 ? 3 : 1;
         int value = [barCode characterAtIndex:i] - 0x30;
         sum += (m*value);
      }
      int cs = 10 - (sum % 10);
      if (cs == 10) cs = 0;
      valid = (cs == ([barCode characterAtIndex:12] - 0x30));
      if (!valid) NSLog(@"%@",kInvalidText);
   }
    
    if (!valid) {
        [self setHidden:YES];
    }
    else
    {
       [self setHidden:NO];
    }
   return valid;
}

-(void)updateLables
{
   firstDigitLabel.text = [self firstDigitOfBarCode];
   manufactureCodeLabel.text = [self manufactureCode];
   productCodeLabel.text = [self productCode];
   checkSumLabel.text = [self checkSum];
}

-(void)createNumberLabels
{
// smoke UI label for better visability
   CGFloat smokeHeight = 6.0f;
   UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(horizontalOffest, self.bounds.size.height-smokeHeight, kTotlaBarCodeLength-1, smokeHeight)];
   l.backgroundColor = _bgColor;
   [self addSubview:l];
//   
   CGFloat offset = horizontalOffest;
   CGFloat labelWidth = 7.0f;
   firstDigitLabel = [self labelWithWidth:labelWidth andOffset:offset andValue:[self firstDigitOfBarCode]];
   [self addSubview:firstDigitLabel];
   offset += 12;
   manufactureCodeLabel = [self labelWithWidth:labelWidth*6 andOffset:offset andValue:[self manufactureCode]];
   [self addSubview:manufactureCodeLabel];
   offset += 46;
   productCodeLabel = [self labelWithWidth:labelWidth*5 andOffset:offset andValue:[self productCode]];
   productCodeLabel.textAlignment = NSTextAlignmentRight;
   [self addSubview:productCodeLabel];
   offset += 35;
   checkSumLabel = [self labelWithWidth:labelWidth andOffset:offset andValue:[self checkSum]];
   [self addSubview:checkSumLabel];
}
-(UILabel*)labelWithWidth:(CGFloat)aWidth andOffset:(CGFloat)offset
   andValue:(NSString*)aValue
{
   UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(offset,
      self.bounds.size.height - kDigitLabelHeight, aWidth, kDigitLabelHeight)];
   label.backgroundColor = _bgColor;
   label.textColor = _drawableColor;
   label.textAlignment = NSTextAlignmentCenter;
   label.font = [UIFont boldSystemFontOfSize:kDigitLabelHeight-4];
   label.text = aValue;
   return label;
}
-(NSString*)firstDigitOfBarCode
{
   return [self.barCode substringToIndex:1];
}
-(NSString*)manufactureCode
{
   return [self.barCode substringWithRange:NSMakeRange(1, 6)];
}
-(NSString*)productCode
{
   return [self.barCode substringWithRange:NSMakeRange(7, 5)];
}
- (NSString *)checkSum
{
   return [_barCode substringWithRange:NSMakeRange(12, 1)];
}
-(void)setShouldShowNumbers:(BOOL)shouldShowNumbers
{
   for (UILabel *label in self.subviews)
   {
      if ([label isKindOfClass:[UILabel class]]) label.hidden = !shouldShowNumbers;
   }
}
@end
