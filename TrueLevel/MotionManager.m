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

#import "MotionManager.h"

// This factor corresponds to a low pass filter with a cutoff of approximately 5Hz for 100Hz input
#define FILTER_FACTOR 0.05
// The amount of time (in seconds) to perform static calibration
#define STATIC_CALIBRATION_TIME 0.5

@implementation MotionManager
{
    NSTimer* timerMotion;
    BOOL isCapturing;
    BOOL isCalibrating;
    CMAcceleration accelerometerBias;
    CMRotationRate gyroBias;
    NSTimeInterval calibrationStartTime;
}
@synthesize cmMotionManager, delegate, calibrationDelegate, accelerometerBias, gyroBias;

+ (MotionManager*) sharedInstance
{
    static MotionManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init
{
	if(self = [super init])
	{
        cmMotionManager = [CMMotionManager new];
        isCapturing = NO;
        timerMotion = nil;
	}
	return self;
}

/** @returns True if successfully started motion capture. */
- (BOOL) startMotionCapture
{
    if(cmMotionManager == nil)
    {
        NSLog(@"Failed to start motion capture. Motion Manager is nil");
        return NO;
    }

    if (!isCapturing)
    {
        //Timer interval of .011 determined experimentally, setting it to .01 makes the gyro rate drop dramatically
        [cmMotionManager setAccelerometerUpdateInterval:.011];
        [cmMotionManager setGyroUpdateInterval:.011];
        isCapturing = [self startMotionCaptureWithTimer:[NSTimer scheduledTimerWithTimeInterval:.011 target:self selector:@selector(timerCallback:) userInfo:nil repeats:true]];
    }
    return isCapturing;
}

- (void) startStaticCalibration
{
    if(!isCapturing) return;

    if(!isCalibrating)
    {
        isCalibrating = YES;
        calibrationStartTime = 0;
    }
}

- (void)removeGravity
{
    if(fabs(accelerometerBias.x) >= fabs(accelerometerBias.y) && fabs(accelerometerBias.x) >= fabs(accelerometerBias.z))
        accelerometerBias.x -= copysign(1.0, accelerometerBias.x);
    else if(fabs(accelerometerBias.y) >= fabs(accelerometerBias.x) && fabs(accelerometerBias.y) >= fabs(accelerometerBias.z))
        accelerometerBias.y -= copysign(1.0, accelerometerBias.y);
    else if(fabs(accelerometerBias.z) >= fabs(accelerometerBias.x) && fabs(accelerometerBias.z) >= fabs(accelerometerBias.y))
        accelerometerBias.z -= copysign(1.0, accelerometerBias.z);
    else
        NSLog(@"Error: This should never happen");
}

- (void)timerCallback:(id)userInfo
{
    CMGyroData *gyroData = cmMotionManager.gyroData;
    if(delegate && [delegate respondsToSelector:@selector(receiveGyroData:)])
        [delegate receiveGyroData:gyroData];

    CMAccelerometerData *accelerometerData = cmMotionManager.accelerometerData;
    if(delegate && [delegate respondsToSelector:@selector(receiveAccelerometerData:)])
        [delegate receiveAccelerometerData:accelerometerData];

    if(isCalibrating)
    {
        if(calibrationStartTime == 0)
        {
            calibrationStartTime = accelerometerData.timestamp;
            accelerometerBias = accelerometerData.acceleration;
            gyroBias = gyroData.rotationRate;
        }
        else if(accelerometerData.timestamp - calibrationStartTime >= STATIC_CALIBRATION_TIME)
        {
            isCalibrating = NO;
            [self removeGravity];
            if (calibrationDelegate && [calibrationDelegate respondsToSelector:@selector(staticCalibrationProgress:)])
                [calibrationDelegate staticCalibrationProgress:1.0];
            if (calibrationDelegate && [calibrationDelegate respondsToSelector:@selector(staticCalibrationDidFinish)])
                [calibrationDelegate staticCalibrationDidFinish];
        }
        else
        {
            accelerometerBias.x = accelerometerBias.x*(1 - FILTER_FACTOR) + accelerometerData.acceleration.x*(FILTER_FACTOR);
            accelerometerBias.y = accelerometerBias.y*(1 - FILTER_FACTOR) + accelerometerData.acceleration.y*(FILTER_FACTOR);
            accelerometerBias.z = accelerometerBias.z*(1 - FILTER_FACTOR) + accelerometerData.acceleration.z*(FILTER_FACTOR);
            gyroBias.x = gyroBias.x*(1 - FILTER_FACTOR) + gyroData.rotationRate.x*(FILTER_FACTOR);
            gyroBias.y = gyroBias.y*(1 - FILTER_FACTOR) + gyroData.rotationRate.y*(FILTER_FACTOR);
            gyroBias.z = gyroBias.z*(1 - FILTER_FACTOR) + gyroData.rotationRate.z*(FILTER_FACTOR);
            if (calibrationDelegate && [calibrationDelegate respondsToSelector:@selector(staticCalibrationProgress:)])
            {
                float progress = (accelerometerData.timestamp - calibrationStartTime)/STATIC_CALIBRATION_TIME;
                [calibrationDelegate staticCalibrationProgress:progress];
            }
        }
    }
}

- (BOOL)startMotionCaptureWithTimer:(NSTimer *)timer
{
    timerMotion = timer;
    if(timerMotion == nil)
    {
        NSLog(@"Failed to start motion capture. Timer is nil");
        return NO;
    }

    [cmMotionManager startGyroUpdates];
    [cmMotionManager startAccelerometerUpdates];
    return true;
}

- (void) stopMotionCapture
{
    if(timerMotion) [timerMotion invalidate];

    if(cmMotionManager)
    {
        if(cmMotionManager.isAccelerometerActive) [cmMotionManager stopAccelerometerUpdates];
        if(cmMotionManager.isGyroActive) [cmMotionManager stopGyroUpdates];
    }

    isCapturing = NO;

    timerMotion = nil;
}

- (BOOL)isCapturing
{
    return isCapturing;
}

@end