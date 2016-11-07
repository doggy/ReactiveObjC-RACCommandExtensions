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
            return [[RACSignal.empty
                     delay:0.1]
                    concat:[RACSignal return:input]];
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
        
        // max default timeout is one second
        expect(arrayInput).withTimeout(1).toEventually(equal(arrayOutput));
    });
    
    qck_it(@"should dispose all previous executing after calling cancelExecution", ^{
        NSMutableArray<NSNumber *> * arrayInput = NSMutableArray.new;
        NSMutableArray<NSNumber *> * arrayOutput = NSMutableArray.new;
        
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
        
        // max default timeout is one second
        expect(arrayInput).withTimeout(1).toEventually(equal(arrayOutput));
    });
});

QuickSpecEnd
