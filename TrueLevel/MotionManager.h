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

#import <CoreMotion/CoreMotion.h>

/** Handles getting IMU data from the system.
 */
@protocol MotionDelegate <NSObject>

@optional
-(void) receiveGyroData:(CMGyroData *)gyroData;
-(void) receiveAccelerometerData:(CMAccelerometerData *)accelerometerData;

@end

@protocol StaticCalibrationDelegate <NSObject>

-(void) staticCalibrationDidFinish;
@optional
-(void) staticCalibrationProgress:(float)progress;

@end

@interface MotionManager : NSObject

@property CMMotionManager* cmMotionManager;
@property (weak) id<MotionDelegate> delegate;
@property (weak) id<StaticCalibrationDelegate> calibrationDelegate;
@property CMAcceleration accelerometerBias;
@property CMRotationRate gyroBias;

- (BOOL) startMotionCapture;
- (void) startStaticCalibration;
- (void) stopMotionCapture;
- (BOOL) isCapturing;

+ (MotionManager *) sharedInstance;

@end
