## 0.0.7
### json 转model


只用一行命令，直接将Json文件转为Dart model类。

## 安装

```
dev_dependencies: 
  json_transform_model: #最新版本
  build_runner: ^1.0.0
  json_serializable: ^2.0.0
```



## 使用

1. 在工程根目录下创建一个名为 "jsons" 的目录;
2. 创建或拷贝json文件到"jsons" 目录中 ;
3. 运行 `pub run json_model` (Dart VM工程)or `flutter packages pub run json_model`(Flutter中) 命令生成Dart model类，生成的文件默认在"lib/models"目录下



## 借鉴json_model生成类文件的功能，在这个基础上把所有的json文件映射到一个文件`JsonConvert`中，对外提供一下api：

```dart
//根据T和给定的字典数据 生成对应的模型
static fromJson<T>(Map<String, dynamic> json){}
//根据T和给定的模型生成 对应的字典
static Map<String, dynamic> toJson<T>() {}
//根据对应的list(json) 批量生成对应的模型数据
static M fromJsonAsT<M>(json){}
```

主要用于在网络请求解析数据的时候提供一个基于泛型的方法，在底层就解析好数据抛给上层来处理。



## 在[`json_model`](https://pub.dev/packages/json_model)的基础上，提供一个JsonConvert文件的一个模板，该模板就是动态生成的，不用修改，

```dart
//模板内容
import '../models/index.dart';

// **************************************************************************
// 动态生成的文件，不要手动去修改
// **************************************************************************

Type typeOf<T>() => T;
class JsonConvert {
  static fromJson<T>(Map<String, dynamic> json) {
    return _getFromJson<T>(typeOf<T>(),T, json);
  }

  static Map<String, dynamic> toJson<T>() {
    return _getToJson<T>(typeOf<T>(), T);
  }

  static _getFromJson<T>(Type type, data, json) {
    switch (type) {
$getFromJson
  }
    return data as T;
  }

  static _getToJson<T>(Type type,data) {
    switch (type) {
$modelToJson
    }
    return data as T;
  }
  //Go back to a single instance by type
  static _fromJsonSingle(String type, json) {
    switch (type) {
$singleJsonToModel
    }
    return null;
  }

  //empty list is returned by type
  static _getListFromType(String type) {
    switch (type) {
$listModel
    }
    return null;
  }

  static M fromJsonAsT<M>(json) {
    String type = M.toString();
    if (json is List && type.contains("List<")) {
      String itemType = type.substring(5, type.length - 1);
      List tempList = _getListFromType(itemType);
      json.forEach((itemJson) {
        tempList
            .add(_fromJsonSingle(type.substring(5, type.length - 1), itemJson));
      });
      return tempList as M;
    } else {
      return _fromJsonSingle(M.toString(), json) as M;
    }
  }
}
  ''';
}
```



## 例子

Json文件: `jsons/user.json`

```
{
  "name":"wendux",
  "father":"$user", //可以通过"$"符号引用其它model类
  "friends":"$[]user", // 可以通过"$[]"来引用数组
  "keywords":"$[]String", // 同上
  "age":20
}
```

生成的Dart model类:

```
import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';

@JsonSerializable()
class User {
    User(this.name,this.father,this.friends,this.keywords);
    
    String name;
    User father;
    List<User> friends;
    List<String> keywords;
    num age;
    
    factory User.fromJson(Map<String,dynamic> json) => _$UserFromJson(json);
    Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

### @JsonKey

您也可以使用[json_annotation](https://pub.dev/packages/json_annotation)包中的“@JsonKey”标注特定的字段。

这个功能在特定场景下非常有用，比如Json文件中有一个字段名为"+1"，由于在转成Dart类后，字段名会被当做变量名，但是在Dart中变量名不能包含“+”，我们可以通过“@JsonKey”来映射变量名；

```
{
  "@JsonKey(ignore: true) dynamic":"md",
  "@JsonKey(name: '+1') int": "loved", //将“+1”映射为“loved”
  "name":"wendux",
  "age":20
}
```

生成文件如下:

```
import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';

@JsonSerializable()
class User {
    User(this.loved,this.name,this.age);
    @JsonKey(name: '+1') int loved;
    String name;
    num age;
    
    factory User.fromJson(Map<String,dynamic> json) => _$UserFromJson(json);
    Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

测试:

```
import 'models/index.dart';

void main() {
  var u = User.fromJson({"name": "Jack", "age": 16, "+1": 20});
  print(u.loved); // 20
}
```

> 关于 `@JsonKey`标注的详细内容请参考[json_annotation](https://pub.dev/packages/json_annotation) 包；

### @Import

另外，提供了一个`@Import `指令，该指令可以在生成的Dart类中导入指定的文件：

```
{
  "@import":"test_dir/profile.dart",
  "@JsonKey(ignore: true) Profile":"profile",
  "name":"wendux",
  "age":20
}
```

生成的Dart类:

```
import 'package:json_annotation/json_annotation.dart';
import 'test_dir/profile.dart';  // 指令生效
part 'user.g.dart';

@JsonSerializable()
class User {
    User(this.profile,this.name,this.age);

    @JsonKey(ignore: true) Profile profile; //file
    String name;
    num age;
    
    factory User.fromJson(Map<String,dynamic> json) => _$UserFromJson(json);
    Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

更完整的示例请移步[这里](https://github.com/flutterchina/json_model/tree/master/example) .

## 命令参数

默认的源json文件目录为根目录下名为 "json" 的目录；可以通过 `src` 参数自定义源json文件目录，例如:

```
pub run json_model src=json_files 
```

默认的生成目录为"lib/models"，同样也可以通过`dist` 参数来自定义输出目录:

```
pub run json_model src=json_files  dist=data # 输出目录为 lib/data
```

> 注意，dist会默认已lib为根目录。

##
