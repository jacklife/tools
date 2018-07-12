
引言
学习过Java的同学应该知道，CountDownLatch是一个同步辅助类，在完成一组正在其他线程中执行的操作之前，它允许一个或多个线程一直等待，在Java中经常使用，
go语言中也有类似于 CountDownLatch的工具，sync.WaitGroup。

使用方法

    var wg = &sync.WaitGroup{}  //定义
	var processor = 2            //定义协程数
	runtime.GOMAXPROCS(processor) //GOMAXPROCS sets the maximum number of CPUs that can be executing simultaneously
	wg.Add(processor)           //协程数
	go func() {                
		defer wg.Done()         //起一个协程，然后wg.Done,类似 countDownLatch.countDown()
        ...
		...
	}()
	
	go func() {                
		defer wg.Done()         //起一个协程，然后wg.Done,类似 countDownLatch.countDown()
        ...
		...
	}()
	
	wg.Wait()   //等待协程运行结束后再执行后面的程序
	...

下面是一个具体的小例子：
"github.com/robfig/cron"是一个定时任务的工具
package main

import (
	"fmt"
	"github.com/robfig/cron"
	"runtime"
	"sync"
	"time"
)

type testJob struct {
}

func (t testJob) Run() {
	fmt.Println("hello world")
}

func init() {
	c := cron.New()
	c.AddJob("0 */1 * * * ?", testJob{})  // 定时任务，每一分钟执行一次
	c.Start()
}

func main() {
	var wg = &sync.WaitGroup{}
	var processor = 2
	runtime.GOMAXPROCS(processor)
	wg.Add(processor)
	//起一个协程，sleep 2分钟之后打印
	go func() {
		defer wg.Done()
		time.Sleep(2 * time.Minute)
		fmt.Println("I am a goroutine")
	}()
	//另起一个协程，直接打印
	go func() {
		defer wg.Done()
		fmt.Println("I am another goroutine")
	}()
    
	wg.Wait()  //等2个协程结束之后，再运行主程序，打印end

	fmt.Println("end")
}

