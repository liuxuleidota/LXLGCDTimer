//
//  TimerViewController.m
//  GCDTimerTest
//
//  Created by levi on 2018/10/19.
//  Copyright © 2018 levi. All rights reserved.
//

#import "TimerViewController.h"
#import "LXLGCDTimerManager.h"

#define WEAK_SELF __weak typeof(self)weakSelf = self;

static NSString* const GCDTimerName = @"GCDTimer";
static NSString* const NSTimerName = @"NSTimer";

@interface TimerViewController ()
@property(nonatomic, strong) NSTimer *nsTimer;
@end

@implementation TimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"timer";
    self.view.backgroundColor = UIColor.whiteColor;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"TestDisapper" style:UIBarButtonItemStylePlain target:self action:@selector(test)];
}

- (void)test {
    UIViewController *ctr = [[UIViewController alloc] init];
    ctr.title = @"TestDisapper";
    [self.navigationController pushViewController:ctr animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self cancelAllTimer];
}

- (void)dealloc{
    [self cancelAllTimer];
    NSLog(@"%@ is dealloced, timer=%@", self, _nsTimer);
}

- (void)cancelAllTimer{
    [self cancelGCDTimer];
    [self cancelNSTimer];
}

- (void)cancelNSTimer{
    if (!_nsTimer) {
        return;
    }

    //从runloop移除timer
    [_nsTimer invalidate];

    //将timer置为nil，如果没有此行，在dealloc中打印仍然可以看到timer不为空
    //至于在dealloc方法走完，self销毁后，timer是否被销毁，这里没有进一步测试，因为NSTimer不能子类化
    _nsTimer = nil;
}

- (NSString *)timerName{
    return [NSString stringWithFormat:@"%@timer", NSStringFromClass(self.class)];
}

- (void)cancelGCDTimer{
    [LXLGCDTimerManager.sharedInstance cancelTimerWithName:self.timerName];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ider"];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        cell.textLabel.text = GCDTimerName;
    } else {
        cell.textLabel.text = NSTimerName;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        [self startGCDTimer:nil];
    } else {
        [self startNSTimer:nil];
    }
}

- (IBAction)startGCDTimer:(id)sender {
    [self cancelAllTimer];
    
    [LXLGCDTimerManager.sharedInstance scheduleGCDTimerWithName:self.timerName interval:1 queue:dispatch_get_main_queue() repeats:YES option:CancelPreviousTimerAction action:^{
        NSLog(@"%@ xxxx", GCDTimerName);
    }];
}

- (IBAction)startNSTimer:(id)sender {
    [self cancelAllTimer];
    
    _nsTimer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSLog(@"%@ xxxx", NSTimerName);
    }];
    [[NSRunLoop mainRunLoop] addTimer:_nsTimer forMode:NSRunLoopCommonModes];
}

@end
