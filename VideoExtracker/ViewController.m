//
//  ViewController.m
//  VideoExtracker
//
//  Created by Nitin Gohel on 19/02/15.
//  Copyright (c) 2015 Olbuz. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@interface ViewController ()
{

}
@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic) CGFloat frame_width;
@property (nonatomic) Float64 durationSeconds;
@property (nonatomic, strong) UIScrollView *bgView;
@property (nonatomic, strong) UIView *centerView;
@property (nonatomic,strong)AVPlayer * avPlayer;
@property (nonatomic,strong)AVPlayerItem *avPlayerItem;
@property (strong, nonatomic) NSString *originalVideoPath;
@property (weak,nonatomic) IBOutlet KAProgressLabel * pLabel;
@end
#define SLIDER_BORDERS_SIZE 6.0f
#define BG_VIEW_BORDERS_SIZE 3.0f
@implementation ViewController

- (void)viewDidLoad {
    
    
    self.pLabel.layer.cornerRadius = self.pLabel.frame.size.height /2;;
    self.pLabel.layer.masksToBounds=YES;
    self.pLabel.progressLabelVCBlock = ^(KAProgressLabel *label, CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [label setText:[NSString stringWithFormat:@"%.0f%%", progress*100]];
        });
    };
    
    [self.pLabel setBackBorderWidth: 10.0];
    [self.pLabel setFrontBorderWidth: 10.0];
    [self.pLabel setColorTable: @{
                                  NSStringFromProgressLabelColorTableKey(ProgressLabelTrackColor):[UIColor blackColor],
                                  NSStringFromProgressLabelColorTableKey(ProgressLabelProgressColor):[UIColor whiteColor]
                                  }];
    
    
    
    CGRect frame = CGRectMake(10, 200, self.view.frame.size.width, 70);
    
    _frame_width = frame.size.width;
    _bgView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-70, self.view.frame.size.width, frame.size.height)];
   
    
    _bgView.layer.borderColor = [UIColor grayColor].CGColor;
    _bgView.layer.borderWidth = BG_VIEW_BORDERS_SIZE;
    [self.view addSubview:_bgView];


    [self getMovieFrame];
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)isRetina{
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            
            ([UIScreen mainScreen].scale == 2.0));
}
- (void)updateProgressBar
{
    double duration = CMTimeGetSeconds(_avPlayerItem.duration);
    double time = CMTimeGetSeconds(_avPlayer.currentTime);
    
     
    
    [self.pLabel setProgress:( time / duration)];
    

}
-(void)getMovieFrame{
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    self.originalVideoPath = [mainBundle pathForResource: @"video" ofType: @"MOV"];
    NSURL *videoFileUrl = [NSURL fileURLWithPath:self.originalVideoPath];
    AVAsset *myAsset = [[AVURLAsset alloc] initWithURL:videoFileUrl options:nil];
 
    _avPlayerItem =[[AVPlayerItem alloc]initWithAsset:myAsset];
   _avPlayer = [[AVPlayer alloc]initWithPlayerItem:_avPlayerItem];
    
    
    
    AVPlayerLayer *avPlayerLayer =[AVPlayerLayer playerLayerWithPlayer:_avPlayer];
    [avPlayerLayer setFrame:CGRectMake(0, 0, self.view.frame.size.width-100, self.view.frame.size.height-72)];
    [avPlayerLayer setVideoGravity:AVLayerVideoGravityResize];
    [self.view.layer addSublayer:avPlayerLayer];
    

    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:myAsset];
    
    if ([self isRetina]){
        self.imageGenerator.maximumSize = CGSizeMake(_bgView.frame.size.width*2, _bgView.frame.size.height*2);
    } else {
        self.imageGenerator.maximumSize = CGSizeMake(_bgView.frame.size.width, _bgView.frame.size.height);
    }
    
    int picWidth = 100;
    
    // First image
    NSError *error;
    CMTime actualTime;
    CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:&actualTime error:&error];
    if (halfWayImage != NULL) {
        UIImage *videoScreen;
        if ([self isRetina]){
            videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationUp];
        } else {
            videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
        }
        UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
        CGRect rect=tmp.frame;
        rect.size.width=picWidth;
        tmp.frame=rect;
        [_bgView addSubview:tmp];
        picWidth = tmp.frame.size.width;
        CGImageRelease(halfWayImage);
    }
    
    
    _durationSeconds = CMTimeGetSeconds([myAsset duration]);
    

    int picsCnt = ceil(_durationSeconds);
    
    NSMutableArray *allTimes = [[NSMutableArray alloc] init];
    
    int time4Pic = 0;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
        // Bug iOS7 - generateCGImagesAsynchronouslyForTimes
        int prefreWidth=0;
        for (int i=1, ii=1; i<picsCnt; i++){
            time4Pic = i*picWidth;
            
            CMTime timeFrame = CMTimeMakeWithSeconds(i, 60);
            //[NSValue valueWithCMTime:CMTimeMakeWithSeconds(i, 60)]];
            
            [allTimes addObject:[NSValue valueWithCMTime:timeFrame]];
            
            
            CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:timeFrame actualTime:&actualTime error:&error];
            
            
            UIImage *videoScreen;
            if ([self isRetina]){
                videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationUp];
            } else {
                videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
            }
            
            
            
            UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
            tmp.tag=CMTimeGetSeconds(actualTime);
            tmp.userInteractionEnabled = YES;
            UITapGestureRecognizer *pgr = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(handlePinch:)];
            pgr.delegate = self;
            [tmp addGestureRecognizer:pgr];
            
            
            
            CGRect currentFrame = tmp.frame;
            currentFrame.origin.x = ii*picWidth;
            
            currentFrame.size.width=picWidth;
            prefreWidth+=currentFrame.size.width;
            
            if( i == picsCnt-1){
                currentFrame.size.width-=6;
            }
            tmp.frame = currentFrame;
            int all = (ii+1)*tmp.frame.size.width;
            
            if (all > _bgView.frame.size.width){
                int delta = all - _bgView.frame.size.width;
                currentFrame.size.width -= delta;
            }
            
            ii++;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_bgView addSubview:tmp];
            });
            
            
            
            
            CGImageRelease(halfWayImage);
            
        }
         _bgView.contentSize = CGSizeMake(picsCnt*100, 70);
      
      
        
        return;
    }
    

    
   
    
}
#pragma mark tapgesturmethod

- (void)handlePinch:(UITapGestureRecognizer *)pinchGestureRecognizer
{
    UIImageView *imageView = (UIImageView *)pinchGestureRecognizer.view;
    
    NSLog(@"%d",imageView.tag);
    
    CMTime seekingCM = CMTimeMake(imageView.tag, 1);
    
    [_avPlayer seekToTime:seekingCM];
    __weak ViewController *self_ = self;
    [_avPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0 / 60.0, NSEC_PER_SEC)
                                            queue:NULL
                                       usingBlock:^(CMTime time){
                                           [self_ updateProgressBar];
                                       }];
    
    
    [_avPlayer play];
}

#pragma mark button action
- (IBAction)ActionPlay:(UIButton *)sender {
    
    [_avPlayer seekToTime:kCMTimeZero];
    
    
    __weak ViewController *self_ = self;
    [_avPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1.0 / 60.0, NSEC_PER_SEC)
                                            queue:NULL
                                       usingBlock:^(CMTime time){
                                           [self_ updateProgressBar];
                                       }];
    
    [_avPlayer play];
    
}

- (IBAction)ActionStop:(UIButton *)sender {
    
    [_avPlayer seekToTime:kCMTimeZero];
    [_avPlayer pause];
}
@end
