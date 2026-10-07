import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';

import 'chunk.dart';
import 'constant.dart';
import 'debug.dart';
import 'error.dart';
import 'object.dart';
import 'ops.dart';
import 'stack.dart';
import 'visitor.dart';

typedef _AssignmentTarget = ({int operandCount, void Function() read, void Function() write});

extension on ClassDeclaration {
  bool get hasUnnamedConstructor {
    return members.whereType<ConstructorDeclaration>().isEmpty;
  }
}

extension on FieldDeclaration {
  ClassDeclaration get parent => this.parent as ClassDeclaration;

  String get className => parent.name.lexeme;
}

extension on MethodDeclaration {
  ClassDeclaration get parent => this.parent as ClassDeclaration;

  String get className => parent.name.lexeme;
}

extension on ClassMemberElement {
  ClassElement get classElement => enclosingElement as ClassElement;
}

extension on PropertyAccessorElement {
  FieldElement? get fieldElement {
    return switch (this) {
      PropertyAccessorElement e when e.variable is FieldElement => e.variable as FieldElement,
      _ => null,
    };
  }
}

extension on CompoundAssignmentExpression {
  FieldElement? get fieldElement {
    return switch (writeElement) {
      PropertyAccessorElement accessor => accessor.fieldElement,
      _ => null,
    };
  }
}

extension on SimpleIdentifier {
  ClassElement? get classElement {
    return switch (staticElement) {
      ClassElement element => element,
      _ => null,
    };
  }

  ClassMemberElement? get classMemberElement {
    // 当父节点为 CompoundAssignmentExpression 时当前节点不会储存 staticElement 信息
    // 如：class Class { int field = 0; int increment() => ++field; }
    return switch (staticElement ?? (parent is CompoundAssignmentExpression ? parent : null)) {
      ClassMemberElement member => member,
      PropertyAccessorElement accessor => accessor.fieldElement,
      CompoundAssignmentExpression assignment => assignment.fieldElement,
      _ => null,
    };
  }
}

extension on Expression {
  ClassElement? get classElement {
    return switch (this) {
      SimpleIdentifier identifier => identifier.classElement,
      _ => null,
    };
  }
}

extension on NullShortableExpression {
  bool get isNullShortable {
    return switch (parent) {
      CascadeExpression() => true,
      CompoundAssignmentExpression node when node.parent is CascadeExpression => true,
      _ => this == nullShortingTermination,
    };
  }
}

extension on FunctionExpression {
  String? get returnType {
    return switch (staticType) {
      FunctionType type => type.returnType.element?.name,
      _ => null,
    };
  }
}

extension on SetOrMapLiteral {
  Iterable<String> get typeArgumentNames {
    return (staticType as InterfaceType).typeArguments.map((e) => e.getDisplayString(withNullability: true));
  }
}

extension on ListLiteral {
  Iterable<String> get typeArgumentNames {
    return (staticType as InterfaceType).typeArguments.map((e) => e.getDisplayString(withNullability: true));
  }
}

typedef _CompilerBody = void Function(_Compiler visitor);

class Local {
  Local({required this.name, required this.depth, this.isCaptured = false}) : assert(depth >= 0);

  int depth;

  bool isCaptured;

  final String name;
}

class Loop {
  Loop({required this.enclosing, required this.loopOffset, required this.scopeDepth, required this.endScope});

  int loopOffset;

  int? conditionOffset;

  final Loop? enclosing;

  final int scopeDepth;

  final Function()? endScope;

  final List<int> breakOffsets = [];

  final List<int> continueOffsets = [];
}

class Trying {
  Trying({required this.enclosing, required this.startOffset, required this.blockOffset});

  int blockOffset;

  final int startOffset;

  final Trying? enclosing;
}

class Shorting {
  Shorting({required this.enclosing});

  final Shorting? enclosing;

  final List<int> offsets = [];
}

class Upvalue {
  Upvalue({required this.index, required this.isLocal});

  final int index;

  final bool isLocal;
}

abstract class Compiler {
  factory Compiler({bool debug = false, required LineInfo debugLineInfo}) {
    return _Compiler(debug: debug, debugLineInfo: debugLineInfo, function: ObjFunction('root', returnType: 'void'));
  }

  ObjFunction compile({required AstNode node});
}

class _Compiler extends CompilerAstVisitor implements Compiler {
  _Compiler({
    bool? hasThis,
    LineInfo? debugLineInfo,
    this.enclosing,
    required this.debug,
    required this.function,
  }) : super(debugLine: enclosing?.debugLine, debugLineInfo: debugLineInfo ?? enclosing!.debugLineInfo) {
    scopeDepth = enclosing != null ? enclosing!.scopeDepth + 1 : 0;
    locals = [Local(name: hasThis == true ? 'this' : '', depth: 0)];
  }

  Loop? loop;

  Trying? trying;

  Shorting? shorting;

  late int scopeDepth;

  late final List<Local> locals;

  final bool debug;

  final ObjFunction function;

  final _Compiler? enclosing;

  final upvalues = Stack<Upvalue>(MAX_UPVALUES);

  Chunk get chunk => function.chunk;

  void error(String message) {
    throw EvalCompileError(message);
  }

  int addConstant(Object? value) {
    return chunk.addConstant(value);
  }

  void emitCodes(int code1, [int? code2]) {
    chunk.addCode(code1, debugLine);
    if (code2 != null) chunk.addCode(code2, debugLine);
  }

  void emitOperator1(String operator) {
    emitCodes(OP_OPERATOR_1, addConstant(operator));
  }

  void emitOperator2(String operator) {
    emitCodes(OP_OPERATOR_2, addConstant(operator));
  }

  void emitOperator3(String operator) {
    emitCodes(OP_OPERATOR_3, addConstant(operator));
  }

  void emitCollectionElement(CollectionElement node, {required bool isMap}) {
    debugUpdateNode(node);
    switch (node) {
      case IfElement():
        if (node.caseClause != null) {
          error("Unsupported 'collection-if' with pattern '${node.caseClause}'.");
        }
        node.expression.accept(this);
        final elseOffset = emitJump(OP_JUMP_IF_FALSE);
        emitCodes(OP_POP);
        emitCollectionElement(node.thenElement, isMap: isMap);
        final exitOffset = emitJump(OP_JUMP);
        patchJump(elseOffset);
        emitCodes(OP_POP);
        if (node.elseElement case CollectionElement element) {
          emitCollectionElement(element, isMap: isMap);
        }
        patchJump(exitOffset);
      case SpreadElement():
        node.expression.accept(this);
        final nullOffset = node.isNullAware ? emitJump(OP_JUMP_IF_NULL) : null;
        emitCodes(OP_COLLECTION_CHECK_SPREAD, isMap ? 1 : 0);
        if (isMap) {
          emitGetProperty('forEach');
          emitCodes(OP_ARGUMENT_LIST, OP_COLLECTION_ENTRY_CALLBACK);
          emitCodes(OP_ARGUMENT_POSITIONAL, OP_CALL);
          emitCodes(OP_POP);
        } else {
          emitGetProperty('iterator');
          final loopOffset = chunk.size;
          emitCodes(OP_PEEK, 0);
          emitGetProperty('moveNext');
          emitCodes(OP_ARGUMENT_LIST, OP_CALL);
          final endOffset = emitJump(OP_JUMP_IF_FALSE);
          emitCodes(OP_POP);
          emitCodes(OP_PEEK, 0);
          emitGetProperty('current');
          // iterator 位于集合上方，加入元素后仍留在栈顶供下一轮使用
          emitCodes(OP_COLLECTION_ADD, 1);
          emitCodes(OP_JUMP, loopOffset - chunk.size - 2);
          patchJump(endOffset);
          emitCodes(OP_POP, OP_POP);
        }
        if (nullOffset != null) {
          final exitOffset = emitJump(OP_JUMP);
          patchJump(nullOffset);
          emitCodes(OP_POP);
          patchJump(exitOffset);
        }
      case MapLiteralEntry():
        node.key.accept(this);
        node.value.accept(this);
        emitCodes(OP_COLLECTION_ADD_ENTRY);
      case Expression():
        node.accept(this);
        emitCodes(OP_COLLECTION_ADD, 0);
      case ForElement():
        node.accept(this);
    }
  }

  void emitSetProperty(String name) {
    emitCodes(OP_SET_PROPERTY, addConstant(name));
  }

  void emitGetProperty(String name, {Expression? target}) {
    if (target is SuperExpression) {
      emitCodes(OP_GET_SUPER, addConstant(name));
    } else {
      emitCodes(OP_GET_PROPERTY, addConstant(name));
    }
  }

  void emitGetClassMember(String name, ClassMemberElement member) {
    if (member.isStatic) {
      assert(member.enclosingElement is ClassElement);
      emitGetVariable('${member.enclosingElement.name!}.$name');
    } else {
      emitGetVariable('this');
      emitGetProperty(name);
    }
  }

  void emitDefineGlobal(String name, {bool isGetter = false, bool isSetter = false}) {
    assert(scopeDepth == 0);
    assert(isGetter == false || isSetter == false);
    if (isGetter) {
      emitCodes(OP_DEFINE_GLOBAL_GETTER, addConstant(name));
    } else if (isSetter) {
      emitCodes(OP_DEFINE_GLOBAL_SETTER, addConstant(name));
    } else {
      emitCodes(OP_DEFINE_GLOBAL, addConstant(name));
    }
  }

  void emitDefineGlobalIfNeeded(String name, {bool isGetter = false, bool isSetter = false}) {
    if (scopeDepth != 0) return;
    emitDefineGlobal(name, isGetter: isGetter, isSetter: isSetter);
  }

  void emitDefineField(String name, FieldDeclaration node) {
    if (node.isStatic) {
      // 定义类的静态字段
      emitDefineGlobal('${node.className}.$name');
    } else {
      emitCodes(OP_CLASS_FIELD, addConstant(name));
    }
  }

  void emitDefineMethod(String name, MethodDeclaration node) {
    assert(node.isGetter == false || node.isSetter == false);
    if (node.isStatic) {
      // 定义类的静态方法
      emitDefineGlobal('${node.className}.$name', isGetter: node.isGetter, isSetter: node.isSetter);
    } else if (node.isGetter) {
      emitCodes(OP_CLASS_GETTER, addConstant(name));
    } else if (node.isSetter) {
      emitCodes(OP_CLASS_SETTER, addConstant(name));
    } else {
      emitCodes(OP_CLASS_METHOD, addConstant(name));
    }
  }

  void emitDefineClosure(String name, {String? returnType, bool? hasThis, _CompilerBody? body}) {
    final function = ObjFunction(name.isNotEmpty ? name : 'anonymous', returnType: returnType ?? 'dynamic');
    final compiler = _Compiler(enclosing: this, function: function, debug: debug, hasThis: hasThis);
    emitCodes(OP_CLOSURE, addConstant(compiler.compile(body: body)));
    for (final upvalue in compiler.upvalues) {
      emitCodes(upvalue.isLocal ? 1 : 0, upvalue.index);
    }
  }

  void emitSetVariable(String name) {
    if (resolveLocal(name) case int index) {
      emitCodes(OP_SET_LOCAL, index);
    } else if (resolveUpvalue(name) case int index) {
      emitCodes(OP_SET_UPVALUE, index);
    } else {
      emitCodes(OP_SET_GLOBAL, addConstant(name));
    }
  }

  void emitGetVariable(String name) {
    if (resolveLocal(name) case int index) {
      emitCodes(OP_GET_LOCAL, index);
    } else if (resolveUpvalue(name) case int index) {
      emitCodes(OP_GET_UPVALUE, index);
    } else {
      emitCodes(OP_GET_GLOBAL, addConstant(name));
    }
  }

  void emitAsyncIfNeeded(FunctionBody node) {
    if (node.isAsynchronous) {
      emitCodes(OP_ASYNC);
    }
  }

  int emitJump(int instruction, [int offset = 0]) {
    emitCodes(instruction, offset);
    return chunk.size - 1;
  }

  void patchJump(int? offset) {
    if (offset == null) return;
    final jump = chunk.size - offset - 1;
    chunk.updateCode(offset, jump);
  }

  int? resolveLocal(String name) {
    for (int i = locals.length - 1; i >= 0; i--) {
      if (locals[i].name == name) return i;
    }
    return null;
  }

  int? resolveUpvalue(String name) {
    if (enclosing == null) return null;

    if (enclosing!.resolveLocal(name) case int index) {
      enclosing!.locals[index].isCaptured = true;
      return addUpvalue(index, true);
    }

    if (enclosing!.resolveUpvalue(name) case int index) {
      return addUpvalue(index, false);
    }

    return null;
  }

  int addUpvalue(int index, bool isLocal) {
    assert(upvalues.size == function.upvalueCount);
    for (int i = 0; i < upvalues.size; i++) {
      final upvalue = upvalues[i];
      if (upvalue.index == index && upvalue.isLocal == isLocal) {
        return i;
      }
    }

    if (upvalues.size >= MAX_UPVALUES) {
      error('Too many closure variables in function.');
    }

    upvalues.push(Upvalue(index: index, isLocal: isLocal));
    return function.upvalueCount++;
  }

  void addLocal(String name) {
    assert(scopeDepth > 0);
    locals.add(Local(name: name, depth: scopeDepth));
  }

  void addLocalIfNeeded(String name) {
    if (scopeDepth == 0) return;
    addLocal(name);
  }

  void addFormalParameters(FormalParameterList? node) {
    for (final parameter in node?.parameters ?? <FormalParameter>[]) {
      addLocal(parameter.name!.lexeme);
    }
  }

  void beginScope() {
    scopeDepth++;
  }

  void endScope() {
    scopeDepth--;
    while (locals.isNotEmpty && locals.last.depth > scopeDepth) {
      emitCodes(locals.removeLast().isCaptured ? OP_CLOSE_UPVALUE : OP_POP);
    }
  }

  int emitExitJump(int depth, [int offset = 0]) {
    // finally 仍可能访问离开作用域的变量，清理延后到实际跳转时
    final localCount = locals.where((local) => local.depth <= depth).length;
    emitCodes(OP_UNWIND_JUMP, localCount);
    emitCodes(offset);
    return chunk.size - 1;
  }

  void beginShorting(NullShortableExpression node) {
    if (node.isNullShortable) {
      shorting = Shorting(enclosing: shorting);
    }
  }

  Expression? targetShorting(Expression? target, bool isNullAware) {
    target?.accept(this);
    // 如果目标节点不存在则不添加判空和跳转指令，避免重复判空，如：foo?..bar..baz
    if (target != null && isNullAware) {
      shorting!.offsets.add(emitJump(OP_JUMP_IF_NULL));
    }
    return target;
  }

  void endShorting(NullShortableExpression node) {
    if (node.isNullShortable) {
      shorting!.offsets.forEach(patchJump);
      shorting = shorting!.enclosing;
    }
  }

  void beginLoop({VariableDeclarationList? declarations, Expression? initialization}) {
    if (declarations != null) {
      beginScope();
      declarations.accept(this);
    }
    if (initialization != null) {
      initialization.accept(this);
      emitCodes(OP_POP);
    }
    loop = Loop(
      enclosing: loop,
      loopOffset: chunk.size,
      scopeDepth: scopeDepth,
      endScope: declarations == null ? null : endScope,
    );
  }

  void conditionLoop(Expression? condition) {
    if (condition == null) return;

    // 如果在 condition 之前已经有解析过 continue 则需要修改跳转位置，如 do-while 循环
    loop!.continueOffsets.forEach(patchJump);

    condition.accept(this);
    loop!.conditionOffset = emitJump(OP_JUMP_IF_FALSE);
    emitCodes(OP_POP);
  }

  int beginForEachLoop(ForEachParts node) {
    beginScope();
    // 先求值 iterable，避免循环变量遮蔽同名的外层变量
    node.iterable.accept(this);
    emitGetProperty('iterator');
    final iteratorOffset = locals.length;
    addLocal('');
    beginLoop();
    emitCodes(OP_GET_LOCAL, iteratorOffset);
    emitGetProperty('moveNext');
    emitCodes(OP_ARGUMENT_LIST, OP_CALL);
    loop!.conditionOffset = emitJump(OP_JUMP_IF_FALSE);
    emitCodes(OP_POP);
    return iteratorOffset;
  }

  void updateLoop(NodeList<Expression> updaters, {int? localOffset}) {
    if (updaters.isEmpty && localOffset == null) return;
    final nextOffset = emitJump(OP_JUMP);
    final loopOffset = chunk.size;
    if (localOffset != null) {
      // 在 updater 前关闭本轮捕获，保留槽位值供下一轮绑定使用
      emitCodes(OP_CLOSE_UPVALUES, localOffset);
    }
    for (final updater in updaters) {
      updater.accept(this);
      emitCodes(OP_POP);
    }
    emitCodes(OP_JUMP, loop!.loopOffset - chunk.size - 2);
    loop!.loopOffset = loopOffset;
    patchJump(nextOffset);
  }

  void bodyLoop(Statement body) {
    body.accept(this);
  }

  void continueLoop() {
    // continue 默认跳转到循环开始的位置
    loop!.continueOffsets.add(emitExitJump(loop!.scopeDepth, loop!.loopOffset - chunk.size - 3));
  }

  void breakLoop() {
    loop!.breakOffsets.add(emitExitJump(loop!.scopeDepth));
  }

  void endLoop() {
    emitCodes(OP_JUMP, loop!.loopOffset - chunk.size - 2);

    // 修改 condition 的跳转位置
    if (loop!.conditionOffset != null) {
      patchJump(loop!.conditionOffset);
      emitCodes(OP_POP);
    }

    // 修改 break 的跳转位置
    loop!.breakOffsets.forEach(patchJump);

    loop!.endScope?.call();
    loop = loop!.enclosing;
  }

  void endForLoop(ForLoopParts node) {
    if (node is ForEachPartsWithDeclaration) {
      endScope();
    }
    endLoop();
    if (node is ForEachParts) {
      endScope();
    }
  }

  void beginTrying() {
    trying = Trying(enclosing: trying, startOffset: chunk.size, blockOffset: emitJump(OP_TRY_JUMP));
  }

  void bodyTrying(Block body) {
    body.accept(this);
    emitCodes(OP_TRY_END);
  }

  void catchTrying(NodeList<CatchClause> catchClauses) {
    for (final catchClause in catchClauses) {
      debugUpdateNode(catchClause);
      patchJump(trying!.blockOffset);
      beginScope();
      if (catchClause.exceptionType case NamedType? type when '$type'.contains('<') != true) {
        emitCodes(OP_CONSTANT, addConstant(type != null ? type.name2.lexeme : 'dynamic'));
      } else {
        error("Unsupported catch on type '${catchClause.exceptionType}'.");
      }
      addLocal(catchClause.exceptionParameter?.name.lexeme ?? '');
      addLocal(catchClause.stackTraceParameter?.name.lexeme ?? '');
      trying!.blockOffset = emitJump(OP_CATCH_JUMP);
      catchClause.body.accept(this);
      endScope();
      emitCodes(OP_TRY_END);
    }
  }

  void finallyTrying(Block? body) {
    debugUpdateNode(body);
    patchJump(trying!.blockOffset);
    trying!.blockOffset = emitJump(OP_FINALLY_JUMP);
    body?.accept(this);
    emitCodes(OP_FINALLY_END);
    patchJump(trying!.blockOffset);
    emitJump(OP_JUMP, trying!.startOffset - chunk.size);
  }

  void endTrying() {
    trying = trying!.enclosing;
  }

  void assign(CompoundAssignmentExpression assignment, Expression expression, void Function(_AssignmentTarget) accept) {
    void variable(String name) {
      accept((operandCount: 0, read: () => emitGetVariable(name), write: () => emitSetVariable(name)));
    }

    void property(String name, {Expression? target}) {
      final isSuper = target is SuperExpression;
      final operandCount = isSuper ? 2 : 1;
      accept((
        operandCount: operandCount,
        read: () {
          for (int i = 0; i < operandCount; i++) {
            emitCodes(OP_PEEK, operandCount - 1);
          }
          emitGetProperty(name, target: target);
        },
        write: () => emitCodes(isSuper ? OP_SET_SUPER : OP_SET_PROPERTY, addConstant(name)),
      ));
    }

    // 判空跳转覆盖整个赋值运算，跳过读取、计算、写入及后缀结果清理
    final shortable = assignment as NullShortableExpression;
    beginShorting(shortable);
    switch (expression) {
      case SimpleIdentifier simpleIdentifier:
        final fieldElement = assignment.fieldElement;
        if (fieldElement != null && fieldElement.isStatic) {
          // 设置类的静态字段
          variable('${fieldElement.classElement.name}.${simpleIdentifier.name}');
        } else if (fieldElement != null) {
          emitGetVariable('this');
          property(simpleIdentifier.name);
        } else {
          variable(simpleIdentifier.name);
        }
      case PrefixedIdentifier prefixedIdentifier:
        if (prefixedIdentifier.prefix.classElement case ClassElement classElement) {
          // 设置类的静态字段
          variable('${classElement.name}.${prefixedIdentifier.identifier.name}');
        } else {
          prefixedIdentifier.prefix.accept(this);
          property(prefixedIdentifier.identifier.name);
        }
      case PropertyAccess propertyAccess:
        targetShorting(propertyAccess.target, propertyAccess.isNullAware);
        property(propertyAccess.propertyName.name, target: propertyAccess.target);
      case IndexExpression indexExpression:
        targetShorting(indexExpression.target, indexExpression.isNullAware);
        indexExpression.index.accept(this);
        accept((
          operandCount: 2,
          read: () {
            emitCodes(OP_PEEK, 1);
            emitCodes(OP_PEEK, 1);
            emitOperator2('[]');
          },
          write: () => emitOperator3('[]='),
        ));
      default:
        throw UnimplementedError('(${expression.runtimeType}) $expression');
    }
    endShorting(shortable);
  }

  @override
  void compileCompilationUnit(CompilationUnit node) {
    super.compileCompilationUnit(node);

    // TODO 重构程序入口调用方式
    debugUpdateNode(null);
    emitCodes(OP_GET_GLOBAL, addConstant('main'));
    emitCodes(OP_ARGUMENT_LIST, OP_CALL);
    emitCodes(OP_RETURN);

    emitCodes(OP_NULL, OP_RETURN);
  }

  @override
  void compileFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    addLocalIfNeeded(name);
    node.functionExpression.accept(this);
    emitDefineGlobalIfNeeded(name, isGetter: node.isGetter, isSetter: node.isSetter);
  }

  @override
  void compileClassDeclaration(ClassDeclaration node) {
    assert(scopeDepth == 0);
    final typeName = node.name.lexeme;
    final className = '$typeName.class';
    emitCodes(OP_CLASS, addConstant(typeName));
    emitCodes(OP_DEFINE_GLOBAL, addConstant(className));

    if (node.hasUnnamedConstructor) {
      final function = ObjFunction('$typeName.new', returnType: 'void');
      final compiler = _Compiler(enclosing: this, function: function, debug: debug, hasThis: true);
      final closure = compiler.compile(body: (compiler) {
        compiler.emitCodes(OP_GET_GLOBAL, compiler.addConstant(className));
        compiler.emitCodes(OP_ARGUMENT_LIST, OP_CALL);
        compiler.emitCodes(OP_RETURN);
      });
      emitCodes(OP_CLOSURE, addConstant(closure));
      emitDefineGlobal(function.name);
    }

    // 方法参数默认值会在注册时读取静态常量
    final staticFields = node.members.whereType<FieldDeclaration>().where((field) => field.isStatic);
    for (final field in staticFields.where((field) => field.fields.isConst)) {
      field.accept(this);
    }

    final extendsClause = node.extendsClause;
    if (extendsClause != null) {
      beginScope();
      addLocal('super');
      extendsClause.accept(this);
    }

    final members = node.members.where((member) => member is! FieldDeclaration || !member.isStatic);
    if (members.isNotEmpty) {
      emitGetVariable(className);
      final fields = members.whereType<FieldDeclaration>();
      for (final member in members) {
        member.accept(this);
      }
      if (fields.isNotEmpty) {
        emitDefineClosure('$typeName.initialize', hasThis: true, body: (compiler) {
          for (final field in fields) {
            for (final variable in field.fields.variables) {
              compiler.emitGetVariable('this');
              if (variable.initializer case AstNode initializer) {
                initializer.accept(compiler);
              } else {
                compiler.emitCodes(OP_NULL);
              }
              compiler.emitSetProperty('$typeName.${variable.name.lexeme}');
              compiler.emitCodes(OP_POP);
            }
          }
          compiler.emitGetVariable('this');
          compiler.emitCodes(OP_RETURN);
        });
        emitCodes(OP_CLASS_INITIALIZER);
      }
      emitCodes(OP_POP);
    }

    if (extendsClause != null) {
      endScope();
    }

    // 先完成实例定义，静态初值才能创建已初始化的同类实例
    for (final field in staticFields.where((field) => !field.fields.isConst)) {
      field.accept(this);
    }
  }

  @override
  void compileExtendsClause(ExtendsClause node) {
    node.superclass.accept(this);
    final classDeclaration = node.parent as ClassDeclaration;
    emitCodes(OP_GET_GLOBAL, addConstant('${node.superclass.name2.lexeme}.class'));
    emitCodes(OP_GET_GLOBAL, addConstant('${classDeclaration.name.lexeme}.class'));
    emitCodes(OP_INHERIT);
  }

  @override
  void compileThisExpression(ThisExpression node) {
    emitGetVariable('this');
  }

  @override
  void compileSuperExpression(SuperExpression node) {
    emitGetVariable('this');
    emitGetVariable('super');
  }

  @override
  void compileInstanceCreationExpression(InstanceCreationExpression node) {
    final constructor = node.constructorName;
    final constructorName = '${constructor.type.name2.lexeme}.${constructor.name ?? 'new'}';
    emitCodes(OP_GET_GLOBAL, addConstant(constructorName));
    emitCodes(OP_ARGUMENT_LIST);
    node.argumentList.accept(this);
    emitCodes(OP_CALL);
  }

  @override
  void compileFieldDeclaration(FieldDeclaration node) {
    for (final variable in node.fields.variables) {
      if (node.isStatic) {
        if (variable.initializer case AstNode initializer) {
          initializer.accept(this);
        } else {
          emitCodes(OP_NULL);
        }
      }
      emitDefineField(variable.name.lexeme, node);
    }
  }

  @override
  void compileMethodDeclaration(MethodDeclaration node) {
    final className = node.className;
    final methodName = node.name.lexeme;
    final returnType = node.returnType?.type?.element?.name;
    emitDefineClosure('$className.$methodName', returnType: returnType, hasThis: true, body: (compiler) {
      compiler.addFormalParameters(node.parameters);
      node.body.accept(compiler);
    });
    emitAsyncIfNeeded(node.body);
    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
    emitDefineMethod(methodName, node);
  }

  @override
  void compileVariableDeclaration(VariableDeclaration node) {
    addLocalIfNeeded(node.name.lexeme);
    if (node.initializer case AstNode initializer) {
      initializer.accept(this);
    } else {
      emitCodes(OP_NULL);
    }
    emitDefineGlobalIfNeeded(node.name.lexeme);
  }

  @override
  void compileBlock(Block node) {
    beginScope();
    node.statements.accept(this);
    endScope();
  }

  @override
  void compileBlockFunctionBody(BlockFunctionBody node) {
    node.block.accept(this);
    if (node.parent is ConstructorDeclaration) {
      emitGetVariable('this');
    } else {
      emitCodes(OP_NULL);
    }
    emitCodes(OP_RETURN);
  }

  @override
  void compileExpressionFunctionBody(ExpressionFunctionBody node) {
    node.expression.accept(this);
    emitCodes(OP_RETURN);
  }

  @override
  void compileMethodInvocation(MethodInvocation node) {
    beginShorting(node);
    final target = node.target;
    final methodName = node.methodName.name;
    if (target?.classElement case ClassElement classElement) {
      // 获取类的静态成员
      emitGetVariable('${classElement.name}.$methodName');
    } else if (target != null || node.realTarget != null) {
      emitGetProperty(methodName, target: targetShorting(target, node.isNullAware));
    } else if (node.methodName.classMemberElement case ClassMemberElement member) {
      emitGetClassMember(methodName, member);
    } else {
      emitGetVariable(methodName);
    }
    emitCodes(OP_ARGUMENT_LIST);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
    emitCodes(OP_CALL);
    endShorting(node);
  }

  @override
  void compileFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.function.accept(this);
    emitCodes(OP_ARGUMENT_LIST);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
    emitCodes(OP_CALL);
  }

  @override
  void compileFunctionExpression(FunctionExpression node) {
    emitDefineClosure(node.declaredElement!.name, returnType: node.returnType, hasThis: false, body: (compiler) {
      compiler.addFormalParameters(node.parameters);
      node.body.accept(compiler);
    });
    emitAsyncIfNeeded(node.body);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void compileExpressionStatement(ExpressionStatement node) {
    super.compileExpressionStatement(node);
    emitCodes(OP_POP);
  }

  @override
  void compileNamedType(NamedType node) {
    switch (node.parent) {
      case IsExpression():
        if ('$node'.contains('<')) {
          error("Unsupported named type '${node.type}' for '${node.parent}'.");
        } else {
          emitCodes(OP_CONSTANT, addConstant(node.name2.lexeme));
        }
      default:
        return;
    }
  }

  @override
  void compileAwaitExpression(AwaitExpression node) {
    node.expression.accept(this);
    emitCodes(OP_AWAIT);
  }

  @override
  void compileIsExpression(IsExpression node) {
    node.expression.accept(this);
    node.type.accept(this);
    emitCodes(OP_IS);
    if (node.notOperator != null) {
      emitOperator1('!#');
    }
  }

  @override
  void compilePostfixExpression(PostfixExpression node) {
    final operator = node.operator.lexeme;
    final operators = {'!'};
    if (operator == '++' || operator == '--') {
      assign(node, node.operand, (target) {
        target.read();
        // 把旧值移到地址操作数下面，写入消耗地址后仍可返回旧值
        if (target.operandCount > 0) {
          emitCodes(OP_ROTATE, target.operandCount);
        }
        emitCodes(OP_PEEK, target.operandCount);
        emitCodes(OP_CONSTANT, addConstant(1));
        emitOperator2(operator[0]);
        target.write();
        emitCodes(OP_POP);
      });
    } else if (operators.contains(operator)) {
      node.operand.accept(this);
      emitOperator1('#$operator');
    } else {
      error("Unimplemented postfix operator: '$operator'.");
    }
  }

  @override
  void compilePrefixExpression(PrefixExpression node) {
    final operator = node.operator.lexeme;
    final operators = {'-', '!', '~'};
    if (operator == '++' || operator == '--') {
      assign(node, node.operand, (target) {
        target.read();
        emitCodes(OP_CONSTANT, addConstant(1));
        emitOperator2(operator[0]);
        target.write();
      });
    } else if (operators.contains(operator)) {
      node.operand.accept(this);
      emitOperator1('$operator#');
    } else {
      error("Unimplemented prefix operator: '$operator'.");
    }
  }

  @override
  void compileBinaryExpression(BinaryExpression node) {
    final operator = node.operator.lexeme;
    final operators = {
      '+', '-', '*', '/', '%', '~/', // 算数运算
      '>', '<', '>=', '<=', '==', '!=', // 关系运算
      '&', '^', '|', '<<', '>>', '>>>', // 位运算符
    };
    if (operator == '&&') {
      node.leftOperand.accept(this);
      final exitOffset = emitJump(OP_JUMP_IF_FALSE);
      emitCodes(OP_POP);
      node.rightOperand.accept(this);
      patchJump(exitOffset);
    } else if (operator == '||' || operator == '??') {
      node.leftOperand.accept(this);
      final nextOffset = emitJump(operator == '||' ? OP_JUMP_IF_FALSE : OP_JUMP_IF_NULL);
      final exitOffset = emitJump(OP_JUMP);
      patchJump(nextOffset);
      emitCodes(OP_POP);
      node.rightOperand.accept(this);
      patchJump(exitOffset);
    } else if (operators.contains(operator)) {
      node.leftOperand.accept(this);
      node.rightOperand.accept(this);
      emitOperator2(operator);
    } else {
      error("Unimplemented binary operator: '$operator'.");
    }
  }

  @override
  void compileCascadeExpression(CascadeExpression node) {
    beginShorting(node);
    targetShorting(node.target, node.isNullAware);
    for (final section in node.cascadeSections) {
      debugUpdateNode(section);
      emitCodes(OP_PEEK, 0);
      section.accept(this);
      emitCodes(OP_POP);
    }
    endShorting(node);
  }

  @override
  void compileIndexExpression(IndexExpression node) {
    beginShorting(node);
    targetShorting(node.target, node.isNullAware);
    node.index.accept(this);
    emitOperator2('[]');
    endShorting(node);
  }

  @override
  void compileAssignmentExpression(AssignmentExpression node) {
    final operator = node.operator.lexeme;
    final operators = {'+=', '-=', '*=', '/=', '%=', '~/=', '&=', '^=', '|=', '<<=', '>>=', '>>>='};
    if (operator != '=' && operator != '??=' && !operators.contains(operator)) {
      error("Unsupported assignment by operator '$operator'.");
    }
    assign(node, node.leftHandSide, (target) {
      if (operator == '??=') {
        target.read();
        final nextOffset = emitJump(OP_JUMP_IF_NULL);
        // 非 null 分支保留读取值，只清理地址操作数，不执行右侧或 setter
        if (target.operandCount > 0) {
          emitCodes(OP_ROTATE, target.operandCount);
          for (int i = 0; i < target.operandCount; i++) {
            emitCodes(OP_POP);
          }
        }
        final exitOffset = emitJump(OP_JUMP);
        patchJump(nextOffset);
        emitCodes(OP_POP);
        node.rightHandSide.accept(this);
        target.write();
        patchJump(exitOffset);
      } else {
        if (operator != '=') {
          target.read();
        }
        node.rightHandSide.accept(this);
        if (operator != '=') {
          emitOperator2(operator.substring(0, operator.length - 1));
        }
        target.write();
      }
    });
  }

  @override
  void compileFormalParameterList(FormalParameterList node) {
    if (node.parameters.isNotEmpty) {
      node.parameters.accept(this);
      emitCodes(OP_PARAMETER_LIST, node.parameters.length);
    }
  }

  @override
  void compileSimpleFormalParameter(SimpleFormalParameter node) {
    node.type?.accept(this);
    if (node.isPositional) {
      emitCodes(OP_PARAMETER_POSITIONAL, addConstant(node.name!.lexeme));
    } else {
      emitCodes(OP_PARAMETER_NAMED, addConstant(node.name!.lexeme));
    }
  }

  @override
  void compileDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
    if (node.isOptional) {
      node.defaultValue == null ? emitCodes(OP_NULL) : node.defaultValue!.accept(this);
      emitCodes(OP_PARAMETER_DEFAULT);
    }
  }

  @override
  void compileArgumentList(ArgumentList node) {
    for (final argument in node.arguments) {
      argument.accept(this);
      emitCodes(argument is NamedExpression ? OP_ARGUMENT_NAMED : OP_ARGUMENT_POSITIONAL);
    }
  }

  @override
  void compileNamedExpression(NamedExpression node) {
    emitCodes(OP_CONSTANT, addConstant(node.name.label.name));
    node.expression.accept(this);
  }

  @override
  void compileSimpleIdentifier(SimpleIdentifier node) {
    if (node.classMemberElement case ClassMemberElement member) {
      emitGetClassMember(node.name, member);
    } else {
      emitGetVariable(node.name);
    }
  }

  @override
  void compilePrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.classElement case ClassElement classElement) {
      // 获取类的静态成员
      emitGetVariable('${classElement.name}.${node.identifier.name}');
    } else {
      emitGetVariable(node.prefix.name);
      emitGetProperty(node.identifier.name);
    }
  }

  @override
  void compilePropertyAccess(PropertyAccess node) {
    if (node.target?.classElement case ClassElement classElement) {
      assert(!node.isNullAware);
      // 获取类的静态成员
      emitGetVariable('${classElement.name}.${node.propertyName.name}');
    } else {
      beginShorting(node);
      emitGetProperty(node.propertyName.name, target: targetShorting(node.target, node.isNullAware));
      endShorting(node);
    }
  }

  @override
  void compileSetOrMapLiteral(SetOrMapLiteral node) {
    assert(node.isSet || node.isMap);
    for (final type in node.typeArgumentNames) {
      emitCodes(OP_CONSTANT, addConstant(type));
    }
    emitCodes(node.isSet ? OP_SET : OP_MAP);
    for (final element in node.elements) {
      emitCollectionElement(element, isMap: node.isMap);
    }
  }

  @override
  void compileListLiteral(ListLiteral node) {
    for (final type in node.typeArgumentNames) {
      emitCodes(OP_CONSTANT, addConstant(type));
    }
    emitCodes(OP_LIST);
    for (final element in node.elements) {
      emitCollectionElement(element, isMap: false);
    }
  }

  @override
  void compileNullLiteral(NullLiteral node) {
    emitCodes(OP_NULL);
  }

  @override
  void compileBooleanLiteral(BooleanLiteral node) {
    emitCodes(node.value ? OP_TRUE : OP_FALSE);
  }

  @override
  void compileDoubleLiteral(DoubleLiteral node) {
    emitCodes(OP_CONSTANT, addConstant(node.value));
  }

  @override
  void compileIntegerLiteral(IntegerLiteral node) {
    emitCodes(OP_CONSTANT, addConstant(node.value));
  }

  @override
  void compileSimpleStringLiteral(SimpleStringLiteral node) {
    emitCodes(OP_CONSTANT, addConstant(node.value));
  }

  @override
  void compileForPartsWithDeclarations(ForPartsWithDeclarations node) {
    final localOffset = locals.length;
    beginLoop(declarations: node.variables);
    conditionLoop(node.condition);
    updateLoop(node.updaters, localOffset: localOffset);
  }

  @override
  void compileForPartsWithExpression(ForPartsWithExpression node) {
    beginLoop(initialization: node.initialization);
    conditionLoop(node.condition);
    updateLoop(node.updaters);
  }

  @override
  void compileForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    final iteratorOffset = beginForEachLoop(node);
    // 每轮绑定单独的作用域，正常结束与退出跳转都会关闭本轮捕获
    beginScope();
    addLocal(node.loopVariable.name.lexeme);
    emitCodes(OP_GET_LOCAL, iteratorOffset);
    emitGetProperty('current');
  }

  @override
  void compileForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    final iteratorOffset = beginForEachLoop(node);
    final identifier = node.identifier;
    final member = identifier.classMemberElement;
    if (member != null && !member.isStatic) {
      emitGetVariable('this');
    }
    emitCodes(OP_GET_LOCAL, iteratorOffset);
    emitGetProperty('current');
    if (member == null) {
      emitSetVariable(identifier.name);
    } else if (member.isStatic) {
      emitSetVariable('${member.classElement.name}.${identifier.name}');
    } else {
      emitSetProperty(identifier.name);
    }
    emitCodes(OP_POP);
  }

  @override
  void compileForEachPartsWithPattern(ForEachPartsWithPattern node) {
    error("Unsupported 'for-in' with pattern '${node.pattern}'.");
  }

  @override
  void compileForElement(ForElement node) {
    if (node.awaitKeyword != null) {
      error("Unsupported 'await for'.");
    }
    if (node.forLoopParts is ForPartsWithPattern) {
      error("Unsupported 'collection-for' with pattern '${node.forLoopParts}'.");
    }
    final literal = node.thisOrAncestorMatching<AstNode>((node) => node is ListLiteral || node is SetOrMapLiteral);
    final isMap = literal is SetOrMapLiteral && literal.isMap;
    final localOffset = locals.length;
    beginScope();
    // 暂存表达式操作数，让循环变量仍按 locals 的槽位编号绑定
    emitCodes(OP_COLLECTION_BEGIN, localOffset);
    addLocal('');
    final collectionOffset = locals.length;
    addLocal('');
    node.forLoopParts.accept(this);
    emitCodes(OP_GET_LOCAL, collectionOffset);
    emitCollectionElement(node.body, isMap: isMap);
    emitCodes(OP_POP);
    endForLoop(node.forLoopParts);
    emitCodes(OP_COLLECTION_END);
    // 恢复指令已移除两个匿名槽，只清理编译器记录
    assert(locals.length == localOffset + 2);
    locals.removeRange(localOffset, locals.length);
    scopeDepth--;
  }

  @override
  void compileForStatement(ForStatement node) {
    if (node.awaitKeyword != null) {
      error("Unsupported 'await for'.");
    }
    node.forLoopParts.accept(this);
    bodyLoop(node.body);
    endForLoop(node.forLoopParts);
  }

  @override
  void compileDoStatement(DoStatement node) {
    beginLoop();
    bodyLoop(node.body);
    conditionLoop(node.condition);
    endLoop();
  }

  @override
  void compileWhileStatement(WhileStatement node) {
    beginLoop();
    conditionLoop(node.condition);
    bodyLoop(node.body);
    endLoop();
  }

  @override
  void compileContinueStatement(ContinueStatement node) {
    if (node.label != null) {
      error("Unsupported 'continue' with label '${node.label}'.");
    }
    continueLoop();
  }

  @override
  void compileBreakStatement(BreakStatement node) {
    if (node.label != null) {
      error("Unsupported 'break' with label '${node.label}'.");
    }
    breakLoop();
  }

  @override
  void compileIfStatement(IfStatement node) {
    node.expression.accept(this);
    final elseOffset = emitJump(OP_JUMP_IF_FALSE);
    emitCodes(OP_POP);

    if (node.caseClause != null) {
      error("Unsupported 'if' with '${node.caseClause}'.");
    }

    node.thenStatement.accept(this);
    final exitOffset = emitJump(OP_JUMP);
    patchJump(elseOffset);
    emitCodes(OP_POP);

    node.elseStatement?.accept(this);
    patchJump(exitOffset);
  }

  @override
  void compileConditionalExpression(ConditionalExpression node) {
    node.condition.accept(this);
    final elseOffset = emitJump(OP_JUMP_IF_FALSE);
    emitCodes(OP_POP);

    node.thenExpression.accept(this);
    final exitOffset = emitJump(OP_JUMP);
    patchJump(elseOffset);
    emitCodes(OP_POP);

    node.elseExpression.accept(this);
    patchJump(exitOffset);
  }

  @override
  void compileThrowExpression(ThrowExpression node) {
    node.expression.accept(this);
    emitCodes(OP_THROW);
  }

  @override
  void compileRethrowExpression(RethrowExpression node) {
    int depth = 0;
    for (AstNode? parent = node.parent; parent != null && parent is! CatchClause; parent = parent.parent) {
      if (parent is TryStatement) depth++;
    }
    emitCodes(OP_RETHROW, depth);
  }

  @override
  void compileTryStatement(TryStatement node) {
    beginTrying();
    bodyTrying(node.body);
    catchTrying(node.catchClauses);
    finallyTrying(node.finallyBlock);
    endTrying();
  }

  @override
  void compileReturnStatement(ReturnStatement node) {
    super.compileReturnStatement(node);
    if (node.expression == null) emitCodes(OP_NULL);
    emitCodes(OP_RETURN);
  }

  @override
  void compileStringInterpolation(StringInterpolation node) {
    assert(node.elements.isNotEmpty);
    for (final element in node.elements) {
      element.accept(this);
    }
    emitCodes(OP_CONCAT_STRING, node.elements.length);
  }

  @override
  void compileAdjacentStrings(AdjacentStrings node) {
    assert(node.strings.isNotEmpty);
    for (final element in node.strings) {
      element.accept(this);
    }
    emitCodes(OP_CONCAT_STRING, node.strings.length);
  }

  @override
  void compileInterpolationString(InterpolationString node) {
    emitCodes(OP_CONSTANT, addConstant(node.value));
  }

  @override
  ObjFunction compile({AstNode? node, _CompilerBody? body}) {
    node?.accept(this);
    body?.call(this);
    if (debug) disassembleChunk(chunk);
    return function;
  }
}
