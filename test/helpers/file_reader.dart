import 'dart:convert';
import 'dart:io';

Future<String> readFile(String fileName) async {
  final file = File(fileName);
  return file.readAsString();
}

Future<Object> readJson(String fileName) async {
  final content = await readFile(fileName);
  return stringToJson(content);
}

Object stringToJson(String content) {
  return json.decode(content) as Object;
}
