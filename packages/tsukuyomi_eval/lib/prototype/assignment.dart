import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:tsukuyomi_eval/prototype/print_visitor.dart';

class CompilerAstVisitor extends RecursiveAstVisitor<void> {
  @override
  void visitExpressionStatement(ExpressionStatement node) {
    stdout.writeln('');
    node.accept(PrintVisitor());
    super.visitExpressionStatement(node);
    stdout.writeln('OP_POP');
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    node.target.accept(this);
    for (final section in node.cascadeSections) {
      stdout.writeln('OP_DUPLICATE');
      section.accept(this);
      stdout.writeln('OP_POP');
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    node.target?.accept(this);
    if (node.target is SuperExpression) {
      stdout.writeln('OP_GET_SUPER: ${node.methodName}');
    } else if (node.target != null || node.realTarget != null) {
      stdout.writeln('OP_GET_PROPERTY: ${node.methodName}');
    } else {
      stdout.writeln('OP_GET_VARIABLE: ${node.methodName}');
    }
    stdout.writeln('OP_CALL: ${node.argumentList.arguments.length}');
  }

  @override
  void visitThisExpression(ThisExpression node) {
    stdout.writeln('OP_GET_VARIABLE: $node');
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    stdout.writeln('OP_GET_VARIABLE: this');
    stdout.writeln('OP_GET_VARIABLE: $node');
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    switch (node.leftHandSide) {
      case SimpleIdentifier simpleIdentifier:
        node.rightHandSide.accept(this);
        stdout.writeln('OP_SET_VARIABLE: $simpleIdentifier');
      case PrefixedIdentifier prefixedIdentifier:
        prefixedIdentifier.prefix.accept(this);
        node.rightHandSide.accept(this);
        stdout.writeln('OP_SET_PROPERTY: ${prefixedIdentifier.identifier}');
      case PropertyAccess propertyAccess:
        propertyAccess.target?.accept(this);
        node.rightHandSide.accept(this);
        stdout.writeln('OP_SET_PROPERTY: ${propertyAccess.propertyName}');
      default:
        throw UnimplementedError('(${node.leftHandSide.runtimeType}) ${node.leftHandSide}');
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.target?.accept(this);
    if (node.target is SuperExpression) {
      stdout.writeln('OP_GET_SUPER: ${node.propertyName}');
    } else {
      stdout.writeln('OP_GET_PROPERTY: ${node.propertyName}');
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    stdout.writeln('OP_GET_VARIABLE: ${node.prefix}');
    stdout.writeln('OP_GET_PROPERTY: ${node.identifier}');
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    stdout.writeln('OP_NULL');
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    stdout.writeln('OP_GET_VARIABLE: $node');
  }
}

void main() {
  parseString(content: '''
class Foo {
  void bar() {
    this.toString;
    this.toString();
    this.toString.toString;
    this.toString.toString();
    this.toString().toString();
  }

  void baz() {
    super.toString;
    super.toString();
    super.toString.toString;
    super.toString.toString();
    super.toString().toString();
  }
}

void main() {
  dynamic a;
  a;
  a = null;
  a.b = null;
  a.b.c = null;
  a.b.c.d = null;
  a..b;
  a..b = null;
  a..b..c = null;
  a..b..c..d = null;
  a..b = null..c = null;
  a..b = null..c = null..d = null;
  a();
  a().b;
  a().b = null;
  a()..b = null;
  a()..b().c = null;
}
''').unit.accept(CompilerAstVisitor());
}
