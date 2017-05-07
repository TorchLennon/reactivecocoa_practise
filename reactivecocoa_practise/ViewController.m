//
//  ViewController.m
//  reactivecocoa_practise
//
//  Created by ZangChengwei on 16/6/19.
//  Copyright © 2016年 ZangChengwei. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa.h>
#import <Masonry.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *grid;
@property (weak, nonatomic) IBOutlet UIButton *autoRunBtn;
@property (weak, nonatomic) IBOutlet UIButton *oneStepBtn;

@end

static int GridXBlocks = 13;
static int GridYBlocks = 7;

typedef NS_ENUM(NSUInteger, SpiritState) {
    SpiritStateAppear,
    SpiritStateRunning,
    SpiritStateDisappear,
};

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImage *img1 = [UIImage imageNamed:@"pet1"];
    UIImage *img2 = [UIImage imageNamed:@"pet2"];
    UIImage *img3 = [UIImage imageNamed:@"pet3"];
    
    NSArray *steps = @[RACTuplePack(@1, @0), RACTuplePack(@1, @0),
                       RACTuplePack(@1, @0), RACTuplePack(@0, @1),
                       RACTuplePack(@0, @1), RACTuplePack(@0, @1),
                       RACTuplePack(@1, @0), RACTuplePack(@1, @0),
                       RACTuplePack(@1, @0), RACTuplePack(@1, @0),
                       RACTuplePack(@0, @-1), RACTuplePack(@0, @-1),
                       RACTuplePack(@1, @0), RACTuplePack(@1, @0),
                       RACTuplePack(@1, @0)
                       ];
    
    RACTuple *startBlock = RACTuplePack(@1, @2);
    
    RACSequence *stepsSequence = steps.rac_sequence;
    
    NSInteger spiritCount = steps.count + 1; // 步数 + 1个起始位置
    
    void (^updateXYConstraints)(UIView *view, RACTuple *location) = ^(UIView *view, RACTuple *location) {
        CGFloat width = self.grid.frame.size.width / GridXBlocks;
        CGFloat height = self.grid.frame.size.height / GridYBlocks;
        CGFloat x = [location.first floatValue] * width;
        CGFloat y = [location.second floatValue] * height;
        view.frame = CGRectMake(x, y, width, height);
    };
    
    for (int i = 0; i < spiritCount; ++i) {
        UIImageView *spiritView = [[UIImageView alloc] init];
        
        spiritView.tag = i;
        spiritView.animationImages = @[img1, img2, img3];
        spiritView.animationDuration = 1.0;
        spiritView.alpha = 0.0f;
        [self.grid addSubview:spiritView];
        
        updateXYConstraints(spiritView, startBlock);
    }
    
    
    
    RACSignal *stepsSignal = [[[[[[RACSignal return:startBlock] concat:[stepsSequence.signal scanWithStart:startBlock reduceWithIndex:^id(RACTuple *running, RACTuple *next, NSUInteger index) {
        return RACTuplePack(@([running.first integerValue] + [next.first integerValue]),@([running.second integerValue] + [next.second integerValue]));
    }]] collect]  concat:[RACSignal never]] sample:[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]]] scanWithStart:nil reduceWithIndex:^id(id running, NSArray *steps, NSUInteger index) {
        SpiritState state = SpiritStateRunning;
        if (0 == index%steps.count) {
            state = SpiritStateAppear;
        }else if (0 == (index+1)%steps.count){
            state = SpiritStateDisappear;
        }
        return RACTuplePack(@(state),steps[index%steps.count]);
    }];

    
    
    RACSignal *autoClickSignal = [[self.autoRunBtn rac_signalForControlEvents:UIControlEventTouchUpInside] mapReplace:@(YES)];
    RACSignal *manualClickSignal = [[self.oneStepBtn rac_signalForControlEvents:UIControlEventTouchUpInside] mapReplace:@(NO)];

    typedef NS_ENUM(NSUInteger, GenerateState) {
        GenerateStateNew =0,
        GenerateStateStop,
        GenerateStateIgnore,
    };
    
    RACSignal *controlSignal = [[[[autoClickSignal merge:manualClickSignal] scanWithStart:RACTuplePack(nil,nil) reduce:^id(RACTuple *running, id next) {
        if (!running.first) {
            return RACTuplePack(@(GenerateStateNew),next);
        }
        if ([running.second isEqual:next]) {
            if ([running.second isEqual:@(YES)] && ([running.first unsignedIntegerValue] != GenerateStateStop)) {
                return RACTuplePack(@(GenerateStateIgnore),next);
            }else{
                return RACTuplePack(@(GenerateStateNew),next);
            }
        }else{
            return RACTuplePack(@(GenerateStateStop),next);
        }
    }] filter:^BOOL(RACTuple *value) {
        if ([value.first isEqual:@(GenerateStateIgnore)]) {
            return @(NO);
        }
        return @(YES);
    }] map:^id(RACTuple *value) {
        if ([value.first isEqual:@(GenerateStateNew)]) {
            if ([value.second isEqual:@(YES)]) {
                return [[RACSignal interval:1.5 onScheduler:[RACScheduler mainThreadScheduler]] startWith:nil];
            }else{
                return [RACSignal return:nil];
            }
        }else{
            return [RACSignal empty];
        }
    }];
    RACSignal *newSpiritSignal = [[[[controlSignal switchToLatest] scanWithStart:nil reduceWithIndex:^id(id running, id next, NSUInteger index) {
        return @(index);
    }] take:spiritCount] flattenMap:^RACStream *(id index) {
        return [stepsSignal map:^id(RACTuple *value) {
            return RACTuplePack(index,value.first,value.second);
        }];
    }];
    RACSignal *spiritRunSignal = newSpiritSignal;
    @weakify(self)
    [[spiritRunSignal deliverOnMainThread] subscribeNext:^(RACTuple *info) {
        @strongify(self)
        RACTupleUnpack(NSNumber *idx, NSNumber *state, RACTuple *xy) = info;
        SpiritState stateValue = state.unsignedIntegerValue;
        NSInteger idxValue = idx.integerValue;
        UIImageView *spirit = [self.grid viewWithTag:idxValue];
        
        switch (stateValue) {
            case SpiritStateAppear:
            {
                updateXYConstraints(spirit, xy);
                [UIView animateWithDuration:1 animations:^{
                    spirit.alpha = 1.0f;
                }];
                [spirit startAnimating];
            }
                break;
            case SpiritStateRunning:
            {
                [UIView animateWithDuration:1 animations:^{
                    updateXYConstraints(spirit, xy);
                }];
            }
                break;
            case SpiritStateDisappear:
            {
                [UIView animateWithDuration:1 animations:^{
                    spirit.alpha = 0;
                } completion:^(BOOL finished) {
//                    [spirit stopAnimating];
                }];
                
            }
                break;
            default:
                break;
        }
        
        
    }];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
