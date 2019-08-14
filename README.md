# LXLGCDTimer
iOS中定时器的使用
gcdTimer vs NSTimer

使用NSTimer，注意点：
一、切换runloop时失效
默认情况下NSTimer会加入到runloop defaultMode中，当界面上有scrollview滑动时，runloop会切换到trackingMode，此时NSTimer会暂停，如果要避免此情况，如下：
```
- (IBAction)startNSTimer:(id)sender {
    _nsTimer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSLog(@"%@ xxxx", NSTimerName);
    }];
    [[NSRunLoop mainRunLoop] addTimer:_nsTimer forMode:NSRunLoopCommonModes];
}
```
二、可能引起内存泄漏
NSTimer与self相互持有，使用weakSelf解除循环引用：
```
    __weak typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakSelf doSth];
    }];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
```
这样self可以正常走dealloc，但是，在self销毁后，timer并不会销毁！因为runloop仍然持有着timer
所以需要在必要的位置，停止timer，比如viewController的viewWillDisapper中（但是viewWillDisapper调用时机有很多，只要有新的controller覆盖当前的controller，此方法就会调用，所以是否要在viewWillDisapper中调用，请根据自己的业务逻辑来处理）
我的做法：
```
//runloop虽然会强持有timer，但是是在把timer加入runloop之后，所以还是要强持有timer，arc会处理这个strong，没关系
@property(nonatomic, strong) NSTimer *nsTimer;

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self cancelNSTimer];
}

- (void)dealloc{
    [self cancelNSTimer];
    NSLog(@"%@ is dealloced, timer=%@", self, _nsTimer);
}

- (void)doSth{
    //doSth
    //when sth is done
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
```
三、不能跨线程操作NSTimer?
此点有疑问，如下：
```
- (void)cancelNSTimer{
    if (!_nsTimer) {
        return;
    }
    
    dispatch_queue_t queue = dispatch_queue_create("com.levi.queue", NULL);
    
    dispatch_sync(queue, ^{
        [_nsTimer invalidate];
        _nsTimer = nil;
    });
}
```
timer是在主线程中创建的，但是这里我在子线程中操作，同样有效，有知道的请解答下
***
使用GCDTimer
引入demo中LXLGCDTimer目录
一、创建GCDTimer
```
- (IBAction)startGCDTimer:(id)sender {
    [LXLGCDTimerManager.sharedInstance scheduleGCDTimerWithName:self.timerName interval:1 queue:dispatch_get_main_queue() repeats:YES option:CancelPreviousTimerAction action:^{
        //此方法中请使用weakSelf
        NSLog(@"%@ xxxx", GCDTimerName);
    }];
}
```
二、实现以下方法
```
//也可自己实现timerName方法，达到同一界面添加多个定时器目的
- (NSString *)timerName{
    return [NSString stringWithFormat:@"%@timer", NSStringFromClass(self.class)];
}

- (void)cancelGCDTimer{
    [LXLGCDTimerManager.sharedInstance cancelTimerWithName:self.timerName];
}

//适当位置取消定时器，不然也会出现像NSTimer一样的情况，controller已经销毁，但是定时器仍然在运行！
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self cancelGCDTimer];
}

- (void)dealloc{
    [self cancelGCDTimer];
}
```
本来想写的标题是用gcdTimer替代NSTimer可以避免很多坑，但是写完发现其实NSTimer使用正确的话，代码量跟gcdTimer是一样的（还不包括引入的LXLGCDTimer！）
总结：都可以用！

