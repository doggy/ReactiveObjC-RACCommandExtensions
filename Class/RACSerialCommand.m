//
//  RACSerialCommand.m
//  ReactiveObjC+RACCommandExtensions
//
//  Created by doggy on 11/07/16.
//  Copyright © 2016 Github. All rights reserved.
//

#import "RACSerialCommand.h"

@interface RACSerialCommand ()
// property inhert from super class
@property (nonatomic, copy, readonly) RACSignal * (^signalBlock)(id input);

@property (nonatomic, strong) RACSubject * subjectCancel;
@property (nonatomic, strong) RACSignal  * signalCancel;
@end

@implementation RACSerialCommand

- (void)setupCancelSignal
{
    self.subjectCancel = RACSubject.subject;
    self.signalCancel = self.subjectCancel.replayLast;
}

- (void)cancelExecution {
    RACSubject* subjectPrevious = self.subjectCancel;
    dispatch_async(dispatch_get_main_queue(), ^{
        // Each executionSignal returned in signalBlock will be connected to RACMulticastConnection asynchronously
        //  In RAC v2.1.8, the executionSignal won't be removed from _activeExecutionSignals array forever if it sendCompleted before connecting to RACMulticastConnection ..
        // That means the signal must be alive for awhile (at least one event loop)
        [subjectPrevious sendNext:nil];
    });
    
    [self setupCancelSignal];
}

- (id)initWithEnabled:(RACSignal *)enabledSignal signalBlock:(RACSignal * (^)(id input))signalBlock {
    if (self = [super initWithEnabled:enabledSignal signalBlock:signalBlock]) {
        [self setupCancelSignal];
        
        RACSubject * subjectQueue = RACSubject.subject;
        [[[[subjectQueue
            concat]
           takeUntil:self.rac_willDeallocSignal]
          publish]
         connect];
        
        __weak typeof(self) weakSelf = self;
        RACSignal * (^cancelableSignalBlock)(id input) = ^RACSignal *(id input) {
            // fetch task
            RACSignal * signalTask = signalBlock(input);
            
            // A replay subject is necessary here since
            // the task signal may become to complete immediately
            RACMulticastConnection * taskConnection = [signalTask
                                                       multicast:RACReplaySubject.subject];
            
            // Return value: multicasted signal
            RACSignal * signalCast = taskConnection.signal;
            
            // add task to queue
            [subjectQueue sendNext:[taskConnection.autoconnect
                                    // cancel command by itself while calling function execute:
                                    takeUntil:weakSelf.signalCancel]];
            return signalCast;
        };
        _signalBlock = [cancelableSignalBlock copy];
        self.allowsConcurrentExecution = YES;
    }
    return self;
}

@end
