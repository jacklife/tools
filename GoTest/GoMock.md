序言

要写出好的测试代码，必须精通相关的测试框架。对于Golang的程序员来说，至少需要掌握下面四个测试框架：
```
GoConvey
GoStub
GoMock
Monkey
```
读者通过前面三篇文章的学习可以对框架GoConvey和GoStub优雅的组合使用了，本文将接着介绍第三个框架GoMock的使用方法，目的是使得读者掌握框架GoConvey + GoStub + GoMock组合使用的正确姿势，从而提高测试代码的质量。

GoMock是由Golang官方开发维护的测试框架，实现了较为完整的基于interface的Mock功能，能够与Golang内置的testing包良好集成，也能用于其它的测试环境中。GoMock测试框架包含了GoMock包和mockgen工具两部分，其中GoMock包完成对桩对象生命周期的管理，mockgen工具用来生成interface对应的Mock类源文件。

安装

在命令行运行命令：

go get github.com/golang/mock/gomock
运行完后你会发现，在$GOPATH/src目录下有了github.com/golang/mock子目录，且在该子目录下有GoMock包和mockgen工具。

继续运行命令：

cd $GOPATH/src/github.com/golang/mock/mockgen
go build
则在当前目录下生成了一个可执行程序mockgen。

将mockgen程序移动到$GOPATH/bin目录下：

mv mockgen $GOPATH/bin
这时在命令行运行mockgen，如果列出了mockgen的使用方法和例子，则说明mockgen已经安装成功，否则会显示：

-bash: mockgen: command not found
一般是由于没有在环境变量PATH中配置$GOPATH/bin导致。

文档

GoMock框架安装完成后，可以使用go doc命令来获取文档：

go doc github.com/golang/mock/gomock
另外，有一个在线的参考文档，即package gomock。

使用方法

定义一个接口

我们先定义一个打算mock的接口Repository:
```
package db

type Repository interface {
    Create(key string, value []byte) error
    Retrieve(key string) ([]byte, error)
    Update(key string, value []byte) error
    Delete(key string) error
}
```
Repository是领域驱动设计中战术设计的一个元素，用来存储领域对象，一般将对象持久化在数据库中，比如Aerospike，Redis或Etcd等。对于领域层来说，只知道对象在Repository中维护，并不care对象到底在哪持久化，这是基础设施层的职责。微服务在启动时，根据部署参数实例化Repository接口，比如AerospikeRepository，RedisRepository或EtcdRepository。

假设有一个领域对象Movie要进行持久化，则先要通过json.Marshal进行序列化，然后再调用Repository的Create方法来存储。当要根据key（实体Id）查找领域对象时，则先通过Repository的Retrieve方法获得领域对象的字节切片，然后通过json.Unmarshal进行反序列化的到领域对象。当领域对象的数据有变化时，则先要通过json.Marshal进行序列化，然后再调用Repository的Update方法来更新。当领域对象生命周期结束而要消亡时，则直接调用Repository的Delete方法进行删除。

生成mock类文件

这下该mockgen工具登场了。mockgen有两种操作模式：源文件和反射。

源文件模式通过一个包含interface定义的文件生成mock类文件，它通过 -source 标识生效，-imports 和 -aux_files 标识在这种模式下也是有用的。
举例：

mockgen -source=foo.go [other options]
反射模式通过构建一个程序用反射理解接口生成一个mock类文件，它通过两个非标志参数生效：导入路径和用逗号分隔的符号列表（多个interface）。
举例：

mockgen database/sql/driver Conn,Driver
注意：第一个参数是基于GOPATH的相对路径，第二个参数可以为多个interface，并且interface之间只能用逗号分隔，不能有空格。

有一个包含打算Mock的interface的源文件，就可用mockgen命令生成一个mock类的源文件。mockgen支持的选项如下：

-source: 一个文件包含打算mock的接口列表
-destination: 存放mock类代码的文件。如果你没有设置这个选项，代码将被打印到标准输出
-package: 用于指定mock类源文件的包名。如果你没有设置这个选项，则包名由mock_和输入文件的包名级联而成
-aux_files: 参看附加的文件列表是为了解析类似嵌套的定义在不同文件中的interface。指定元素列表以逗号分隔，元素形式为foo=bar/baz.go，其中bar/baz.go是源文件，foo是-source选项指定的源文件用到的包名
在简单的场景下，你将只需使用-source选项。在复杂的情况下，比如一个文件定义了多个interface而你只想对部分interface进行mock，或者interface存在嵌套，这时你需要用反射模式。由于 -destination 选项输入太长，笔者一般不使用该标识符，而使用重定向符号 >，并且mock类代码的输出文件的路径必须是绝对路径。

现在我们运行mockgen命令通过反射模式生成Repository的Mock类源文件：

mockgen infra/db Repository > $GOPATH/src/test/mock/db/mock_repository.go
注意：
输出目录test/mock/db必须提前建好，否则mockgen会运行失败
如果你的工程中的第三方库统一放在vendor目录下，则需要拷贝一份gomock的代码到$GOPATH/src下，gomock的代码即github.com/golang/mock/gomock，这是因为mockgen命令运行时要在这个路径访问gomock
可以在test/mock/db目录下看到mock_repository.go文件已经生成，该文件的代码片段如下：
```
// Automatically generated by MockGen. DO NOT EDIT!
// Source: infra/db (interfaces: Repository)

package mock_db

import (
    gomock "github.com/golang/mock/gomock"
)

// MockRepository is a mock of Repository interface
type MockRepository struct {
    ctrl     *gomock.Controller
    recorder *MockRepositoryMockRecorder
}

// MockRepositoryMockRecorder is the mock recorder for MockRepository
type MockRepositoryMockRecorder struct {
    mock *MockRepository
}

// NewMockRepository creates a new mock instance
func NewMockRepository(ctrl *gomock.Controller) *MockRepository {
    mock := &MockRepository{ctrl: ctrl}
    mock.recorder = &MockRepositoryMockRecorder{mock}
    return mock
}

// EXPECT returns an object that allows the caller to indicate expected use
func (_m *MockRepository) EXPECT() *MockRepositoryMockRecorder {
    return _m.recorder
}

// Create mocks base method
func (_m *MockRepository) Create(_param0 string, _param1 []byte) error {
    ret := _m.ctrl.Call(_m, "Create", _param0, _param1)
    ret0, _ := ret[0].(error)
    return ret0
}

// Create indicates an expected call of Create
func (_mr *MockRepositoryMockRecorder) Create(arg0, arg1 interface{}) *gomock.Call {
    return _mr.mock.ctrl.RecordCall(_mr.mock, "Create", arg0, arg1)
}
...
```
使用mock对象进行打桩测试

mock类源文件生成后，就可以写测试用例了。

导入mock相关的包

mock相关的包包括testing，gmock和mock_db，import包路径：
```
import (
    "testing"
    . "github.com/golang/mock/gomock"
    "test/mock/db"
    ...
)
```
mock控制器

mock控制器通过NewController接口生成，是mock生态系统的顶层控制，它定义了mock对象的作用域和生命周期，以及它们的期望。多个协程同时调用控制器的方法是安全的。
当用例结束后，控制器会检查所有剩余期望的调用是否满足条件。

控制器的代码如下所示：
```
ctrl := NewController(t)
defer ctrl.Finish()
mock对象创建时需要注入控制器，如果有多个mock对象则注入同一个控制器，如下所示：

ctrl := NewController(t)
defer ctrl.Finish()
mockRepo := mock_db.NewMockRepository(ctrl)
mockHttp := mock_api.NewHttpMethod(ctrl)
```
mock对象的行为注入

对于mock对象的行为注入，控制器是通过map来维护的，一个方法对应map的一项。因为一个方法在一个用例中可能调用多次，所以map的值类型是数组切片。当mock对象进行行为注入时，控制器会将行为Add。当该方法被调用时，控制器会将该行为Remove。

假设有这样一个场景：先Retrieve领域对象失败，然后Create领域对象成功，再次Retrieve领域对象就能成功。这个场景对应的mock对象的行为注入代码如下所示：
```
mockRepo.EXPECT().Retrieve(Any()).Return(nil, ErrAny)
mockRepo.EXPECT().Create(Any(), Any()).Return(nil)
mockRepo.EXPECT().Retrieve(Any()).Return(objBytes, nil)
```
objBytes是领域对象的序列化结果，比如：

obj := Movie{...}
objBytes, err := json.Marshal(obj)
...
当批量Create对象时，可以使用Times关键字：

mockRepo.EXPECT().Create(Any(), Any()).Return(nil).Times(5)
当批量Retrieve对象时，需要注入多次mock行为:
```
mockRepo.EXPECT().Retrieve(Any()).Return(objBytes1, nil)
mockRepo.EXPECT().Retrieve(Any()).Return(objBytes2, nil)
mockRepo.EXPECT().Retrieve(Any()).Return(objBytes3, nil)
mockRepo.EXPECT().Retrieve(Any()).Return(objBytes4, nil)
mockRepo.EXPECT().Retrieve(Any()).Return(objBytes5, nil)
```
行为调用的保序

默认情况下，行为调用顺序可以和mock对象行为注入顺序不一致，即不保序。如果要保序，有两种方法：

通过After关键字来实现保序
通过InOrder关键字来实现保序
通过After关键字实现的保序示例代码：
```
retrieveCall := mockRepo.EXPECT().Retrieve(Any()).Return(nil, ErrAny)
createCall := mockRepo.EXPECT().Create(Any(), Any()).Return(nil).After(retrieveCall)
mockRepo.EXPECT().Retrieve(Any()).Return(objBytes, nil).After(createCall)
```
通过InOrder关键字实现的保序示例代码：
```
InOrder(
    mockRepo.EXPECT().Retrieve(Any()).Return(nil, ErrAny)
    mockRepo.EXPECT().Create(Any(), Any()).Return(nil)
    mockRepo.EXPECT().Retrieve(Any()).Return(objBytes, nil)
)
```
可见，通过InOrder关键字实现的保序更简单自然，所以推荐这种方式。其实，关键字InOrder是After的语法糖，源码如下：
```
// InOrder declares that the given calls should occur in order.
func InOrder(calls ...*Call) {
    for i := 1; i < len(calls); i++ {
        calls[i].After(calls[i-1])
    }
}
```
当mock对象行为的注入保序后，如果行为调用的顺序和其不一致，就会触发测试失败。这就是说，对于上面的例子，如果在测试用例执行过程中，Repository的方法的调用顺序如果不是按 Retrieve -> Create -> Retrieve 的顺序进行，则会导致测试失败。

mock对象的注入

mock对象的行为都注入到控制器以后，我们接着要将mock对象注入给interface，使得mock对象在测试中生效。
在使用GoStub框架之前，很多人都使用土方法，比如Set。这种方法有一个缺陷：当测试用例执行完成后，并没有回滚interface到真实对象，有可能会影响其它测试用例的执行。所以，笔者强烈建议大家使用GoStub框架完成mock对象的注入。

stubs := StubFunc(&redisrepo.GetInstance, mockDb)
defer stubs.Reset()
测试Demo

编写测试用例有一些基本原则，我们一起回顾一下：

每个测试用例只关注一个问题，不要写大而全的测试用例
测试用例是黑盒的
测试用例之间彼此独立，每个用例要保证自己的前置和后置完备
测试用例要对产品代码非入侵
...
根据基本原则，我们不要在一个测试函数的多个测试用例之间共享mock控制器，于是就有了下面的Demo:
```
func TestObjDemo(t *testing.T) {
    Convey("test obj demo", t, func() {
        Convey("create obj", func() {
            ctrl := NewController(t)
            defer ctrl.Finish()
            mockRepo := mock_db.NewMockRepository(ctrl)
            mockRepo.EXPECT().Retrieve(Any()).Return(nil, ErrAny)
            mockRepo.EXPECT().Create(Any(), Any()).Return(nil)
            mockRepo.EXPECT().Retrieve(Any()).Return(objBytes, nil)
            stubs := StubFunc(&redisrepo.GetInstance, mockRepo)
            defer stubs.Reset()
            ...
        })

        Convey("bulk create objs", func() {
            ctrl := NewController(t)
            defer ctrl.Finish()
            mockRepo := mock_db.NewMockRepository(ctrl)
            mockRepo.EXPECT().Create(Any(), Any()).Return(nil).Times(5)
            stubs := StubFunc(&redisrepo.GetInstance, mockRepo)
            defer stubs.Reset()
            ...
        })

        Convey("bulk retrieve objs", func() {
            ctrl := NewController(t)
            defer ctrl.Finish()
            mockRepo := mock_db.NewMockRepository(ctrl)
            objBytes1 := ...
            objBytes2 := ...
            objBytes3 := ...
            objBytes4 := ...
            objBytes5 := ...
            mockRepo.EXPECT().Retrieve(Any()).Return(objBytes1, nil)
            mockRepo.EXPECT().Retrieve(Any()).Return(objBytes2, nil)
            mockRepo.EXPECT().Retrieve(Any()).Return(objBytes3, nil)
            mockRepo.EXPECT().Retrieve(Any()).Return(objBytes4, nil)
            mockRepo.EXPECT().Retrieve(Any()).Return(objBytes5, nil)
            stubs := StubFunc(&redisrepo.GetInstance, mockRepo)
            defer stubs.Reset()
            ...
        })
        ...
    })
}
```
小结

本文详细阐述了GoMock框架的使用方法，不但结合例子给出了标准用法，而且列出了很多要点，最后通过一个简单的测试Demo说明了GoConvey + GoStub + GoMock组合使用的正确姿势。希望读者举一反三，同时将前面三篇的核心内容融入进来，写出高质量的测试代码，最终提升产品质量。

至此，我们已经知道：

全局变量可通过GoStub框架打桩
过程可通过GoStub框架打桩
函数可通过GoStub框架打桩
interface可通过GoMock框架打桩
于是问题来了，方法通过神马打桩？我们将在下一篇文章中给出答案。

作者：_张晓龙_
链接：https://www.jianshu.com/p/f4e773a1b11f
來源：简书
简书著作权归作者所有，任何形式的转载都请联系作者获得授权并注明出处。