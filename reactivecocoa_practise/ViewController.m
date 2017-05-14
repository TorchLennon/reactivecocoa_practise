//
//  ViewController.m
//  reactivecocoa_practise
//
//  Created by ZangChengwei on 16/6/19.
//  Copyright © 2016年 ZangChengwei. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa.h>

@interface ViewController ()

@end

@implementation ViewController
void sendAsync()
{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSLog(@"111");
        RACDisposable *disposable = [[RACScheduler mainThreadScheduler] schedule:^{
            NSLog(@"!!!");
            [subscriber sendNext:@1];
            [subscriber sendCompleted];
        }];
        return disposable;
    }];
    
    NSLog(@"222");
    [signal subscribeNext:^(id x) {
        NSLog(@"333");
    }];
    
    NSLog(@"444");
}
- (void)viewDidLoad {
    [super viewDidLoad];
//    RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:2];
//    [subject subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    }];
//    [subject sendNext:@1];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [subject sendNext:@2];
//    });
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [subject subscribeNext:^(id x) {
//            NSLog(@"replay:%@",x);
//        }];
//    });
//    RACSignal *signal= [[@[@1,@2,@3,@4].rac_sequence signal] groupBy:^id<NSCopying>(NSNumber *object) {
//        return object.integerValue % 2 != 0 ? @"odd" : @"even";
//    }];
//    [[[signal filter:^BOOL(RACGroupedSignal *value) {
//        return [(NSString *)value.key isEqual:@"odd"] ;
//    }] flatten] subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    }];

    sendAsync();

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
