//
//  ThreadOperation.h
//  ThreadOperation
//
//  Created by 紫冬 on 13-7-20.
//  Copyright (c) 2013年 qsji. All rights reserved.
//

/*
 主要介绍几种创建线程的方式，以及其他对线程的操作
 创建方式：
 1.通过NSThread
      通过NSThread，又有两种方式创建一个线程对象
      第一种：利用alloc方法，创建返回一个线程对象，第二种使用静态方法+ detachNewThreadSelector:toTarget:withObject:创建一个线程，无返回值
 
 2.通过NSObject的performSelectorInBackground方法，创建一个后台线程
      常用方式是[self performSelectorInBackground:<#(SEL)#> withObject:<#(id)#>]
 
 3.通过NSOperation 是一个抽象基类，我们必须使用它的子类。iOS 提供了两种默认实现：NSInvocationOperation 和 NSBlockOperation。
      NSOperation的使用方法：
      NSOperation对象就像java.lang.Runnable接口，就像java.lang.Runnable接口那样，NSOperation类也被设计为可扩展的，而且只有一个需要重写的方法。它就是－(void)main。使用NSOperation的最简单的方式就是把一个NSOperation对象加入到NSOperationQueue队列中，一旦这个对象被加入到队列，队列就开始处理这个对象，直到这个对象的所有操作完成。然后它被队列释放。
      所以使用方法就是，继承NSOperation，重写main方法。获得了一个自定义的线程类，然后创建该线程类的对象，将对象添加到一个NSOperationQueue队列中，让队列来管理这些线程对象。
      关于线程队列：
      线程队列对象最好设计为一个单例，一个应用程序最好只有一个队列，用AppDelegate的静态方法来获取，或者是每一个窗体（viewController）只有一个
      一个NSOperationQueue 操作队列，就相当于一个线程管理器，而非一个线程。因为你可以设置这个线程管理器内可以并行运行的的线程数量等等。
      队列是同时执行这些操作的。幸运的是，如果你想要为队列限制同时只能运行几个操作，你可以使用NSOperationQueue的setMaxConcurrentOperationCount:方法。例如，[queue setMaxConcurrentOperationCount:2];
      通过设置允许同时执行的线程数量，可以提高线程运行的效率
 
 4.通过GCD，Grand Central Dispatch，它提供了一些新的特性，以及运行库来支持多核并行编程，它的关注点更高：如何在多个 cpu 上提升效率。
    在使用GCD 之前，先添加libsystem.dylib动态加载库，在头文件引入#import<dispatch/dispatch.h>，之后就可以程序中使用GCD了
    最重要的是使用它后，即使我们的工作线程在处理很繁重的任务，也能使我们的UI很平滑。
   
   基于C的执行自定义任务机制,dispatch queue 按先进先出的顺序,串行或并发地执行任务.dispatch queue 分以下三种:
 
  下面首先来看GCD的基本使用语句:
 
  dispatch_async(dispatch_queue_t queue, dispatch_block_t block);
  async表明异步运行,block代表的是你要做的事情,queue则是你把任务交给谁来处理了.(除了async,还有sync,delay,本文以async为例).
 
   基本代码结构如下：
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
     // 耗时的操作
   dispatch_async(dispatch_get_main_queue(), ^{
     // 更新界面
   });
   });
 
  示例代码：
  异步下载图片，刷新ui的例子：
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
   NSURL * url = [NSURL URLWithString:@"http://avatar.csdn.net/2/C/D/1_totogo2010.jpg"];
   NSData * data = [[NSData alloc]initWithContentsOfURL:url];
   UIImage *image = [[UIImage alloc]initWithData:data];
   if (data != nil) {
   dispatch_async(dispatch_get_main_queue(), ^{
   self.imageView.image = image;
       });
     }
   });
 
  之所以程序中会用到多线程是因为程序往往会需要读取数据,然后更新UI.为了良好的用户体验,读取数据的操作会倾向于在后台运行,这样以避免阻塞主线程.GCD里就有三种queue来处理.
 
 1. Main queue：
 
 　　顾名思义,运行在主线程,全局可用的串行，由dispatch_get_main_queue获得.和ui相关的就要使用Main Queue.
 
 2.Serial quque(private dispatch queue)
 
   串行调度队列,一次只执行一个任务,直到当前任务完成才开始出列并启动下一个任务
   主要用于对特定资源的同步访问.虽然每个串行queue本身每次只能执行一个任务,但各个串行queue之间是并发执行的
 　　每次运行一个任务,可以添加多个,执行次序FIFO. 通常是指程序员生成的,比如:
 
 NSDate *da = [NSDate date];
 NSString *daStr = [da description];
 constchar*queueName = [daStr UTF8String];
 dispatch_queue_t myQueue = dispatch_queue_create(queueName, NULL);
 
 3. Concurrent queue(global dispatch queue):
 
 并行调度队列,并发执行一个或多个任务,但启动顺序仍是按照添加到queue的顺序启动
 你不能创建并发dispatch queues, 只能使用系统已经定义好了的三个全局并发queues,具体下面说到
 可以同时运行多个任务,每个任务的启动时间是按照加入queue的顺序,结束的顺序依赖各自的任务.使用dispatch_get_global_queue获得.
 
 所以我们可以大致了解使用GCD的框架:
 
 复制代码
 dispatch_async(getDataQueue,^{
 //获取数据,获得一组后,刷新UI.
 dispatch_aysnc (mainQueue, ^{
 //UI的更新需在主线程中进行
 };
 }
 )
 
 相关知识点：
 Dispatch group : 用于监控一组block对象完成
 Dispatch semaphore : 类似于传统的 semaphore (信号量)
 Dispatch Source : 系统事件异步处理机制
 dispatch queue 中的 各个线程,可以通过queue的context指针来共享数据
 
 
 常用实现方式：
 >>>>>>>>GCD的使用方法
 以点击一个按钮，然后显示loading，同时在后台下载一张图片，最后将下载的图片放到UIImageView中显示为例。
 
 //显示loading
 self.indicator.hidden = NO;
 [self.indicator startAnimating];
 //进入异步线程
 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
 //异步下载图片
 NSURL * url = [NSURL URLWithString:@"http://anImageUrl"];
 NSData * data = [NSData dataWithContentsOfURL:url];
 //网络请求之后进入主线程
 dispatch_async(dispatch_get_main_queue(), ^{
 //关闭loading
 [self.indicator stopAnimating];
 self.indicator.hidden = YES;
 if (data) {//显示图片
 self.imageView.image = [UIImage imageWithData:data];
 }
 });
 });
 这样利用GCD可以把关于一个任务的代码都放在一起。而不是像采用第一种方法一样代码到处散落。
 
 
 
 >>>>>>> 利用GCD延迟执行任务的方法
 
 // 延迟2秒执行：
 double delayInSeconds = 2.0;
 dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
 dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
 // code to be executed on the main queue after delay
 });
 
 
 >>>>>>> 创建自己的Queue
 
 dispatch_queue_t custom_queue = dispatch_queue_create(“customQueue”, NULL);
 dispatch_async(custom_queue, ^{
 //doing something in custom_queue
 });
 dispatch_release(custom_queue);
 
 
 >>>>>>> 利用GCD并行多个线程并且等待所有线程结束之后再执行其它任务
 
 dispatch_group_t group = dispatch_group_create();
 dispatch_group_async(group, dispatch_get_global_queue(0,0), ^{
 // 并行执行的线程一
 });
 dispatch_group_async(group, dispatch_get_global_queue(0,0), ^{
 // 并行执行的线程二
 });
 dispatch_group_notify(group, dispatch_get_global_queue(0,0), ^{
 // 汇总结果
 });
 
 //
 
 */

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import "AppDelegate.h"
#import "MyDrinkOperation.h"
#import "MyEatOperation.h"

@interface ThreadOperation : NSObject
{
    UILabel *label;
}

//分别用上面几种方式创建线程

// 1.通过NSThread
-(void)createThreadByNSThread;

// 2.通过NSObject
-(void)createThreadByNSObject;

// 3.通过NSOperation
-(void)createThreadByNSOperation;

// 4.通过子类NSInvocationOperation
-(void)createThreadByNSInvocationOperation;

// 4.通过GCD
-(void)createThreadByGCD;

@end
