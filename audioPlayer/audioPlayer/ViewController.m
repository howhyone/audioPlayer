//
//  ViewController.m
//  audioPlayer
//
//  Created by mac on 2018/4/16.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "ViewController.h"
#import "AVFoundation/AVFoundation.h"
#define MaxVolume 1.0
#define MinVolume 0.2
#define recorderVolume  2.0
@interface ViewController ()<AVAudioRecorderDelegate,AVAudioPlayerDelegate>
{
    NSTimer *myTimer;
    int number;
    NSInteger countDown;
    NSString *filePath;
//    dispatch_time_t popTime;


}
@property (weak, nonatomic) IBOutlet UIButton *playerBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopRecorderBtn;
@property (weak, nonatomic) IBOutlet UITextField *timerLabel;

@property(nonatomic, strong) AVAudioSession *session;
@property (nonatomic, retain) AVAudioPlayer *player;
@property(nonatomic, retain) AVAudioPlayer *backGroundPlayer;
@property (nonatomic, retain) AVAudioRecorder *recorder;
@property (nonatomic, copy)NSURL *recordFileUrl;

@end

@implementation ViewController

int64_t delayInSeconds = 3.0;  //延迟时间

- (void)viewDidLoad {
    [super viewDidLoad];
}
- (IBAction)startRecord:(id)sender {
    countDown = 0;
    myTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(recordTimer) userInfo:nil repeats:YES];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    if (session == nil) {
        NSLog(@"Error creating session : %@", [sessionError description]);
    }
    else
    {
        [session setActive:YES error:nil];
    }
    self.session = session;
    filePath = [self FilePathInLibraryWithName:@"Caches/UserRecordTemp.wav"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:filePath error:nil];
    self.recordFileUrl = [NSURL fileURLWithPath:filePath];
    
    NSDictionary *recordSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithFloat: 44100.0],AVSampleRateKey, //采样率
                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,//采样位数 默认 16
                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,//通道的数目,
                                   nil];
    
    _recorder = [[AVAudioRecorder alloc] initWithURL:self.recordFileUrl settings:recordSetting error:nil];
    if (_recorder) {
        _recorder.meteringEnabled = YES;
        [_recorder prepareToRecord];
        [_recorder record];
    }
    else
    {
        NSLog(@"音频格式和文件格式存储不匹配，无法初始化Recorder");
    }
    
}
- (NSString *)FilePathInLibraryWithName:(NSString *)name{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *LibraryDirectory = [paths objectAtIndex:0];
    return [LibraryDirectory stringByAppendingPathComponent:name];
}

- (IBAction)stopRecorder:(id)sender {
    [self removeTimer];
    if ([self.recorder isRecording]) {
        [self.recorder stop];
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]) {
        _timerLabel.text = [NSString stringWithFormat:@"录了 %ld 秒,文件大小为 %.2fKb",countDown,[[manager attributesOfItemAtPath:filePath error:nil] fileSize]/1024.0];
    }else
    {
        NSLog(@"hahahah");
    }
}

- (IBAction)player:(id)sender
{
    [self.recorder stop];
    if ([self.player isPlaying]) {
        return;
    }
    [self playBackGroundSong];
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 0.5*NSEC_PER_SEC, 0);
        //计时器回调
        dispatch_source_set_event_handler(_timer, ^{
            self.backGroundPlayer.volume -= 0.05;
            NSLog(@"----------- entry event_handler backGroundPlayer.volume = %f",self.backGroundPlayer.volume);
            if ((self.backGroundPlayer.volume <= MinVolume)) {
                // 异步取消调度源
                dispatch_source_cancel(_timer);
            }
            else if (self.backGroundPlayer.volume > recorderVolume)
            {
                NSLog(@"self.backGroundPlayer error");
            }
        });
        //dispatch源取消时调用的block
        dispatch_source_set_cancel_handler(_timer, ^{
            [self playRecorder];
        });
        //启动_timer
        dispatch_resume(_timer);
}
#pragma mark --- 播放录音
-(void)playRecorder
{
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recordFileUrl error:nil];
    self.player.delegate = self;
    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.player.volume = recorderVolume;
    [self.player prepareToPlay];
    [self.player play];
}
#pragma mark ---- 播放背景音乐
-(void)playBackGroundSong
{
    NSString *songStr = [[NSBundle mainBundle] pathForResource:@"谢谢你的温柔" ofType:@"mp3"];
    NSURL *songUrl = [NSURL fileURLWithPath:songStr];
    self.backGroundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:songUrl error:nil];
    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.backGroundPlayer.volume = MaxVolume;
    [self.backGroundPlayer prepareToPlay];
    [self.backGroundPlayer play];
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 0.5 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_timer, ^{
            self.backGroundPlayer.volume += 0.05;
            NSLog(@"----------- entry event_handler backGroundPlayer.volume = %f",self.backGroundPlayer.volume);
            if ((self.backGroundPlayer.volume >= MaxVolume)) {
                // 异步取消调度源
                dispatch_source_cancel(_timer);
            }
            else if (self.backGroundPlayer.volume < MinVolume)
            {
                NSLog(@"self.backGroundPlayer error");
            }
        });
        //dispatch源取消时调用的block
        dispatch_source_set_cancel_handler(_timer, ^{
            [self.backGroundPlayer stop];
        });
        //启动_timer
        dispatch_resume(_timer);
    }
    else
    {
        NSLog(@"音频播放无法解码 参数flag = %@",flag? @"YES":@"NO");
    }
    
}

-(void)recordTimer
{
    ++countDown;
    _timerLabel.text = [NSString stringWithFormat:@"%ld",(long)countDown];
}

-(void)removeTimer
{
    [myTimer invalidate];
    myTimer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
