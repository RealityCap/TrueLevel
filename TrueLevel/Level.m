/*
 The MIT License (MIT)

 Copyright (c) 2013 RealityCap

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "Level.h"

enum GravityDirection {DirectionX, DirectionY, DirectionZ};

@implementation Level
{
    CMAcceleration acceleration;
    double radians;
}

// This factor corresponds to a low pass filter with a cutoff of approximately 5Hz for 100Hz input
#define FILTER_FACTOR 0.05

- (void) resetViews
{
    // Initialization code
    acceleration.x = 0;
    acceleration.y = 0;
    acceleration.z = 0;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self resetViews];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self resetViews];
    }
    return self;
}

/* Returns the dominant direction of the acceleration value, we assume gravity is this way */
- (enum GravityDirection) getCurrentDirection
{
    enum GravityDirection currentDirection = DirectionZ;

    if(fabs(acceleration.x) >= fabs(acceleration.y) && fabs(acceleration.x) >= fabs(acceleration.z))
        currentDirection = DirectionX;
    else if(fabs(acceleration.y) >= fabs(acceleration.x) && fabs(acceleration.y) >= fabs(acceleration.z))
        currentDirection = DirectionY;
    else if(fabs(acceleration.z) >= fabs(acceleration.x) && fabs(acceleration.z) >= fabs(acceleration.y))
        currentDirection = DirectionZ;
    else
        NSLog(@"This shouldn't happen");

    return currentDirection;
}

- (void) addAccelerometerValue:(CMAcceleration)value
{
    acceleration.x = acceleration.x * (1 - FILTER_FACTOR) + value.x * FILTER_FACTOR;
    acceleration.y = acceleration.y * (1 - FILTER_FACTOR) + value.y * FILTER_FACTOR;
    acceleration.z = acceleration.z * (1 - FILTER_FACTOR) + value.z * FILTER_FACTOR;

    enum GravityDirection closestAxis = [self getCurrentDirection];

    /* Provides the angle of the vector induced by gravity to the nearest axis by
       taking the dot product of the acceleration vector with the closest axis */
    double magnitude = sqrt(acceleration.x*acceleration.x + acceleration.y*acceleration.y + acceleration.z*acceleration.z);
    if(closestAxis == DirectionX)
        radians = acos(fabs(acceleration.x) / magnitude);
    else if(closestAxis == DirectionY)
        radians = acos(fabs(acceleration.y) / magnitude);
    else if(closestAxis == DirectionZ)
        radians = acos(fabs(acceleration.z) / magnitude);

    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	UIGraphicsPushContext(context);

    CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextFillRect(context, self.bounds);

    // Draw the text
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    UIFont * font = [UIFont systemFontOfSize:32.0];
    CGFloat fontHeight = font.pointSize;
    CGFloat yOffset = (self.bounds.size.height - fontHeight) / 2.0;
    CGRect textRect = CGRectMake(0, yOffset, self.bounds.size.width, fontHeight);

    NSString * label;
    label = [NSString stringWithFormat:@"%.0f\u00B0", radians*180/M_PI];

    [label drawInRect:textRect withFont:font lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentCenter];

    UIGraphicsPopContext();
}

@end
