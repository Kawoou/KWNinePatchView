/*
 The MIT License (MIT)
 
 KWNinePatchView - Copyright (c) 2013, Jeungwon An (kawoou@kawoou.kr)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

#import "KWNinePatchView.h"

typedef NS_ENUM(NSUInteger, KWNinePatchViewCroppedImage)
{
    KWNinePatchViewCroppedImageDefault = 0,
    KWNinePatchViewCroppedImageHighlight,
    KWNinePatchViewCroppedImageCount
};

@interface KWNinePatchView()
{
    UILabel     *_textLabel;
    UIButton    *_clearButton;
    
    UIImage     *_original[KWNinePatchViewCroppedImageCount];
    
    UIImage     *_cornerImage[KWNinePatchViewCroppedImageCount][9];
    CGRect      _cornerRect[KWNinePatchViewCroppedImageCount][10];
    CGRect      _renderRect[KWNinePatchViewCroppedImageCount][10];
    
    KWNinePatchViewCroppedImage _currentState;
}

- (void)initialize;
- (void)buttonHighlight:(UIButton *)button;
- (void)buttonUnhighlight:(UIButton *)button;

- (void)calculateRenderRect;
- (void)createNinePatchWithImage:(UIImage *)image
                    croppedIndex:(KWNinePatchViewCroppedImage)index;

- (UIImage *)cropImage:(UIImage *)image andFrame:(CGRect)frame;
- (bool)isTransparentAtPoint:(NSUInteger)point rawData:(unsigned char *)rawData;
- (NSRange)findNinePatchLineWithCount:(NSUInteger)count
                              rawData:(unsigned char *)rawData
                            algorithm:(NSUInteger (^)(NSUInteger))algorithm;
@end

@implementation KWNinePatchView

#pragma mark - Properties
- (void)setImage:(UIImage *)image
{
    if(!image) return;
    
    _original[KWNinePatchViewCroppedImageDefault] = image;
    [self createNinePatchWithImage:image
                      croppedIndex:KWNinePatchViewCroppedImageDefault];
}

- (void)setHighlightImage:(UIImage *)highlightImage
{
    if(!highlightImage) return;
    
    _original[KWNinePatchViewCroppedImageHighlight] = highlightImage;
    [self createNinePatchWithImage:highlightImage
                      croppedIndex:KWNinePatchViewCroppedImageHighlight];
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    _textLabel.font = font;
}

- (void)setText:(NSString *)text
{
    _text = text;
    _textLabel.text = text;
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    _textLabel.textColor = textColor;
}

- (void)setTextAlignment:(UITextAlignment)textAlignment
{
    _textAlignment = textAlignment;
    _textLabel.textAlignment = textAlignment;
}

#pragma mark - Creation
- (id)init
{
    self = [self initWithImage:nil];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [self initWithImage:nil andFrame:frame];
    return self;
}

- (id)initWithImage:(UIImage *)image
{
    self = [self initWithImage:image highlightImage:nil];
    return self;
}

- (id)initWithImage:(UIImage *)image andFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initialize];
        
        [self setImage:image];
        [self setHighlightImage:nil];
        
        [self setFrame:frame];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image highlightImage:(UIImage *)highlightImage
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        [self initialize];
        
        [self setImage:image];
        [self setHighlightImage:highlightImage];
        
        [self setFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    }
    return self;
}

#pragma mark - Override methods
- (void)setFrame:(CGRect)frame
{
    if(_original[_currentState])
    {
        CGSize size = _original[_currentState].size;
        
        if(frame.size.width < size.width - 2)
            frame.size.width = size.width - 2;
        if(frame.size.height < size.height - 2)
            frame.size.height = size.height - 2;
    }
    [super setFrame:frame];
    [_clearButton setFrame:frame];
    
    [self calculateRenderRect];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    NSUInteger i;
    if(!_original[_currentState]) return;
    
    for(i = 0; i < 9; i ++)
    {
        [_cornerImage[_currentState][i] drawInRect:CGRectMake
         (_renderRect[_currentState][i].origin.x,
          _renderRect[_currentState][i].origin.y,
          _renderRect[_currentState][i].size.width,
          _renderRect[_currentState][i].size.height)];
    }
    
    [_textLabel setBounds:_renderRect[_currentState][9]];
    [_textLabel drawRect:_renderRect[_currentState][9]];
}

#pragma mark - Private methods
- (void)initialize
{
    NSUInteger i, j;
    
    [self setBackgroundColor:[UIColor clearColor]];
    
    _textLabel = [[UILabel alloc] init];
    [_textLabel setText:@""];
    [_textLabel setTextColor:[UIColor whiteColor] ];
    [_textLabel setTextAlignment:NSTextAlignmentCenter];
    
    _clearButton = [[UIButton alloc] init];
    [_clearButton setBackgroundColor:[UIColor clearColor]];
    [_clearButton addTarget:self action:@selector(buttonHighlight:)
           forControlEvents:UIControlEventTouchDown];
    [_clearButton addTarget:self action:@selector(buttonHighlight:)
           forControlEvents:UIControlEventTouchDragInside];
    [_clearButton addTarget:self action:@selector(buttonUnhighlight:)
           forControlEvents:UIControlEventTouchUpInside];
    [_clearButton addTarget:self action:@selector(buttonUnhighlight:)
           forControlEvents:UIControlEventTouchUpOutside];
    [_clearButton addTarget:self action:@selector(buttonUnhighlight:)
           forControlEvents:UIControlEventTouchDragOutside];
    [_clearButton addTarget:self action:@selector(buttonUnhighlight:)
           forControlEvents:UIControlEventTouchCancel];
    [self addSubview:_clearButton];
    
    _currentState = KWNinePatchViewCroppedImageDefault;
    for(i = 0; i < KWNinePatchViewCroppedImageCount; i ++)
    {
        _original[i] = nil;
        for(j = 0; j < 9; j ++)
        {
            _cornerImage[i][j] = nil;
            _cornerRect[i][j] = CGRectZero;
            _renderRect[i][j] = CGRectZero;
        }
    }
}

- (void)buttonHighlight:(UIButton *)button
{
    KWNinePatchViewCroppedImage state = _currentState;
    if(_original[KWNinePatchViewCroppedImageHighlight])
        _currentState = KWNinePatchViewCroppedImageHighlight;
    else
        _currentState = KWNinePatchViewCroppedImageDefault;
    
    if(state != _currentState)
    {
        [self calculateRenderRect];
        [self setNeedsDisplay];
    }
}

- (void)buttonUnhighlight:(UIButton *)button
{
    KWNinePatchViewCroppedImage state = _currentState;
    _currentState = KWNinePatchViewCroppedImageDefault;
    
    if(state != _currentState)
    {
        [self calculateRenderRect];
        [self setNeedsDisplay];
    }
}

- (void)calculateRenderRect
{
    // Calculate rect for rendering
    NSUInteger index, i;
    CGSize fs = CGSizeMake([super frame].size.width + 2,
                           [super frame].size.height + 2);
    
    for(index = 0; index < KWNinePatchViewCroppedImageCount; index ++)
    {
        if(!_original[index]) break;
        
        CGSize size = _original[index].size;
        for(i = 0; i < 3; i ++)
        {
            NSUInteger j = i * 3;
            NSUInteger yValue = _cornerRect[index][j+0].origin.y+
                                (i>1?fs.height-size.height-2:0);
            NSUInteger hValue = _cornerRect[index][j+0].size.height+
                                (i%2?fs.height-size.height-2:0);
            
            
            _renderRect[index][j + 0] = CGRectMake
            (
             _cornerRect[index][j + 0].origin.x,
             yValue,
             _cornerRect[index][j + 0].size.width,
             hValue
            );
            
            _renderRect[index][j + 1] = CGRectMake
            (
             _cornerRect[index][j + 1].origin.x,
             yValue,
             _cornerRect[index][j + 1].size.width+fs.width-size.width-2,
             hValue
            );
            _renderRect[index][j + 2] = CGRectMake
            (
             _cornerRect[index][j + 2].origin.x+fs.width-size.width-2,
             yValue,
             _cornerRect[index][j + 2].size.width,
             hValue
            );
        }
        _renderRect[index][9] = CGRectMake
        (
         _cornerRect[index][9].origin.x - 1.0,
         _cornerRect[index][9].origin.y - 1.0,
         _cornerRect[index][9].size.width + fs.width - size.width,
         _cornerRect[index][9].size.height + fs.height - size.height
        );
    }
}

- (void)createNinePatchWithImage:(UIImage *)image
                    croppedIndex:(KWNinePatchViewCroppedImage)index
{
    unsigned char *rawData;
    NSUInteger bytesPerRow;
    
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bitsPerComponent = 8;
    
    // Get the raw data in image
    rawData = (unsigned char*)calloc(height * width * 4, sizeof(unsigned char));
    bytesPerRow = bytesPerPixel * width;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast|
                                                 kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // to find, size information
    NSRange topRange, bottomRange, leftRange, rightRange;
    
    topRange = [self findNinePatchLineWithCount:width
                                        rawData:rawData
                                      algorithm:^NSUInteger (NSUInteger i) {
                                          return i*4;
                                      }];
    bottomRange = [self findNinePatchLineWithCount:width
                                        rawData:rawData
                                      algorithm:^NSUInteger (NSUInteger i) {
                                          return bytesPerRow*(height-1)+i*4;
                                      }];
    
    leftRange = [self findNinePatchLineWithCount:height
                                        rawData:rawData
                                      algorithm:^NSUInteger (NSUInteger i) {
                                          return bytesPerRow*i;
                                      }];
    rightRange = [self findNinePatchLineWithCount:height
                                        rawData:rawData
                                      algorithm:^NSUInteger (NSUInteger i) {
                                          return bytesPerRow*i+(width-1)*4;
                                      }];
    UIGraphicsEndImageContext();
    
    // Cropping
    NSUInteger i, j;
    for(i = 0; i < 3; i ++)
    {
        for(j = 0; j < 3; j ++)
        {
            // j(x) : 1.0, topRange.location, LastInRange(topRange)
            // i(y) : 1.0, leftRange.location, LastInRange(leftRange)
            // j(w) : topRange.location, topRange.length, width-LastInRange(topRange)-1
            // i(h) : leftRange.location, leftRange.length, height-LastInRange(leftRange)-1
            
            CGRect rect = CGRectMake
            (
             (!j?1:topRange.location)+(topRange.length+1)*(j>1),
             (!i?1:leftRange.location)+(leftRange.length+1)*(i>1),
             ((width-1)*(j>1)+(topRange.location*(!(j%2))+(j%2)+
                           topRange.length*(j>0))*(j>1?-1:1))-(!(j%2)),
             ((height-1)*(i>1)+(leftRange.location*(!(i%2))+(i%2)+
                            leftRange.length*(i>0))*(i>1?-1:1))-(!(i%2))
            );
            _cornerRect[index][i*3+j] = CGRectMake
            (
             rect.origin.x * 0.5 - 1,
             rect.origin.y * 0.5 - 1,
             rect.size.width * 0.5,
             rect.size.height * 0.5
            );
            
            _cornerImage[index][i*3+j] = [self cropImage:image andFrame:rect];
        }
    }
    
    _cornerRect[index][9] = CGRectMake
    (
     bottomRange.location * 0.5,
     rightRange.location * 0.5,
     bottomRange.length * 0.5,
     rightRange.length * 0.5
    );
    [self calculateRenderRect];
    
    // Release
    free(rawData);
}

- (UIImage *)cropImage:(UIImage *)image andFrame:(CGRect)frame
{
    UIImage *newImage;
    CGImageRef renderBoard;
    
    renderBoard = CGImageCreateWithImageInRect([image CGImage], frame);
    newImage = [UIImage imageWithCGImage:renderBoard
                                   scale:image.scale
                             orientation:UIImageOrientationUp];
    CGImageRelease(renderBoard);
    
    return newImage;
}

- (bool)isTransparentAtPoint:(NSUInteger)point rawData:(unsigned char *)rawData
{
    int byteIndex = point;
    int red = rawData[byteIndex];
    int green = rawData[byteIndex + 1];
    int blue = rawData[byteIndex + 2];
    int alpha = rawData[byteIndex + 3];
    
    if(red == 0 && green == 0 && blue == 0 && alpha != 0)
        return NO;
    else
        return YES;
}

- (NSRange)findNinePatchLineWithCount:(NSUInteger)count
                              rawData:(unsigned char *)rawData
                            algorithm:(NSUInteger (^)(NSUInteger))algorithm
{
    NSUInteger i;
    NSRange range = {.location=0,.length=0};
    
    for(i = 0; i < count; i ++)
    {
        if(![self isTransparentAtPoint:algorithm(i) rawData:rawData])
        {
            range.location = i;
            break;
        }
    }
    for(i = range.location; i < count; i ++)
    {
        if([self isTransparentAtPoint:algorithm(i) rawData:rawData])
        {
            range.length = i - range.location - 1;
            break;
        }
    }
    return range;
}

@end


































