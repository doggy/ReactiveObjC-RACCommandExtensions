//
//  RACSerialCommandSpec.m
//  RACCommandExtensions
//
//  Created by doggy on 11/7/16.
//  Copyright © 2016 Github. All rights reserved.
//

@import Quick;
@import Nimble;

#import "RACSerialCommand.h"

QuickSpecBegin(RACSerialCommandSpec)

qck_describe(@"Asynchronous working as a standard RACCommand", ^{
    __block RACSerialCommand * command = nil;
    
    qck_beforeEach(^{
        command = [[RACSerialCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            return [RACSignal
                    return:input];
        }];
    });
    
    qck_it(@"should get value in subscribeNext", ^{
        __block id outputValue = nil;
        RACSignal* taskSignal = [command execute:@YES];
        [taskSignal subscribeNext:^(id  _Nullable x) {
            outputValue = x;
        }];
        expect(outputValue).toEventually(equal(@YES));
    });
    
    qck_it(@"should reach completed status", ^{
        __block id outputValue = nil;
        RACSignal* taskSignal = [command execute:@YES];
        [taskSignal subscribeCompleted: ^{
            outputValue = @20;
        }];
        expect(outputValue).toEventually(equal(@20));
    });
});

qck_describe(@"running in serial queue", ^{
    __block RACSerialCommand * command = nil;
    
    qck_beforeEach(^{
        command = [[RACSerialCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            return [RACSignal
                    return:input];
        }];
    });
    
    qck_it(@"should report values in given sequence", ^{
        NSMutableArray<NSNumber *> * arrayInput = NSMutableArray.new;
        NSMutableArray<NSNumber *> * arrayOutput = NSMutableArray.new;
        
        NSUInteger i = 0;
        while (i++ < 5) {
            NSNumber * indexValue = @(i);
            [arrayInput addObject:indexValue];
            [[command execute:indexValue]
             subscribeNext:^(NSNumber * indexValue) {
                 [arrayOutput addObject:indexValue];
             }];
        }
        
        // timeout default is one second
        expect(arrayInput).toEventually(equal(arrayOutput));
    });
    
    qck_it(@"should execute all tasks one by one", ^{
        NSMutableArray<NSNumber *> * arrayInput = NSMutableArray.new;
        NSMutableArray<NSNumber *> * arrayOutput = NSMutableArray.new;
        
        RACSignal * queueSignal = RACSignal.empty;
        
        NSUInteger i = 0;
        while (i++ < 10) {
            NSNumber * indexValue = @(i);
            [arrayInput addObject:indexValue];
            RACSignal * taskSignal = [[command execute:indexValue]
                                      doNext:^(NSNumber * indexValue) {
                                          [arrayOutput addObject:indexValue];
                                      }];
            queueSignal = [queueSignal concat:taskSignal];
        }
        
        __block BOOL bFinished = NO;
        [queueSignal subscribeCompleted:^{
            bFinished = YES;
        }];
        expect(@(bFinished)).withTimeout(2).toEventually(beTruthy());
        
        expect(arrayInput).withTimeout(2).toEventually(equal(arrayOutput));
    });
});

qck_describe(@"task cancellation", ^{
    __block NSMutableArray<NSNumber *> * arrayInput = NSMutableArray.new;
    __block NSMutableArray<NSNumber *> * arrayOutput = NSMutableArray.new;
    
    qck_beforeEach(^{
        [arrayInput removeAllObjects];
        [arrayOutput removeAllObjects];
    });
    
    qck_it(@"should cancel 1-4, since all task signals are pending in queue", ^{
        RACSerialCommand * command = [[RACSerialCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            return [[RACSignal.empty
                     delay:0.1]
                    concat:[RACSignal return:input]];
        }];
        
        NSUInteger i = 0;
        while (i++ < 10) {
            NSNumber * indexValue = @(i);
            [arrayInput addObject:indexValue];
            [[command execute:indexValue]
             subscribeNext:^(NSNumber * indexValue) {
                 [arrayOutput addObject:indexValue];
             }];
            if (i == 4) {
                [command cancelExecution];
                [arrayInput removeAllObjects];
            }
        }
        
        // Output: 5,6,7,8,9,10
        expect(arrayOutput).withTimeout(2).toEventually(equal(arrayInput));
    });
    
    qck_it(@"should not cancel any task since all signals running synchronously", ^{
        RACSerialCommand * command = [[RACSerialCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            return [RACSignal
                    return:input];
        }];
        
        // Okay, ...
        //  It's just looks rightly in theory.
        //  In practice, Task 1-4 should be cancelled cus
        //    'execute:' always perform in next loop
        //    A enhanced logic should be updated here
        NSUInteger i = 0;
        while (i++ < 10) {
            NSNumber * indexValue = @(i);
            [arrayInput addObject:indexValue];
            [[command execute:indexValue]
             subscribeNext:^(NSNumber * indexValue) {
                 [arrayOutput addObject:indexValue];
             }];
            if (i == 4) {
                [command cancelExecution];
            }
        }
        
        // Output: 1-10
        expect(arrayOutput).withTimeout(2).toEventually(equal(arrayInput));
    });
});

QuickSpecEnd
