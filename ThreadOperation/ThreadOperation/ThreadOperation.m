//
//  ThreadOperation.m
//  ThreadOperation
//
//  Created by 紫冬 on 13-7-20.
//  Copyright (c) 2013年 qsji. All rights reserved.
//

#import "ThreadOperation.h"

@implementation ThreadOperation

/*
 首先讲解一下创建线程的方式
 */

// 1.通过NSThread
-(void)createThreadByNSThread
{
    //第一种，用alloc创建一个线程对象
    NSThread *myThread = [[NSThread alloc] initWithTarget:self selector:@selector(execute) object:nil];
    [myThread start];
    
    //第一种方法，不返回线程对象，直接创建一个线程开始执行execute方法
    [NSThread detachNewThreadSelector:@selector(execute) toTarget:self withObject:nil];
    
    //NSThread对象的其他操作，比如取消，退出
    [myThread cancel];    //取消以后，并不意味立即就退出，仅仅是将线程标识为取消状态
    [NSThread exit];      //退出线程是一个类方法，表示将当前线程退出；
    
    //设置线程优先级
    [myThread setThreadPriority:1];
    
    //设置线程休眠时间
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0f]];//暂停一秒，也即是阻塞一秒钟
    
    //设置当前方法的线程休眠2秒钟
    [NSThread sleepForTimeInterval:2.0f];   //每个2秒钟执行一次线程，也即是
    
    //休眠
    sleep(2.0f);         //这个也表示将当前线程休眠2秒钟，但是和上面区别在于，sleep表示方法执行完了以后在休眠2秒钟，上面的表示当前方法的线程执行到该语句就开始休眠2秒钟，2秒钟以后再接着执行该方法下面的语句
    
    //如果继承NSThread，那么子类就要重写NSThread的main方法
}

// 2.通过NSObject
-(void)createThreadByNSObject
{
    //通过NSObject的performSelectorInBackground方法，在后台创建一个线程，开始执行我们指定的方法
    //因为该类ThreadOperation是继承自NSObject的，所以直接调用该方法
    [self performSelectorInBackground:@selector(execute) withObject:nil];
}

// 3.通过NSOperation
-(void)createThreadByNSOperation
{
    //我们分别继承NSOperation抽象类，定义了喝水MyDrinkOperation类和吃饭MyEatOperation类
    //操作步骤：
    /*
     第一步：继承NSOperation，定义我们需要完成行为的子类
     第二步：创建线程队列NSOperationQueue对象
     第三步：创建线程类对象
     第四步：将线程类对象添加到线程队列中
     */
    
    //创建线程队列对象
    //一个应用程序最好只有一个线程队列对象，是单例模式
    
    //创建线程对象
    MyDrinkOperation *myDrinkOperation = [[MyDrinkOperation alloc] init];   //创建喝水线程对象
    MyEatOperation *myEatOperation = [[MyEatOperation alloc] init];         //创建吃饭线程对象
    
    //将线程对象加入到队列中
    [[AppDelegate sharedQueue] addOperation:myDrinkOperation];
    [[AppDelegate sharedQueue] addOperation:myEatOperation];
    
    [myDrinkOperation release];
    myDrinkOperation = nil;
    [myEatOperation release];
    myEatOperation = nil;
    
}

// 3.通过NSInvocationOperation
-(void)createThreadByNSInvocationOperation
{
    //使用步骤
    /*
     第一步：创建一个NSInvocationOperation对象，并初始化到方法
     第二步：selector参数后的值是你想在另外一个线程中运行的方法（函数，Method）
     第三步：在这里，object后的值是想传递给前面方法的数据
     */
    NSInvocationOperation* invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                        selector:@selector(execute) object:nil];
    [[AppDelegate sharedQueue] addOperation:invocationOperation];
}

// 5.通过GCD
-(void)createThreadByGCD
{
    /*
     全局并发 Dispatch queue
     1. 并发 dispatch queue 可以同时并发执行多个任务,不过并发 queue 仍然按照先进先出的顺序启动任务
     2. 并发 queue 同时执行的任务数量会根据应用和系统动态变化,各个因素如:可用核数量  其他进程正在执行的工作数量 其他串行dispatch queue 中的优先任务的数量等
     3. 系统会给每个应用程序提供三个并发 dispatch queue,全局共享,三个queue的唯一区别在于优先级不同
     */
    
    /*
           获取全局并发 dispatch queue : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
           第一个参数表示 queue 的优先级,这里获取默认优先级的那个queue,也可以获取高/低优先级的那个,把 DEFAULT 换成 HIGH 或 LOW 就行了
           第二个参数表示 ?
    */
    
    //首先利用dispatch_get_global_queue获取一个global queue
    dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //然后把一个block加入到全局并发调度队列里
    dispatch_async(aQueue, ^(void) {
        for (int i = 0; i < 1000; i++) {
            //把block同步添加到主线程里,这样子,demo queue 就会暂停等这个block执行完成才继续执行
            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                NSString *text = [NSString stringWithFormat:@"%d", i];
                label.text = text;
                });
            }

        });

    //然后把另一个block加入到全局并发调度队列里.这个block和上面那个block会并发执行
    dispatch_async(aQueue, ^(void){
    for (int i = 0; i < 5000; i++) {
            //把block同步添加到主线程里,这样子,demo queue 就会暂停等这个block执行完成才继续执行
            dispatch_sync(dispatch_get_main_queue(), ^(void) {             
                NSString *text = [NSString stringWithFormat:@"%d", i];
                label.text = text;
                });
            }        
        });
    
    
    /*
     串行 Dispatch queue
     1. 串行 queue 每次只能执行一个任务,可以使用它来代替锁,保护共享资源或可变的数据结构,串行queue确保任务按可预测的顺序执行(这是比锁好的地方)
     2. 必须显式创建和管理所有你使用的串行queue(数目任意)
     */

     /*
        使用 dispatch_queue_create() 方法来创建串行queue
        第一个参数表示 queue 的名字, 第二个参数表示 queue 的一组属性(保留给将来使用)
        */
        //首先利用函数dispatch_queue_create创建一个串行队列  serial_queue，需要释放的
        dispatch_queue_t serial_queue = dispatch_queue_create("demo queue", NULL);
        /*
         异步调度和同步调度
         异步调度 dispatch_async : 把一个任务添加到某queue后就马上离开,而不管任务在那个queue里的执行状态
         同步调度 dispatch_sync : 把一个任务添加到某queue后,等这个任务完成,调用线程才继续执行.尼玛,坑爹啊
         所以,异步调度和同步调度的区别不在于被添加的任务怎样执行,而在于调用线程是否等待任务执行完
         */

        //然后把block异步添加到上面创建的名为 serial_queue 的调度队列里
        dispatch_async(serial_queue, ^(void){
            for (int i = 0; i < 1000; i++) {
                //   sleep(1);
                //  printf("a%d\t",i);
                //把block同步添加到主线程里,这样子,demo queue 就会暂停等这个block执行完成才继续执行
                dispatch_sync(dispatch_get_main_queue(), ^(void) {
                    NSString *text = [NSString stringWithFormat:@"%d", i];
                    label.text = text;
                    // printf("b%d\n",i);
                    });

                }
            });    
        //然后再把这个block任务添加进入到这个串行队列里，因为 serial_queue 是串行调度队列,所以等上面那个block执行完,下面这个block才会开始
        dispatch_async(serial_queue, ^(void){        
            for (int i = 0; i < 5000; i++) {
                dispatch_sync(dispatch_get_main_queue(), ^(void) {                
                     label.text = [NSString stringWithFormat:@"%d", i];
                    });
                } 
            });
    
        //释放该串行队列，xxxxx_create 的object对象要对应 xxxxx_release
        dispatch_release(serial_queue);
    
    
    /*
     dispatch_group 可以把一组task放到一个group里,等group里的所有task都执行完后再继续运行
     */
        //重置label2的text
        label.text = @"begin";
        //获取一个全局并发 调度队列
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        //创建一个 dispatch group
        dispatch_group_t group = dispatch_group_create();
        //定义 task1
        dispatch_block_t task1 = ^(void){
            for (int i = 0; i < 300; i++) {
                dispatch_sync(dispatch_get_main_queue(), ^(void){
                    label.text = [NSString stringWithFormat:@"%d", i];
                    });
                }
            };
        //定义task2
        dispatch_block_t task2 = ^(void){
            for (int i = 0; i < 600; i++) {
                dispatch_sync(dispatch_get_main_queue(), ^(void){
                    label.text = [NSString stringWithFormat:@"%d", i];
                    });
                }
            };
        //把task1关联到 queue 和group
        dispatch_group_async(group, queue, task1);   
        //把task2关联到 queue和group
        dispatch_group_async(group, queue, task2);
    
        //等group里的task都执行完后执行notify方法里的内容,相当于把wait方法及之后要执行的代码合到一起了
        dispatch_group_notify(group, dispatch_get_main_queue(), ^(void){       
            label.text = @"done!";
            });
    
        //XXX_create创建,就需要对应的 XXX_release()
        dispatch_release(group);
    
    
}


//线程启动后，要执行的方法
-(void)execute
{
    while (true)
    {
        //......
        //......
        [NSThread sleepForTimeInterval:2.0f];
        NSLog(@"线程执行了该方法");
    }
    
}

@end
    
    
