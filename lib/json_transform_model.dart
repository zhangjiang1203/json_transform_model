//
//  json_model
//  flutter_json_to_model
//
//  Created by zhangjiang on 6/3/21 .
//  Copyright © flutter_json_to_model. All rights reserved.

//定义对应的模型文件路径解析，展示和对应的工具
import 'dart:convert';
import 'dart:io';
import 'json_convert_genericity.dart';
import 'package:path/path.dart' as path;
import 'src/build_runner.dart' as build;
import 'json_convert_genericity.dart' as convert;
import 'package:args/args.dart';

const SRC="./jsons"; //JSON 目录
const Dire="lib/models/";
const tpl='''

// **************************************************************************
// 自动生成代码，不要手动修改
  /*
                           _ooOoo_
                          o8888888o
                          88" . "88
                          (| -_- |)
                          O  =  /O
                       ____/`---'____
                     .'  |     |//  `.
                    /  |||  :  |||//  
                   /  _||||| -:- |||||-  
                   |   |   -  /// |   |
                   | _|  ''---/''  |   |
                     .-__  `-`  ___/-. /
                 ___`. .'  /--.--  `. . __
              ."" '<  `.____<|>_/___.'  >'"".
             | | :  `- `.;` _ /`;.`/ - ` : | |
                `-.   _ __ /__ _/   .-` /  /
        ======`-.____`-.________/___.-`____.-'======
                           `=---='
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                 佛祖保佑       永无BUG
* 佛曰:

* 写字楼里写字间，写字间里程序员；

* 程序人员写程序，又拿程序换酒钱。

* 酒醒只在网上坐，酒醉还来网下眠；

* 酒醉酒醒日复日，网上网下年复年。

* 但愿老死电脑间，不愿鞠躬老板前；

* 奔驰宝马贵者趣，公交自行程序员。

* 别人笑我忒疯癫，我笑自己命太贱；

* 不见满街漂亮妹，哪个归得程序员？
// **************************************************************************

import 'package:json_annotation/json_annotation.dart';
%t

part '%s.g.dart';

@JsonSerializable()
class %s {
    %s(
%s
    );
    
    %s
    
    factory %s.fromJson(Map<String,dynamic> json) => _\$%sFromJson(json);
    Map<String, dynamic> toJson() => _\$%sToJson(this);
}
''';

main(List<String> args){
  run(args);
}

void run(List<String> args){
  String src = SRC;
  String dist = DIST;
  String tag = '\$';
  var parser = new ArgParser();
  parser.addOption('src', defaultsTo: src, callback: (v) => src = v!, help: "Specify the json directory.");
  parser.addOption('dist', defaultsTo: dist, callback: (v) => dist = v!, help: "Specify the dist directory.");
  parser.addOption('tag', defaultsTo: tag, callback: (v) => tag = v!, help: "Specify the tag ");
  parser.parse(args);
  if (walk(src,dist,tag)) {
    //生成jsonConvert文件
    convert.walk(src,dist);
    print("开始生成对应的 .g.dart文件");
    build.run(['build','--delete-conflicting-outputs']);
    print("生成对应的 .g.dart文件完成");
  }
}


//遍历JSON目录生成模板
bool walk(String srcDir, String distDir,String tag) {
  if(srcDir.endsWith("/")) srcDir=srcDir.substring(0, srcDir.length-1);
  if(distDir.endsWith("/")) distDir=distDir.substring(0, distDir.length-1);
  var src = Directory(srcDir);
  var list = src.listSync(recursive: true);
  String indexFile = "";
  if(list.isEmpty) return false;
  if(!Directory(distDir).existsSync()){
    Directory(distDir).createSync(recursive: true);
  }

  print("开始生成对应的JsonSerializable模板");
  File file;
  list.forEach((f) {
    if (FileSystemEntity.isFileSync(f.path)) {
      file = File(f.path);
      var paths = path.basename(f.path).split(".");
      String name = paths.first;
      if(paths.last.toLowerCase()!= "json"||name.startsWith("_")) return ;
      if(name.startsWith("_")) return;
      //下面生成模板
      var map = json.decode(file.readAsStringSync());
      //为了避免重复导入相同的包，我们用Set来保存生成的import语句。
      var set = new Set<String>();
      StringBuffer attrs= new StringBuffer();
      StringBuffer initAttrs = new StringBuffer();
      (map as Map<String, dynamic>).forEach((key, v) {
        if(key.startsWith("_")) return ;
        if(key.startsWith("@")){
          if(key.startsWith("@import")){
            set.add(key.substring(1)+" '$v'");
            return;
          }
          attrs.write(key);
          attrs.write(" ");
          attrs.write(v);
          attrs.writeln(";");
          //设置对应的属性
          initAttrs.write("        this."+key+",\r\n");
        }else {
          attrs.write(getType(v, set, name, tag));
          attrs.write(" ");
          attrs.write(key);
          attrs.writeln(";");

          initAttrs.write("        this."+key+",\r\n");
        }
        attrs.write("    ");
      });
      String className=name[0].toUpperCase()+name.substring(1);
      //替换文本
      var dist = format(tpl,[name,className,className,initAttrs.toString(),attrs.toString(),
        className,className,className]);

      var _import = set.join(";\r\n");
      _import += _import.isEmpty?"":";";
      dist = dist.replaceFirst("%t",_import );
      //将生成的模板输出
      var p = f.path.replaceFirst(srcDir, distDir).replaceFirst(".json", ".dart");
      //写入文件中
      File(p)..createSync(recursive: true)..writeAsStringSync(dist);
      var relative = p.replaceFirst(distDir+path.separator, "");
      indexFile += "export '$relative' ; \n";
    }
  });
  if(indexFile.isNotEmpty) {
    File(path.join(distDir, "index.dart")).writeAsStringSync(indexFile);
  }

  print("JsonSerializable模板生成完毕");
  return indexFile.isNotEmpty;
}


String changeFirstChar(String str, [bool upper=true] ){
  return (upper?str[0].toUpperCase():str[0].toLowerCase()) + str.substring(1);
}

bool isBuiltInType(String type){
  return ['int','num','string','double','map','list'].contains(type);
}

//将JSON类型转为对应的dart类型
String getType(v,Set<String> set,String current, tag){
  current = current.toLowerCase();
  if(v is bool){
    return "bool?";
  }else if(v is num){
    return "num?";
  }else if(v is Map){
    return "Map<String,dynamic>?";
  }else if(v is List){
    return "List?";
  }else if(v is String){ //处理特殊标志
    if(v.startsWith("$tag[]")){
      var type = changeFirstChar(v.substring(3),false);
      if(type.toLowerCase() != current&&!isBuiltInType(type)) {
        set.add('import "$type.dart"');
      }
      return "List<${changeFirstChar(type)}>?";

    }else if(v.startsWith(tag)){
      var fileName = changeFirstChar(v.substring(1),false);
      if(fileName.toLowerCase()!= current) {
        set.add('import "$fileName.dart"');
      }
      return changeFirstChar(fileName);
    }else if(v.startsWith("@")){
      return v;
    }
    return "String?";
  }else{
    return "String?";
  }
}

// String getDefaultValueByType(String type,String className){
//   if (type == 'bool') {
//     return 'false';
//   }else if (type == 'num') {
//     return '0';
//   }else if (type == 'String') {
//     return "\"\"";
//   }else if (type == "List") {
//     return 'List.empty()';
//   }else if (type.contains("Map<")) {
//     return 'Map<String,dynamic>()';
//   }else if (type.contains("List<")) {
//     return 'List.empty()';
//   }
//   return "";
// }

//替换模板占位符
String format(String fmt, List<Object> params) {
  int matchIndex = 0;
  String replace(Match m) {
    if (matchIndex < params.length) {
      switch (m[0]) {
        case "%s":
          return params[matchIndex++].toString();
      }
    } else {
      throw new Exception("Missing parameter for string format");
    }
    throw new Exception("Invalid format string: " + m[0].toString());
  }
  return fmt.replaceAllMapped("%s", replace);
}
