//
//  AppDelegate.h
//  ThreadOperation
//
//  Created by 紫冬 on 13-7-20.
//  Copyright (c) 2013年 qsji. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThreadOperation.h"

//最好一个应用程序只有一个线程队列对象，我们可以将它设计为单例，用AppDelegate的静态方法来获取
//或者是每一个窗体（viewController）只有一个

static NSOperationQueue *queue = nil;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

+(NSOperationQueue *)sharedQueue;

@property (strong, nonatomic) UIWindow *window;

@end
