//
//  json_convert
//  flutter_json_to_model
//
//  Created by zhangjiang on 6/4/21 .
//  Copyright © flutter_json_to_model. All rights reserved.

import 'dart:io';
import 'package:path/path.dart' as path;

/// 默认输出目录
const SRC="./jsons"; //JSON 目录
const DIST="lib/models/"; //输出model目录

//定义替换的内容
// const getFromJson = "%{getFromJson}";
// const modelToJson = "%{modelToJson}";
// const singleJsonToModel = "%{singleJsonToModel}";
// const listModel = "%{listModel}";

void walk(String src,String dist) { //遍历JSON目录生成模板
  var srcDire = new Directory(src);
  List<FileSystemEntity> list = srcDire.listSync();
  File file;
  StringBuffer modelToJsonStr = new StringBuffer();
  StringBuffer jsonToModelStr = new StringBuffer();
  StringBuffer signalModelStr = new StringBuffer();
  StringBuffer listModelStr = new StringBuffer();
  StringBuffer indexStr = new StringBuffer();
  list.forEach((f) {
    if (FileSystemEntity.isFileSync(f.path)) {
      file = new File(f.path);
      var paths = path.basename(f.path).split(".");
      String name = paths.first;
      String className = name[0].toUpperCase() + name.substring(1);
      if (paths.last.toLowerCase() != "json" || name.startsWith("_")) return;
      if (name.startsWith("_")) return;
      //设置jsonToModel
      jsonToModelStr.write('    case $className:\r\n');
      jsonToModelStr.write("       return $className.fromJson(json) as T;\r\n");

      //设置modelToJson
      modelToJsonStr.write('    case $className:\r\n');
      modelToJsonStr.write("       return (data as $className).toJson();\r\n");

      //singleModel
      signalModelStr.write("     case '$className':\r\n");
      signalModelStr.write('       return $className.fromJson(json);\r\n');

      //listModel
      listModelStr.write("     case '$className':\r\n");
      listModelStr.write('       return List<$className>.empty();\r\n');

      //添加索引,文件名不用大写
      indexStr.write("export '$name.dart' ; \r\n");
    }
  });
  var content = _getTemplateContent();
  content = replaceContent(content, [jsonToModelStr.toString(),modelToJsonStr.toString(),signalModelStr.toString(),listModelStr.toString()]);
  //将生成的模板输出
  new File("$DIST/JsonConvert.dart").writeAsStringSync(content);
}

String replaceContent(String content,List<Object> params){
  int matchIndex = 0;
  String replace(Match m){
    if (matchIndex < params.length) {
      switch (m[0]){
        case "%s":
          return params[matchIndex++].toString();
      }
    }else{
      throw new Exception("Missing parameter for string format");
    }
    throw new Exception("Invalid format string" + m[0].toString());
  }

  return content.replaceAllMapped('%s', replace);
}


String _getTemplateContent(){
  return '''
import '../models/index.dart';

// **************************************************************************
// 代码生成不要手动修改
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
%s
  }
    return data as T;
  }

  static _getToJson<T>(Type type,data) {
    switch (type) {
%s
    }
    return data as T;
  }
  //Go back to a single instance by type
  static _fromJsonSingle(String type, json) {
    switch (type) {
%s
    }
    return null;
  }

  //empty list is returned by type
  static _getListFromType(String type) {
    switch (type) {
%s
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

void main(){
  walk(SRC,DIST);
}