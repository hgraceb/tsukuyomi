import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'property.dart';

class LibrariesCheckVisitor extends RecursiveAstVisitor<void> {
  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    // 函数参数最多支持两个位置参数（根据常见代码进行限制）
    assert(node.parameters.parameters.length <= 2, node.parent?.parent?.toSource());
    // 函数参数暂不接受任意命名参数（不是很好做通用的处理）
    assert(node.parameters.parameters.where(($) => $.isNamed).isEmpty, node.parent?.parent?.toSource());
  }
}

bool isLibrariesValid(List<DartLibrary> libraries) {
  for (final library in libraries) {
    parseString(content: library.source).unit.accept(LibrariesCheckVisitor());
  }
  return true;
}
