import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class PrintVisitor extends RecursiveAstVisitor<void> {
  int _indent = 0;

  _print(String name, AstNode node, Function visit, [Map<String, dynamic>? props]) {
    final info = StringBuffer('$name: $node');
    if (props != null && props.isNotEmpty) {
      info.write(' {');
      for (final (index, entry) in props.entries.indexed) {
        info.write(' ${entry.key}: (${entry.value})');
        if (index < props.length - 1) info.write(',');
      }
      info.write(' }');
    }
    _indent++;
    stdout.writeln('${'|   ' * (_indent ~/ 2)}${'| ' * (_indent % 2)}$info');
    visit(node);
    _indent--;
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _print('AdjacentStrings', node, super.visitAdjacentStrings, {
      'strings': node.strings,
    });
  }

  @override
  void visitAnnotation(Annotation node) {
    _print('Annotation', node, super.visitAnnotation);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _print('ArgumentList', node, super.visitArgumentList, {
      'arguments': node.arguments,
    });
  }

  @override
  void visitAsExpression(AsExpression node) {
    _print('AsExpression', node, super.visitAsExpression);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _print('AssertInitializer', node, super.visitAssertInitializer);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    _print('AssertStatement', node, super.visitAssertStatement);
  }

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    _print('AssignedVariablePattern', node, super.visitAssignedVariablePattern);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _print('AssignmentExpression', node, super.visitAssignmentExpression, {
      'leftHandSide': node.leftHandSide,
      'operator': node.operator,
      'rightHandSide': node.rightHandSide,
    });
  }

  @override
  void visitAugmentationImportDirective(AugmentationImportDirective node) {
    _print('AugmentationImportDirective', node, super.visitAugmentationImportDirective);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _print('AwaitExpression', node, super.visitAwaitExpression);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _print('BinaryExpression', node, super.visitBinaryExpression, {
      'leftOperand': node.leftOperand,
      'operator': node.operator,
      'rightOperand': node.rightOperand,
    });
  }

  @override
  void visitBlock(Block node) {
    _print('Block', node, super.visitBlock);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _print('BlockFunctionBody', node, super.visitBlockFunctionBody);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _print('BooleanLiteral', node, super.visitBooleanLiteral);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    _print('BreakStatement', node, super.visitBreakStatement, {
      'breakKeyword': node.breakKeyword,
      'label': node.label,
      'semicolon': node.semicolon,
    });
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    _print('CascadeExpression', node, super.visitCascadeExpression, {
      'target': node.target,
      'cascadeSections': node.cascadeSections,
    });
  }

  @override
  void visitCaseClause(CaseClause node) {
    _print('CaseClause', node, super.visitCaseClause);
  }

  @override
  void visitCastPattern(CastPattern node) {
    _print('CastPattern', node, super.visitCastPattern);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _print('CatchClause', node, super.visitCatchClause, {
      'onKeyword': node.onKeyword,
      'exceptionType': node.exceptionType,
      'catchKeyword': node.catchKeyword,
      'leftParenthesis': node.leftParenthesis,
      'exceptionParameter': node.exceptionParameter,
      'comma': node.comma,
      'stackTraceParameter': node.stackTraceParameter,
      'rightParenthesis': node.rightParenthesis,
      'body': node.body,
    });
  }

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    _print('CatchClauseParameter', node, super.visitCatchClauseParameter);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _print('ClassDeclaration', node, super.visitClassDeclaration);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _print('ClassTypeAlias', node, super.visitClassTypeAlias);
  }

  @override
  void visitComment(Comment node) {
    _print('Comment', node, super.visitComment);
  }

  @override
  void visitCommentReference(CommentReference node) {
    _print('CommentReference', node, super.visitCommentReference);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _print('CompilationUnit', node, super.visitCompilationUnit);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _print('ConditionalExpression', node, super.visitConditionalExpression, {
      'condition': node.condition,
      'question': node.question,
      'thenExpression': node.thenExpression,
      'colon': node.colon,
      'elseExpression': node.elseExpression,
    });
  }

  @override
  void visitConfiguration(Configuration node) {
    _print('Configuration', node, super.visitConfiguration);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    _print('ConstantPattern', node, super.visitConstantPattern);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _print('ConstructorDeclaration', node, super.visitConstructorDeclaration);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _print('ConstructorFieldInitializer', node, super.visitConstructorFieldInitializer);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _print('ConstructorName', node, super.visitConstructorName, {
      'type': node.type,
      'period': node.period,
      'name': node.name,
    });
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    _print('ConstructorReference', node, super.visitConstructorReference);
  }

  @override
  void visitConstructorSelector(ConstructorSelector node) {
    _print('ConstructorSelector', node, super.visitConstructorSelector);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _print('ContinueStatement', node, super.visitContinueStatement, {
      'continueKeyword': node.continueKeyword,
      'label': node.label,
      'semicolon': node.semicolon,
    });
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _print('DeclaredIdentifier', node, super.visitDeclaredIdentifier);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    _print('DeclaredVariablePattern', node, super.visitDeclaredVariablePattern);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    _print('DefaultFormalParameter', node, super.visitDefaultFormalParameter);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _print('DoStatement', node, super.visitDoStatement, {
      'doKeyword': node.doKeyword,
      'body': node.body,
      'whileKeyword': node.whileKeyword,
      'leftParenthesis': node.leftParenthesis,
      'condition': node.condition,
      'rightParenthesis': node.rightParenthesis,
      'semicolon': node.semicolon,
    });
  }

  @override
  void visitDottedName(DottedName node) {
    _print('DottedName', node, super.visitDottedName);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _print('DoubleLiteral', node, super.visitDoubleLiteral);
  }

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    _print('EmptyFunctionBody', node, super.visitEmptyFunctionBody);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    _print('EmptyStatement', node, super.visitEmptyStatement);
  }

  @override
  void visitEnumConstantArguments(EnumConstantArguments node) {
    _print('EnumConstantArguments', node, super.visitEnumConstantArguments);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _print('EnumConstantDeclaration', node, super.visitEnumConstantDeclaration);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _print('EnumDeclaration', node, super.visitEnumDeclaration);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _print('ExportDirective', node, super.visitExportDirective);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _print('ExpressionFunctionBody', node, super.visitExpressionFunctionBody);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _print('ExpressionStatement', node, super.visitExpressionStatement, {
      'expression': node.expression,
      'semicolon': node.semicolon,
    });
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _print('ExtendsClause', node, super.visitExtendsClause);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _print('ExtensionDeclaration', node, super.visitExtensionDeclaration);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _print('ExtensionOverride', node, super.visitExtensionOverride);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _print('ExtensionTypeDeclaration', node, super.visitExtensionTypeDeclaration);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _print('FieldDeclaration', node, super.visitFieldDeclaration, {
      'staticKeyword': node.staticKeyword,
      'fields': node.fields,
      'semicolon': node.semicolon,
    });
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _print('FieldFormalParameter', node, super.visitFieldFormalParameter);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _print('ForEachPartsWithDeclaration', node, super.visitForEachPartsWithDeclaration);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _print('ForEachPartsWithIdentifier', node, super.visitForEachPartsWithIdentifier);
  }

  @override
  void visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    _print('ForEachPartsWithPattern', node, super.visitForEachPartsWithPattern);
  }

  @override
  void visitForElement(ForElement node) {
    _print('ForElement', node, super.visitForElement);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    _print('ForPartsWithDeclarations', node, super.visitForPartsWithDeclarations, {
      'variables': node.variables,
      'leftSeparator': node.leftSeparator,
      'condition': node.condition,
      'rightSeparator': node.rightSeparator,
      'updaters': node.updaters,
    });
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    _print('ForPartsWithExpression', node, super.visitForPartsWithExpression, {
      'initialization': node.initialization,
      'leftSeparator': node.leftSeparator,
      'condition': node.condition,
      'rightSeparator': node.rightSeparator,
      'updaters': node.updaters,
    });
  }

  @override
  void visitForPartsWithPattern(ForPartsWithPattern node) {
    _print('ForPartsWithPattern', node, super.visitForPartsWithPattern);
  }

  @override
  void visitForStatement(ForStatement node) {
    _print('ForStatement', node, super.visitForStatement, {
      'awaitKeyword': node.awaitKeyword,
      'forKeyword': node.forKeyword,
      'leftParenthesis': node.leftParenthesis,
      'forLoopParts': node.forLoopParts,
      'rightParenthesis': node.rightParenthesis,
      'body': node.body,
    });
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _print('FormalParameterList', node, super.visitFormalParameterList);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _print('FunctionDeclaration', node, super.visitFunctionDeclaration);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _print('FunctionDeclarationStatement', node, super.visitFunctionDeclarationStatement);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _print('FunctionExpression', node, super.visitFunctionExpression, {
      'typeParameters': node.typeParameters,
      'parameters': node.parameters,
      'body': node.body,
    });
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _print('FunctionExpressionInvocation', node, super.visitFunctionExpressionInvocation, {
      'function': node.function,
      'typeArguments': node.typeArguments,
      'argumentList': node.argumentList,
    });
  }

  @override
  void visitFunctionReference(FunctionReference node) {
    _print('FunctionReference', node, super.visitFunctionReference);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _print('FunctionTypeAlias', node, super.visitFunctionTypeAlias);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _print('FunctionTypedFormalParameter', node, super.visitFunctionTypedFormalParameter);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    _print('GenericFunctionType', node, super.visitGenericFunctionType);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _print('GenericTypeAlias', node, super.visitGenericTypeAlias);
  }

  @override
  void visitGuardedPattern(GuardedPattern node) {
    _print('GuardedPattern', node, super.visitGuardedPattern);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    _print('HideCombinator', node, super.visitHideCombinator);
  }

  @override
  void visitIfElement(IfElement node) {
    _print('IfElement', node, super.visitIfElement);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _print('IfStatement', node, super.visitIfStatement);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    _print('ImplementsClause', node, super.visitImplementsClause);
  }

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    _print('ImplicitCallReference', node, super.visitImplicitCallReference);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _print('ImportDirective', node, super.visitImportDirective);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    _print('ImportPrefixReference', node, super.visitImportPrefixReference);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _print('IndexExpression', node, super.visitIndexExpression, {
      'target': node.target,
      'period': node.period,
      'leftBracket': node.leftBracket,
      'index': node.index,
      'rightBracket': node.rightBracket,
    });
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _print('InstanceCreationExpression', node, super.visitInstanceCreationExpression, {
      'keyword': node.keyword,
      'constructorName': node.constructorName,
      'argumentList': node.argumentList,
    });
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _print('IntegerLiteral', node, super.visitIntegerLiteral, {
      'literal': node.literal,
    });
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _print('InterpolationExpression', node, super.visitInterpolationExpression, {
      'leftBracket': node.leftBracket,
      'expression': node.expression,
      'rightBracket': node.rightBracket,
    });
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _print('InterpolationString', node, super.visitInterpolationString, {
      'contents': node.contents,
    });
  }

  @override
  void visitIsExpression(IsExpression node) {
    _print('IsExpression', node, super.visitIsExpression, {
      'expression': node.expression,
      'isOperator': node.isOperator,
      'notOperator': node.notOperator,
      'type': node.type,
    });
  }

  @override
  void visitLabel(Label node) {
    _print('Label', node, super.visitLabel);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _print('LabeledStatement', node, super.visitLabeledStatement);
  }

  @override
  void visitLibraryAugmentationDirective(LibraryAugmentationDirective node) {
    _print('LibraryAugmentationDirective', node, super.visitLibraryAugmentationDirective);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _print('LibraryDirective', node, super.visitLibraryDirective);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    _print('LibraryIdentifier', node, super.visitLibraryIdentifier);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _print('ListLiteral', node, super.visitListLiteral, {
      'leftBracket': node.leftBracket,
      'elements': node.elements,
      'rightBracket': node.rightBracket,
    });
  }

  @override
  void visitListPattern(ListPattern node) {
    _print('ListPattern', node, super.visitListPattern);
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    _print('LogicalAndPattern', node, super.visitLogicalAndPattern);
  }

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    _print('LogicalOrPattern', node, super.visitLogicalOrPattern);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    _print('MapLiteralEntry', node, super.visitMapLiteralEntry, {
      'key': node.key,
      'separator': node.separator,
      'value': node.value,
    });
  }

  @override
  void visitMapPattern(MapPattern node) {
    _print('MapPattern', node, super.visitMapPattern);
  }

  @override
  void visitMapPatternEntry(MapPatternEntry node) {
    _print('MapPatternEntry', node, super.visitMapPatternEntry);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _print('MethodDeclaration', node, super.visitMethodDeclaration);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _print('MethodInvocation', node, super.visitMethodInvocation, {
      'target': node.target,
      'methodName': node.methodName,
      'typeArguments': node.typeArguments,
      'argumentList': node.argumentList,
    });
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _print('MixinDeclaration', node, super.visitMixinDeclaration);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    _print('NamedExpression', node, super.visitNamedExpression);
  }

  @override
  void visitNamedType(NamedType node) {
    _print('NamedType', node, super.visitNamedType, {
      'importPrefix': node.importPrefix,
      'name2': node.name2,
      'typeArguments': node.typeArguments,
      'question': node.question,
    });
  }

  @override
  void visitNativeClause(NativeClause node) {
    _print('NativeClause', node, super.visitNativeClause);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    _print('NativeFunctionBody', node, super.visitNativeFunctionBody);
  }

  @override
  void visitNullAssertPattern(NullAssertPattern node) {
    _print('NullAssertPattern', node, super.visitNullAssertPattern);
  }

  @override
  void visitNullCheckPattern(NullCheckPattern node) {
    _print('NullCheckPattern', node, super.visitNullCheckPattern);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _print('NullLiteral', node, super.visitNullLiteral, {
      'literal': node.literal,
    });
  }

  @override
  void visitObjectPattern(ObjectPattern node) {
    _print('ObjectPattern', node, super.visitObjectPattern);
  }

  @override
  void visitOnClause(OnClause node) {
    _print('OnClause', node, super.visitOnClause);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    _print('ParenthesizedExpression', node, super.visitParenthesizedExpression);
  }

  @override
  void visitParenthesizedPattern(ParenthesizedPattern node) {
    _print('ParenthesizedPattern', node, super.visitParenthesizedPattern);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _print('PartDirective', node, super.visitPartDirective);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _print('PartOfDirective', node, super.visitPartOfDirective);
  }

  @override
  void visitPatternAssignment(PatternAssignment node) {
    _print('PatternAssignment', node, super.visitPatternAssignment);
  }

  @override
  void visitPatternField(PatternField node) {
    _print('PatternField', node, super.visitPatternField);
  }

  @override
  void visitPatternFieldName(PatternFieldName node) {
    _print('PatternFieldName', node, super.visitPatternFieldName);
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    _print('PatternVariableDeclaration', node, super.visitPatternVariableDeclaration);
  }

  @override
  void visitPatternVariableDeclarationStatement(PatternVariableDeclarationStatement node) {
    _print('PatternVariableDeclarationStatement', node, super.visitPatternVariableDeclarationStatement, {
      'declaration': node.declaration,
      'semicolon': node.semicolon,
    });
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _print('PostfixExpression', node, super.visitPostfixExpression, {
      'operator': node.operator,
      'operand': node.operand,
    });
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _print('PrefixExpression', node, super.visitPrefixExpression, {
      'operator': node.operator,
      'operand': node.operand,
    });
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _print('PrefixedIdentifier', node, super.visitPrefixedIdentifier, {
      'prefix': node.prefix,
      'period': node.period,
      'identifier': node.identifier,
    });
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _print('PropertyAccess', node, super.visitPropertyAccess, {
      'target': node.target,
      'operator': node.operator,
      'propertyName': node.propertyName,
    });
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    _print('RecordLiteral', node, super.visitRecordLiteral);
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    _print('RecordPattern', node, super.visitRecordPattern);
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    _print('RecordTypeAnnotation', node, super.visitRecordTypeAnnotation);
  }

  @override
  void visitRecordTypeAnnotationNamedField(RecordTypeAnnotationNamedField node) {
    _print('RecordTypeAnnotationNamedField', node, super.visitRecordTypeAnnotationNamedField);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(RecordTypeAnnotationNamedFields node) {
    _print('RecordTypeAnnotationNamedFields', node, super.visitRecordTypeAnnotationNamedFields);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(RecordTypeAnnotationPositionalField node) {
    _print('RecordTypeAnnotationPositionalField', node, super.visitRecordTypeAnnotationPositionalField);
  }

  @override
  void visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    _print('RedirectingConstructorInvocation', node, super.visitRedirectingConstructorInvocation);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    _print('RelationalPattern', node, super.visitRelationalPattern);
  }

  @override
  void visitRepresentationConstructorName(RepresentationConstructorName node) {
    _print('RepresentationConstructorName', node, super.visitRepresentationConstructorName);
  }

  @override
  void visitRepresentationDeclaration(RepresentationDeclaration node) {
    _print('RepresentationDeclaration', node, super.visitRepresentationDeclaration);
  }

  @override
  void visitRestPatternElement(RestPatternElement node) {
    _print('RestPatternElement', node, super.visitRestPatternElement);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    _print('RethrowExpression', node, super.visitRethrowExpression, {
      'rethrowKeyword': node.rethrowKeyword,
    });
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _print('ReturnStatement', node, super.visitReturnStatement);
  }

  @override
  void visitScriptTag(ScriptTag node) {
    _print('ScriptTag', node, super.visitScriptTag);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _print('SetOrMapLiteral', node, super.visitSetOrMapLiteral, {
      'leftBracket': node.leftBracket,
      'elements': node.elements,
      'rightBracket': node.rightBracket,
    });
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    _print('ShowCombinator', node, super.visitShowCombinator);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _print('SimpleFormalParameter', node, super.visitSimpleFormalParameter);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _print('SimpleIdentifier', node, super.visitSimpleIdentifier, {
      'token': node.token,
    });
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _print('SimpleStringLiteral', node, super.visitSimpleStringLiteral, {
      'literal': node.literal,
    });
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    _print('SpreadElement', node, super.visitSpreadElement);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _print('StringInterpolation', node, super.visitStringInterpolation, {
      'elements': node.elements,
    });
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _print('SuperConstructorInvocation', node, super.visitSuperConstructorInvocation);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    _print('SuperExpression', node, super.visitSuperExpression, {
      'superKeyword': node.superKeyword,
    });
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _print('SuperFormalParameter', node, super.visitSuperFormalParameter);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _print('SwitchCase', node, super.visitSwitchCase);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _print('SwitchDefault', node, super.visitSwitchDefault);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _print('SwitchExpression', node, super.visitSwitchExpression);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    _print('SwitchExpressionCase', node, super.visitSwitchExpressionCase);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    _print('SwitchPatternCase', node, super.visitSwitchPatternCase);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _print('SwitchStatement', node, super.visitSwitchStatement);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _print('SymbolLiteral', node, super.visitSymbolLiteral);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _print('ThisExpression', node, super.visitThisExpression, {
      'thisKeyword': node.thisKeyword,
    });
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    _print('ThrowExpression', node, super.visitThrowExpression, {
      'throwKeyword': node.throwKeyword,
      'expression': node.expression,
    });
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _print('TopLevelVariableDeclaration', node, super.visitTopLevelVariableDeclaration);
  }

  @override
  void visitTryStatement(TryStatement node) {
    _print('TryStatement', node, super.visitTryStatement, {
      'tryKeyword': node.tryKeyword,
      'body': node.body,
      'catchClauses': node.catchClauses,
      'finallyKeyword': node.finallyKeyword,
      'finallyBlock': node.finallyBlock,
    });
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    _print('TypeArgumentList', node, super.visitTypeArgumentList);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    _print('TypeLiteral', node, super.visitTypeLiteral);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _print('TypeParameter', node, super.visitTypeParameter);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    _print('TypeParameterList', node, super.visitTypeParameterList);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _print('VariableDeclaration', node, super.visitVariableDeclaration, {
      'name': node.name,
      'equals': node.equals,
      'initializer': node.initializer,
    });
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    _print('VariableDeclarationList', node, super.visitVariableDeclarationList, {
      'lateKeyword': node.lateKeyword,
      'keyword': node.keyword,
      'type': node.type,
      'variables': node.variables,
    });
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _print('VariableDeclarationStatement', node, super.visitVariableDeclarationStatement, {
      'variables': node.variables,
      'semicolon': node.semicolon,
    });
  }

  @override
  void visitWhenClause(WhenClause node) {
    _print('WhenClause', node, super.visitWhenClause);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _print('WhileStatement', node, super.visitWhileStatement, {
      'whileKeyword': node.whileKeyword,
      'leftParenthesis': node.leftParenthesis,
      'condition': node.condition,
      'rightParenthesis': node.rightParenthesis,
      'body': node.body,
    });
  }

  @override
  void visitWildcardPattern(WildcardPattern node) {
    _print('WildcardPattern', node, super.visitWildcardPattern);
  }

  @override
  void visitWithClause(WithClause node) {
    _print('WithClause', node, super.visitWithClause);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _print('YieldStatement', node, super.visitYieldStatement);
  }
}
