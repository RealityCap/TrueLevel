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

#import "DoubleLevel.h"

#import "MBProgressHUD.h"

@implementation DoubleLevel
{
    CMAcceleration accelerometerBias;
    BOOL isCalibrating;
    MBProgressHUD *progressView;
}

@synthesize calibratedLevel, uncalibratedLevel, button;

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePause)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];

    [self resetCalibration];
	isCalibrating = NO;

    accelerometerBias = [MotionManager sharedInstance].accelerometerBias;
    [MotionManager sharedInstance].delegate = self;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) handlePause
{
    if (isCalibrating) [self resetCalibration];
}


- (void)staticCalibrationProgress:(float)progress
{
    [progressView setProgress:progress];
}

- (void) staticCalibrationDidFinish
{
    [MotionManager sharedInstance].calibrationDelegate = nil;
    accelerometerBias = [MotionManager sharedInstance].accelerometerBias;
    [self resetCalibration];
}

- (void) startCalibration
{
    [self showProgressWithTitle:@"Calibrating"];
    [button setTitle:@"Calibrating" forState:UIControlStateNormal];
    [MotionManager sharedInstance].calibrationDelegate = self;
    [[MotionManager sharedInstance] startStaticCalibration];
    isCalibrating = YES;
}

- (void) resetCalibration
{
    [button setTitle:@"Begin Calibration" forState:UIControlStateNormal];
    isCalibrating = NO;
    [self hideProgress];
}

- (void)showProgressWithTitle:(NSString*)title
{
    progressView = [[MBProgressHUD alloc] initWithView:self.view];
    progressView.mode = MBProgressHUDModeAnnularDeterminate;
    [self.view addSubview:progressView];
    progressView.labelText = title;
    [progressView show:YES];
}

- (void)hideProgress
{
    [progressView hide:YES];
}

- (IBAction)handleButton:(id)sender
{
    if (!isCalibrating) [self startCalibration];
}

- (void)receiveAccelerometerData:(CMAccelerometerData *)accelerometerData
{
    if (!isCalibrating)
    {
        [uncalibratedLevel addAccelerometerValue:accelerometerData.acceleration];
        CMAcceleration currentValue = accelerometerData.acceleration;
        double radians = acos(currentValue.z*currentValue.z / (currentValue.x*currentValue.x + currentValue.y*currentValue.y + currentValue.z*currentValue.z));
        CMAcceleration calibratedAcceleration;
        calibratedAcceleration.x = accelerometerData.acceleration.x - accelerometerBias.x;
        calibratedAcceleration.y = accelerometerData.acceleration.y - accelerometerBias.y;
        calibratedAcceleration.z = accelerometerData.acceleration.z - accelerometerBias.z;
        currentValue = calibratedAcceleration;
        radians = acos(currentValue.z*currentValue.z / (currentValue.x*currentValue.x + currentValue.y*currentValue.y + currentValue.z*currentValue.z));
        [calibratedLevel addAccelerometerValue:calibratedAcceleration];
    }
}

@end
