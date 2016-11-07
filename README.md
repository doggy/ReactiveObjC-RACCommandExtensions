# ReactiveObjC-RACCommandExtensions
Provide RACCommand's extensions such as concurrent task but executed in a serial queue.

### Feature

Main idea of `RACSerialCommand` is based on [this repo](https://github.com/haifengkao/RACSerialCommand) and [disscusion on StackOverFlow](http://stackoverflow.com/questions/23382691/building-a-queue-with-rac-idioms)

With those improvements:

* The signal returned by method `execute:` is COMING BACK
* __Cancellation__ Support (cancel tasks in queue)
* Derives from RACCommand which means tons of feature with it
* Test Case with [Quick](https://github.com/quick/quick)

### Usage

Feel free to check the Test Case and press Ctrl+U to run the unit test.

1. Task queue with RACSerialCommand

    ``` objc
    RACSerialCommand * command = [[RACSerialCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        return [[RACSignal.empty
                 delay:0.1]     // do some job
                 concat:[RACSignal
                         return:input]];
        }];
    void (^taskFinished)(NSNumber *) = ^(NSNumber * taskIndex) {
        NSLog(@"value %@", taskIndex);
    };
    [[command execute:@1]
      subscribeNext:taskFinished];
    [[command execute:@2]
      subscribeNext:taskFinished];
    [[command execute:@3]
      subscribeNext:taskFinished];
    ```
    
    The output values is:
    ``` objc
    1
    2
    3
    ```

1. Cancellation with RACSerialCommand

    ``` objc
    [[command execute:@1]
      subscribeNext:taskFinished];
    [[command execute:@2]
      subscribeNext:taskFinished];
    
    [command cancelExecution];  // cancel all previous tasks
    
    [[command execute:@3]
      subscribeNext:taskFinished];
    ```
    
    The output values is:
    ``` objc
    3
    ```

### Installation

1. Source code integration

    Drag & drop two files RACSerialCommand{.h|.m} to your project.

2. Carthage and CocoaPods

    Will be supported.

### Todo

* RACSerialCommand Runloop improvement
    
    Signal running in synchronous should also be cancelled. (It's really a minor issue. Refer last test case pls.)
