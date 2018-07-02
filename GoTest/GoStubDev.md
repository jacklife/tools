#GoStub框架二次开发实践
##序言

要写出好的测试代码，必须精通相关的测试框架。对于Golang的程序员来说，至少需要掌握下面四个测试框架：
```
GoConvey
GoStub
GoMock
Monkey
```
通过上一篇文章《GoStub框架使用指南》的学习，大家熟悉了GoStub框架的基本使用方法，可以优雅的对全局变量、函数或过程打桩，提高了单元测试水平。

尽管GoStub框架已经解决了很多场景的函数打桩问题，但对于一些复杂的情况，却只能干瞪眼：

被测函数中多次调用了数据库读操作函数接口 ReadDb，并且数据库为key-value型。被测函数先是 ReadDb 了一个父目录的值，然后在 for 循环中读了若干个子目录的值。在多个测试用例中都有将ReadDb打桩为在多次调用中呈现不同行为的需求，即父目录的值不同于子目录的值，并且子目录的值也互不相等

被测函数中有一个循环，用于一个批量操作，当某一次操作失败，则返回失败，并进行错误处理。假设该操作为Apply，则在异常的测试用例中有将Apply打桩为在多次调用中呈现不同行为的需求，即Apply的前几次调用返回成功但最后一次调用却返回失败

被测函数中多次调用了同一底层操作函数，比如 exec.Command，函数参数既有命令也有命令参数。被测函数先是创建了一个对象，然后查询对象的状态，在对象状态达不到期望时还要删除对象，其中查询对象是一个重要的操作，一般会进行多次重试。在多个测试用例中都有将 exec.Command 打桩为多次调用中呈现不同行为的需求，即创建对象、查询对象状态和删除对象对返回值的期望都不一样

...

针对GoStub框架不适用的复杂情况，本文将对该框架进行二次开发，优雅的变不适用为适用，提高GoStub框架的适应能力。

##接口

根据开闭原则，我们通过新增接口来应对复杂情况，那么应该增加两个接口：

函数接口
方法接口
对于复杂情况，都是针对一个函数的多次调用而产生不同的行为，即存在多个返回值列表。显然用户打桩时应该指定一个数组切片[]Output，那么数组切片的元素Output应该是什么呢？

每一个函数的返回值列表的大小不是确定的，且返回值类型也不统一，所以Output本身也是一个数组切片，Output的元素是interface{}。

于是Output有了下面的定义：

type Output []interface{}
对于函数接口的声明如下所示：

func StubFuncSeq(funcVarToStub interface{}, outputs []Output) *Stubs
对于方法接口的声明如下所示：

func (s *Stubs) StubFuncSeq(funcVarToStub interface{}, outputs []Output) *Stubs
但还存在下面两种情况：

当被打桩函数在批量操作的场景下，即前面几次都返回成功而最后一次却返回失败，outputs中存在多个相邻的值是一样的
当被打桩函数在重试调用的场景下，即被打桩函数在前面几次都返回失败而最后一次却返回成功，outputs中存在多个相邻的值是一样的
重复是万恶之源，我们保持零容忍，所以引入Times变量到Output中，于是Output的定义就演进为：
于是Output有了下面的定义：
```
type Values []interface{}
type Output struct {
    StubVals Values
    Times int
}
```
##接口使用

###场景一：多次读数据库

假设我们在一个函数f中读了3次数据库，比如调用了3次函数ReadLeaf，即通过3个不同的url读取了3个不同的value。ReadLeaf在db包中定义，示例如下：

var ReadLeaf = func(url string)(string, error) {
    ...
}
假设对该函数打桩之前还未生成stubs对象，覆盖3次读数据库的场景的打桩代码如下：
```
info1 := "..."
info2 := "..."
info3 := "..."
outputs := []Output{
    Output{StubVals: Values{info1, nil}},
    Output{StubVals: Values{info2, nil}},
    Output{StubVals: Values{info3, nil}},
}
stubs := StubFuncSeq(&db.ReadLeaf, outputs)
defer stubs.Reset()
```
...
说明：不指定Times时，Times的值为1

###场景二：批量操作

假设我们在一个函数f中进行批量操作，比如在一个循环中调用了5次Apply函数，前4次操作都成功但第5次操作却失败了。Apply在resource包中定义，示例如下：

var Apply = func(id string) error {
    ...
｝
假设对该函数打桩之前已经生成了stubs对象，覆盖前4次Apply都成功但第5次Apply却失败的场景的打桩代码如下：
```
info1 := "..."
info2 := ""
info3 := "..."
outputs := []Output{
    Output{StubVals: Values{nil}, Times: 4},
    Output{StubVals: Values{ErrAny}},
}
stubs.StubFuncSeq(&resource.Apply, outputs)
...
```
###场景三：底层操作有重试

假设我们在一个函数f中调用了3次底层操作函数，比如调用了3次Command函数，即第一次调用创建对象，第二次调用查询对象的状态，在状态达不到期望的情况下第三次掉用删除对象，其中第二次调用时为了提高正确性，进行了10次尝试。Command在exec包中定义，属于库函数，我们不能直接打桩，所以要在适配层adapter包中进行二次封装：
```
var Command = func(cmd string, arg ...string)(string, error) {
    ...
｝
```
假设对该函数打桩之前已经生成了stubs对象，覆盖前9次尝试失败且第10次尝试成功的场景的打桩代码如下：
```
info1 := "..."
info2 := ""
info3 := "..."
outputs := []Output{
    Output{StubVals: Values{info1, nil}},
    Output{StubVals: Values{info2, ErrAny}, Times: 9},
    Output{StubVals: Values{info3, nil}},
}
stubs.StubFuncSeq(&adapter.Command, outputs)
...
```
##接口实现

###函数接口实现

函数接口的实现很简单，直接委托方法接口实现：
```
func StubFuncSeq(funcVarToStub interface{}, outputs []Output) *Stubs {
    return New().StubFuncSeq(funcVarToStub, outputs)
}
```
提供函数接口的目的是，在Stubs对象生成之前就可以使用该接口。

###方法接口实现

我们回顾一下方法接口的声明：

func (s *Stubs) StubFuncSeq(funcVarToStub interface{}, outputs []Output) *Stubs
方法接口的实现相对比较复杂，需要借助反射和闭包这两个强大的功能。

为了便于实现，我们分而治之，先进行to do list的拆分：

入参校验。（1）funcVarToStub必须为指向函数的指针变量；（2）函数返回值列表的大小必须和Output.StubVals切片的长度相等
将outputs中的Times变量都消除，转化成一个纯的多组返回值列表，即切片[]Values，设切片变量为slice
构造一个闭包函数，自由变量为i，i的值为［0, len(slice) － 1]，闭包函数的返回值列表为slice[i]
将待打桩函数替换为闭包函数
入参校验

入参校验的代码参考了StubFunc方法的实现，如下所示：
```
funcPtrType := reflect.TypeOf(funcVarToStub)
if funcPtrType.Kind() != reflect.Ptr ||
    funcPtrType.Elem().Kind() != reflect.Func {
    panic("func variable to stub must be a pointer to a function")
}

funcType := funcPtrType.Elem()
if funcType.NumOut() != len(outputs[0].StubVals) {
    panic(fmt.Sprintf("func type has %v return values, but only %v stub values provided", funcType.NumOut(), len(outputs[0].StubVals)))
}
```
构造slice

构造slice的代码很简单，如下所示：
```
slice := make([]Values, 0)
for _, output := range outputs {
    t := 0
    if output.Times <= 1 {
        t = 1
    } else {
        t = output.Times
    }
    for j := 0; j < t; j++ {
        slice = append(slice, output.StubVals)
    }
}
```
说明：当Times的值小于等于1时，就按1次记录，否则按实际次数记录。这是一个特殊处理，目的是用户在构造Output时，一般不需要显式的给Times赋值，除非有多次，这样就提高了GoStub框架的易用性。

生成闭包

生成闭包的代码实现中调用了新封装的函数getResultValues，如下所示：
```
i := 0
len := len(slice)
stubVal := reflect.MakeFunc(funcType, func(_ []reflect.Value) []reflect.Value {
    if i < len {
        i++
        return getResultValues(funcPtrType.Elem(), slice[i - 1]...)
    }
    panic("output seq is less than call seq!")
})
```
新封装的函数getResultValues的实现参考了StubFunc方法的实现，如下所示：
```
func getResultValues(funcType reflect.Type, results ...interface{}) []reflect.Value {
    var resultValues []reflect.Value
    for i, r := range results {
        var retValue reflect.Value
        if r == nil {
            retValue = reflect.Zero(funcType.Out(i))
        } else {
            tempV := reflect.New(funcType.Out(i))
            tempV.Elem().Set(reflect.ValueOf(r))
            retValue = tempV.Elem()
        }
        resultValues = append(resultValues, retValue)
    }
    return resultValues
}
```
说明：StubFuncSeq要求len(slice)必须大于等于桩函数的调用次数，否则会显式panic，并有异常日志"output seq is less than call seq!"。

将待打桩函数替换为闭包

这里直接复用既有的变量打桩方法Stub即可实现，如下所示：

return s.Stub(funcVarToStub, stubVal.Interface())
至此，StubFuncSeq方法实现完了，oh yeah!

反模式

多个测试用例的桩函数绑定在一起

通过上一篇文章《GoStub框架使用指南》的学习，读者会写出诸如下面的测试代码：
```
func TestFuncDemo(t *testing.T) {
    Convey("TestFuncDemo", t, func() {
        Convey("for succ", func() {
            var liLei = `{"name":"LiLei", "age":"21"}`
            stubs := StubFunc(&adapter.Marshal, []byte(liLei), nil)
            defer stubs.Reset()
            //several So assert
        })

        Convey("for fail", func() {
            stubs := StubFunc(&adapter.Marshal, nil, ERR_ANY)
            //several So assert
        })

    })
}
```
GoStub框架有了StubFuncSeq接口后，有些读者就会将上面的测试代码写成下面的反模式：
```
func TestFuncDemo(t *testing.T) {
    Convey("TestFuncDemo", t, func() {
        var liLei = `{"name":"LiLei", "age":"21"}`
        outputs := []Output{
            Output{StubVals: Values{[]byte(liLei), nil}},
            Output{StubVals: Values{ErrAny, nil}},
        }
        stubs := StubFuncSeq(&adapter.Marshal, outputs)
        defer stubs.Reset()

        Convey("for succ", func() {
            //several So assert
        })

        Convey("for fail", func() {
            //several So assert
        })

    })
}
```
有的读者可能认为上面的测试代码更好，但一般情况下，一个测试函数有多个测试用例，即第二级的Convey数（5个左右很常见）。如果将所有测试用例的桩函数都写在一起，将非常复杂，而且很多时候会超过人脑的掌握极限，所以笔者将这种模式称为反模式。

我们提倡每个用例管理自己的桩函数，即分离关注点。

函数返回值列表都相同仍使用StubFuncSeq接口打桩

显然，StubFuncSeq接口的功能强于StubFunc接口，这就导致有些读者习惯了使用StubFuncSeq接口，而忽略或很少使用StubFunc接口。

假设函数f中有一个循环，可以从数组切片中获取到不同用户的Id，然后根据Id清理该用户的资源。比如总共有3个用户，依次调用resource包中的Clear函数进行资源清理，该函数的示例如下：

var Clear = func(id string) error {
    ...
｝
假设对该函数打桩之前已经生成了stubs对象，覆盖3次都清理成功的场景的打桩代码如下：
```
outputs := []Output{
    Output{StubVals: Values{nil}, Times: 3},
}
stubs.StubFuncSeq(&resource.Clear, outputs)
...
```
这段代码尽管没毛病，但如果函数通过StubFunc接口打桩，则不管桩函数被调用多少次，都会返回唯一的值列表。

我们重构一下代码：

stubs.StubFunc(&resource.Clear, nil)
...
很明显，重构后的代码简单了很多。

可见，当函数返回值列表都相同时仍使用StubFuncSeq接口打桩是一种反模式。我们在给函数打桩时，优先使用StubFunc接口，当且仅当StubFunc接口不满足测试需求时才考虑使用StubFuncSeq接口。

小结

针对GoStub框架不适用的复杂情况，本文对该框架进行了二次开发，包括新增接口StubFuncSeq的定义、使用及实现，优雅的变不适用为适用，提高了GoStub框架的适应能力。本文在最后还提出了StubFuncSeq接口使用的两种反模式，使得读者时刻保持警惕，从而正确的使用GoStub框架。

作者：_张晓龙_
链接：https://www.jianshu.com/p/53a531852619
來源：简书
简书著作权归作者所有，任何形式的转载都请联系作者获得授权并注明出处。
