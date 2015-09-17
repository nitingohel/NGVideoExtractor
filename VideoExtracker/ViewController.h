//
//  ViewController.h
//  VideoExtracker
//
//  Created by Nitin Gohel on 19/02/15.
//  Copyright (c) 2015 Olbuz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KAProgressLabel.h"
@interface ViewController : UIViewController<UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIButton *btnPlay;

@property (strong, nonatomic) IBOutlet UIButton *btnStop;
- (IBAction)ActionPlay:(UIButton *)sender;
- (IBAction)ActionStop:(UIButton *)sender;
@end

