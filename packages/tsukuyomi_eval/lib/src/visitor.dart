import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:meta/meta.dart';

mixin CompilerAstVisitorMixin on AstVisitor<void> {
  void compileAdjacentStrings(AdjacentStrings node) {
    node.visitChildren(this);
  }

  void compileAnnotation(Annotation node) {
    node.visitChildren(this);
  }

  void compileArgumentList(ArgumentList node) {
    node.visitChildren(this);
  }

  void compileAsExpression(AsExpression node) {
    node.visitChildren(this);
  }

  void compileAssertInitializer(AssertInitializer node) {
    node.visitChildren(this);
  }

  void compileAssertStatement(AssertStatement node) {
    node.visitChildren(this);
  }

  void compileAssignedVariablePattern(AssignedVariablePattern node) {
    node.visitChildren(this);
  }

  void compileAssignmentExpression(AssignmentExpression node) {
    node.visitChildren(this);
  }

  void compileAugmentationImportDirective(AugmentationImportDirective node) {
    node.visitChildren(this);
  }

  void compileAwaitExpression(AwaitExpression node) {
    node.visitChildren(this);
  }

  void compileBinaryExpression(BinaryExpression node) {
    node.visitChildren(this);
  }

  void compileBlock(Block node) {
    node.visitChildren(this);
  }

  void compileBlockFunctionBody(BlockFunctionBody node) {
    node.visitChildren(this);
  }

  void compileBooleanLiteral(BooleanLiteral node) {
    node.visitChildren(this);
  }

  void compileBreakStatement(BreakStatement node) {
    node.visitChildren(this);
  }

  void compileCascadeExpression(CascadeExpression node) {
    node.visitChildren(this);
  }

  void compileCaseClause(CaseClause node) {
    node.visitChildren(this);
  }

  void compileCastPattern(CastPattern node) {
    node.visitChildren(this);
  }

  void compileCatchClause(CatchClause node) {
    node.visitChildren(this);
  }

  void compileCatchClauseParameter(CatchClauseParameter node) {
    node.visitChildren(this);
  }

  void compileClassDeclaration(ClassDeclaration node) {
    node.visitChildren(this);
  }

  void compileClassTypeAlias(ClassTypeAlias node) {
    node.visitChildren(this);
  }

  void compileComment(Comment node) {
    node.visitChildren(this);
  }

  void compileCommentReference(CommentReference node) {
    node.visitChildren(this);
  }

  void compileCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
  }

  void compileConditionalExpression(ConditionalExpression node) {
    node.visitChildren(this);
  }

  void compileConfiguration(Configuration node) {
    node.visitChildren(this);
  }

  void compileConstantPattern(ConstantPattern node) {
    node.visitChildren(this);
  }

  void compileConstructorDeclaration(ConstructorDeclaration node) {
    node.visitChildren(this);
  }

  void compileConstructorFieldInitializer(ConstructorFieldInitializer node) {
    node.visitChildren(this);
  }

  void compileConstructorName(ConstructorName node) {
    node.visitChildren(this);
  }

  void compileConstructorReference(ConstructorReference node) {
    node.visitChildren(this);
  }

  void compileConstructorSelector(ConstructorSelector node) {
    node.visitChildren(this);
  }

  void compileContinueStatement(ContinueStatement node) {
    node.visitChildren(this);
  }

  void compileDeclaredIdentifier(DeclaredIdentifier node) {
    node.visitChildren(this);
  }

  void compileDeclaredVariablePattern(DeclaredVariablePattern node) {
    node.visitChildren(this);
  }

  void compileDefaultFormalParameter(DefaultFormalParameter node) {
    node.visitChildren(this);
  }

  void compileDoStatement(DoStatement node) {
    node.visitChildren(this);
  }

  void compileDottedName(DottedName node) {
    node.visitChildren(this);
  }

  void compileDoubleLiteral(DoubleLiteral node) {
    node.visitChildren(this);
  }

  void compileEmptyFunctionBody(EmptyFunctionBody node) {
    node.visitChildren(this);
  }

  void compileEmptyStatement(EmptyStatement node) {
    node.visitChildren(this);
  }

  void compileEnumConstantArguments(EnumConstantArguments node) {
    node.visitChildren(this);
  }

  void compileEnumConstantDeclaration(EnumConstantDeclaration node) {
    node.visitChildren(this);
  }

  void compileEnumDeclaration(EnumDeclaration node) {
    node.visitChildren(this);
  }

  void compileExportDirective(ExportDirective node) {
    node.visitChildren(this);
  }

  void compileExpressionFunctionBody(ExpressionFunctionBody node) {
    node.visitChildren(this);
  }

  void compileExpressionStatement(ExpressionStatement node) {
    node.visitChildren(this);
  }

  void compileExtendsClause(ExtendsClause node) {
    node.visitChildren(this);
  }

  void compileExtensionDeclaration(ExtensionDeclaration node) {
    node.visitChildren(this);
  }

  void compileExtensionOverride(ExtensionOverride node) {
    node.visitChildren(this);
  }

  void compileExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    node.visitChildren(this);
  }

  void compileFieldDeclaration(FieldDeclaration node) {
    node.visitChildren(this);
  }

  void compileFieldFormalParameter(FieldFormalParameter node) {
    node.visitChildren(this);
  }

  void compileForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    node.visitChildren(this);
  }

  void compileForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    node.visitChildren(this);
  }

  void compileForEachPartsWithPattern(ForEachPartsWithPattern node) {
    node.visitChildren(this);
  }

  void compileForElement(ForElement node) {
    node.visitChildren(this);
  }

  void compileForPartsWithDeclarations(ForPartsWithDeclarations node) {
    node.visitChildren(this);
  }

  void compileForPartsWithExpression(ForPartsWithExpression node) {
    node.visitChildren(this);
  }

  void compileForPartsWithPattern(ForPartsWithPattern node) {
    node.visitChildren(this);
  }

  void compileForStatement(ForStatement node) {
    node.visitChildren(this);
  }

  void compileFormalParameterList(FormalParameterList node) {
    node.visitChildren(this);
  }

  void compileFunctionDeclaration(FunctionDeclaration node) {
    node.visitChildren(this);
  }

  void compileFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    node.visitChildren(this);
  }

  void compileFunctionExpression(FunctionExpression node) {
    node.visitChildren(this);
  }

  void compileFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.visitChildren(this);
  }

  void compileFunctionReference(FunctionReference node) {
    node.visitChildren(this);
  }

  void compileFunctionTypeAlias(FunctionTypeAlias node) {
    node.visitChildren(this);
  }

  void compileFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    node.visitChildren(this);
  }

  void compileGenericFunctionType(GenericFunctionType node) {
    node.visitChildren(this);
  }

  void compileGenericTypeAlias(GenericTypeAlias node) {
    node.visitChildren(this);
  }

  void compileGuardedPattern(GuardedPattern node) {
    node.visitChildren(this);
  }

  void compileHideCombinator(HideCombinator node) {
    node.visitChildren(this);
  }

  void compileIfElement(IfElement node) {
    node.visitChildren(this);
  }

  void compileIfStatement(IfStatement node) {
    node.visitChildren(this);
  }

  void compileImplementsClause(ImplementsClause node) {
    node.visitChildren(this);
  }

  void compileImplicitCallReference(ImplicitCallReference node) {
    node.visitChildren(this);
  }

  void compileImportDirective(ImportDirective node) {
    node.visitChildren(this);
  }

  void compileImportPrefixReference(ImportPrefixReference node) {
    node.visitChildren(this);
  }

  void compileIndexExpression(IndexExpression node) {
    node.visitChildren(this);
  }

  void compileInstanceCreationExpression(InstanceCreationExpression node) {
    node.visitChildren(this);
  }

  void compileIntegerLiteral(IntegerLiteral node) {
    node.visitChildren(this);
  }

  void compileInterpolationExpression(InterpolationExpression node) {
    node.visitChildren(this);
  }

  void compileInterpolationString(InterpolationString node) {
    node.visitChildren(this);
  }

  void compileIsExpression(IsExpression node) {
    node.visitChildren(this);
  }

  void compileLabel(Label node) {
    node.visitChildren(this);
  }

  void compileLabeledStatement(LabeledStatement node) {
    node.visitChildren(this);
  }

  void compileLibraryAugmentationDirective(LibraryAugmentationDirective node) {
    node.visitChildren(this);
  }

  void compileLibraryDirective(LibraryDirective node) {
    node.visitChildren(this);
  }

  void compileLibraryIdentifier(LibraryIdentifier node) {
    node.visitChildren(this);
  }

  void compileListLiteral(ListLiteral node) {
    node.visitChildren(this);
  }

  void compileListPattern(ListPattern node) {
    node.visitChildren(this);
  }

  void compileLogicalAndPattern(LogicalAndPattern node) {
    node.visitChildren(this);
  }

  void compileLogicalOrPattern(LogicalOrPattern node) {
    node.visitChildren(this);
  }

  void compileMapLiteralEntry(MapLiteralEntry node) {
    node.visitChildren(this);
  }

  void compileMapPattern(MapPattern node) {
    node.visitChildren(this);
  }

  void compileMapPatternEntry(MapPatternEntry node) {
    node.visitChildren(this);
  }

  void compileMethodDeclaration(MethodDeclaration node) {
    node.visitChildren(this);
  }

  void compileMethodInvocation(MethodInvocation node) {
    node.visitChildren(this);
  }

  void compileMixinDeclaration(MixinDeclaration node) {
    node.visitChildren(this);
  }

  void compileNamedExpression(NamedExpression node) {
    node.visitChildren(this);
  }

  void compileNamedType(NamedType node) {
    node.visitChildren(this);
  }

  void compileNativeClause(NativeClause node) {
    node.visitChildren(this);
  }

  void compileNativeFunctionBody(NativeFunctionBody node) {
    node.visitChildren(this);
  }

  void compileNullAssertPattern(NullAssertPattern node) {
    node.visitChildren(this);
  }

  void compileNullCheckPattern(NullCheckPattern node) {
    node.visitChildren(this);
  }

  void compileNullLiteral(NullLiteral node) {
    node.visitChildren(this);
  }

  void compileObjectPattern(ObjectPattern node) {
    node.visitChildren(this);
  }

  void compileOnClause(OnClause node) {
    node.visitChildren(this);
  }

  void compileParenthesizedExpression(ParenthesizedExpression node) {
    node.visitChildren(this);
  }

  void compileParenthesizedPattern(ParenthesizedPattern node) {
    node.visitChildren(this);
  }

  void compilePartDirective(PartDirective node) {
    node.visitChildren(this);
  }

  void compilePartOfDirective(PartOfDirective node) {
    node.visitChildren(this);
  }

  void compilePatternAssignment(PatternAssignment node) {
    node.visitChildren(this);
  }

  void compilePatternField(PatternField node) {
    node.visitChildren(this);
  }

  void compilePatternFieldName(PatternFieldName node) {
    node.visitChildren(this);
  }

  void compilePatternVariableDeclaration(PatternVariableDeclaration node) {
    node.visitChildren(this);
  }

  void compilePatternVariableDeclarationStatement(PatternVariableDeclarationStatement node) {
    node.visitChildren(this);
  }

  void compilePostfixExpression(PostfixExpression node) {
    node.visitChildren(this);
  }

  void compilePrefixExpression(PrefixExpression node) {
    node.visitChildren(this);
  }

  void compilePrefixedIdentifier(PrefixedIdentifier node) {
    node.visitChildren(this);
  }

  void compilePropertyAccess(PropertyAccess node) {
    node.visitChildren(this);
  }

  void compileRecordLiteral(RecordLiteral node) {
    node.visitChildren(this);
  }

  void compileRecordPattern(RecordPattern node) {
    node.visitChildren(this);
  }

  void compileRecordTypeAnnotation(RecordTypeAnnotation node) {
    node.visitChildren(this);
  }

  void compileRecordTypeAnnotationNamedField(RecordTypeAnnotationNamedField node) {
    node.visitChildren(this);
  }

  void compileRecordTypeAnnotationNamedFields(RecordTypeAnnotationNamedFields node) {
    node.visitChildren(this);
  }

  void compileRecordTypeAnnotationPositionalField(RecordTypeAnnotationPositionalField node) {
    node.visitChildren(this);
  }

  void compileRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    node.visitChildren(this);
  }

  void compileRelationalPattern(RelationalPattern node) {
    node.visitChildren(this);
  }

  void compileRepresentationConstructorName(RepresentationConstructorName node) {
    node.visitChildren(this);
  }

  void compileRepresentationDeclaration(RepresentationDeclaration node) {
    node.visitChildren(this);
  }

  void compileRestPatternElement(RestPatternElement node) {
    node.visitChildren(this);
  }

  void compileRethrowExpression(RethrowExpression node) {
    node.visitChildren(this);
  }

  void compileReturnStatement(ReturnStatement node) {
    node.visitChildren(this);
  }

  void compileScriptTag(ScriptTag node) {
    node.visitChildren(this);
  }

  void compileSetOrMapLiteral(SetOrMapLiteral node) {
    node.visitChildren(this);
  }

  void compileShowCombinator(ShowCombinator node) {
    node.visitChildren(this);
  }

  void compileSimpleFormalParameter(SimpleFormalParameter node) {
    node.visitChildren(this);
  }

  void compileSimpleIdentifier(SimpleIdentifier node) {
    node.visitChildren(this);
  }

  void compileSimpleStringLiteral(SimpleStringLiteral node) {
    node.visitChildren(this);
  }

  void compileSpreadElement(SpreadElement node) {
    node.visitChildren(this);
  }

  void compileStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
  }

  void compileSuperConstructorInvocation(SuperConstructorInvocation node) {
    node.visitChildren(this);
  }

  void compileSuperExpression(SuperExpression node) {
    node.visitChildren(this);
  }

  void compileSuperFormalParameter(SuperFormalParameter node) {
    node.visitChildren(this);
  }

  void compileSwitchCase(SwitchCase node) {
    node.visitChildren(this);
  }

  void compileSwitchDefault(SwitchDefault node) {
    node.visitChildren(this);
  }

  void compileSwitchExpression(SwitchExpression node) {
    node.visitChildren(this);
  }

  void compileSwitchExpressionCase(SwitchExpressionCase node) {
    node.visitChildren(this);
  }

  void compileSwitchPatternCase(SwitchPatternCase node) {
    node.visitChildren(this);
  }

  void compileSwitchStatement(SwitchStatement node) {
    node.visitChildren(this);
  }

  void compileSymbolLiteral(SymbolLiteral node) {
    node.visitChildren(this);
  }

  void compileThisExpression(ThisExpression node) {
    node.visitChildren(this);
  }

  void compileThrowExpression(ThrowExpression node) {
    node.visitChildren(this);
  }

  void compileTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.visitChildren(this);
  }

  void compileTryStatement(TryStatement node) {
    node.visitChildren(this);
  }

  void compileTypeArgumentList(TypeArgumentList node) {
    node.visitChildren(this);
  }

  void compileTypeLiteral(TypeLiteral node) {
    node.visitChildren(this);
  }

  void compileTypeParameter(TypeParameter node) {
    node.visitChildren(this);
  }

  void compileTypeParameterList(TypeParameterList node) {
    node.visitChildren(this);
  }

  void compileVariableDeclaration(VariableDeclaration node) {
    node.visitChildren(this);
  }

  void compileVariableDeclarationList(VariableDeclarationList node) {
    node.visitChildren(this);
  }

  void compileVariableDeclarationStatement(VariableDeclarationStatement node) {
    node.visitChildren(this);
  }

  void compileWhenClause(WhenClause node) {
    node.visitChildren(this);
  }

  void compileWhileStatement(WhileStatement node) {
    node.visitChildren(this);
  }

  void compileWildcardPattern(WildcardPattern node) {
    node.visitChildren(this);
  }

  void compileWithClause(WithClause node) {
    node.visitChildren(this);
  }

  void compileYieldStatement(YieldStatement node) {
    node.visitChildren(this);
  }
}

class CompilerAstVisitor extends AstVisitor<void> with CompilerAstVisitorMixin {
  CompilerAstVisitor({required this.debugLine, required this.debugLineInfo});

  int? debugLine;

  final LineInfo? debugLineInfo;

  bool debugUpdateLine(AstNode? node) {
    debugLine = node != null ? debugLineInfo?.getLocation(node.offset).lineNumber : null;
    return true;
  }

  void debugUpdateNode(AstNode? node) {
    assert(debugUpdateLine(node));
  }

  @override
  @nonVirtual
  void visitAdjacentStrings(AdjacentStrings node) {
    assert(debugUpdateLine(node));
    compileAdjacentStrings(node);
  }

  @override
  @nonVirtual
  void visitAnnotation(Annotation node) {
    assert(debugUpdateLine(node));
    compileAnnotation(node);
  }

  @override
  @nonVirtual
  void visitArgumentList(ArgumentList node) {
    assert(debugUpdateLine(node));
    compileArgumentList(node);
  }

  @override
  @nonVirtual
  void visitAsExpression(AsExpression node) {
    assert(debugUpdateLine(node));
    compileAsExpression(node);
  }

  @override
  @nonVirtual
  void visitAssertInitializer(AssertInitializer node) {
    assert(debugUpdateLine(node));
    compileAssertInitializer(node);
  }

  @override
  @nonVirtual
  void visitAssertStatement(AssertStatement node) {
    assert(debugUpdateLine(node));
    compileAssertStatement(node);
  }

  @override
  @nonVirtual
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    assert(debugUpdateLine(node));
    compileAssignedVariablePattern(node);
  }

  @override
  @nonVirtual
  void visitAssignmentExpression(AssignmentExpression node) {
    assert(debugUpdateLine(node));
    compileAssignmentExpression(node);
  }

  @override
  @nonVirtual
  void visitAugmentationImportDirective(AugmentationImportDirective node) {
    assert(debugUpdateLine(node));
    compileAugmentationImportDirective(node);
  }

  @override
  @nonVirtual
  void visitAwaitExpression(AwaitExpression node) {
    assert(debugUpdateLine(node));
    compileAwaitExpression(node);
  }

  @override
  @nonVirtual
  void visitBinaryExpression(BinaryExpression node) {
    assert(debugUpdateLine(node));
    compileBinaryExpression(node);
  }

  @override
  @nonVirtual
  void visitBlock(Block node) {
    assert(debugUpdateLine(node));
    compileBlock(node);
  }

  @override
  @nonVirtual
  void visitBlockFunctionBody(BlockFunctionBody node) {
    assert(debugUpdateLine(node));
    compileBlockFunctionBody(node);
  }

  @override
  @nonVirtual
  void visitBooleanLiteral(BooleanLiteral node) {
    assert(debugUpdateLine(node));
    compileBooleanLiteral(node);
  }

  @override
  @nonVirtual
  void visitBreakStatement(BreakStatement node) {
    assert(debugUpdateLine(node));
    compileBreakStatement(node);
  }

  @override
  @nonVirtual
  void visitCascadeExpression(CascadeExpression node) {
    assert(debugUpdateLine(node));
    compileCascadeExpression(node);
  }

  @override
  @nonVirtual
  void visitCaseClause(CaseClause node) {
    assert(debugUpdateLine(node));
    compileCaseClause(node);
  }

  @override
  @nonVirtual
  void visitCastPattern(CastPattern node) {
    assert(debugUpdateLine(node));
    compileCastPattern(node);
  }

  @override
  @nonVirtual
  void visitCatchClause(CatchClause node) {
    assert(debugUpdateLine(node));
    compileCatchClause(node);
  }

  @override
  @nonVirtual
  void visitCatchClauseParameter(CatchClauseParameter node) {
    assert(debugUpdateLine(node));
    compileCatchClauseParameter(node);
  }

  @override
  @nonVirtual
  void visitClassDeclaration(ClassDeclaration node) {
    assert(debugUpdateLine(node));
    compileClassDeclaration(node);
  }

  @override
  @nonVirtual
  void visitClassTypeAlias(ClassTypeAlias node) {
    assert(debugUpdateLine(node));
    compileClassTypeAlias(node);
  }

  @override
  @nonVirtual
  void visitComment(Comment node) {
    assert(debugUpdateLine(node));
    compileComment(node);
  }

  @override
  @nonVirtual
  void visitCommentReference(CommentReference node) {
    assert(debugUpdateLine(node));
    compileCommentReference(node);
  }

  @override
  @nonVirtual
  void visitCompilationUnit(CompilationUnit node) {
    assert(debugUpdateLine(node));
    compileCompilationUnit(node);
  }

  @override
  @nonVirtual
  void visitConditionalExpression(ConditionalExpression node) {
    assert(debugUpdateLine(node));
    compileConditionalExpression(node);
  }

  @override
  @nonVirtual
  void visitConfiguration(Configuration node) {
    assert(debugUpdateLine(node));
    compileConfiguration(node);
  }

  @override
  @nonVirtual
  void visitConstantPattern(ConstantPattern node) {
    assert(debugUpdateLine(node));
    compileConstantPattern(node);
  }

  @override
  @nonVirtual
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    assert(debugUpdateLine(node));
    compileConstructorDeclaration(node);
  }

  @override
  @nonVirtual
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    assert(debugUpdateLine(node));
    compileConstructorFieldInitializer(node);
  }

  @override
  @nonVirtual
  void visitConstructorName(ConstructorName node) {
    assert(debugUpdateLine(node));
    compileConstructorName(node);
  }

  @override
  @nonVirtual
  void visitConstructorReference(ConstructorReference node) {
    assert(debugUpdateLine(node));
    compileConstructorReference(node);
  }

  @override
  @nonVirtual
  void visitConstructorSelector(ConstructorSelector node) {
    assert(debugUpdateLine(node));
    compileConstructorSelector(node);
  }

  @override
  @nonVirtual
  void visitContinueStatement(ContinueStatement node) {
    assert(debugUpdateLine(node));
    compileContinueStatement(node);
  }

  @override
  @nonVirtual
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    assert(debugUpdateLine(node));
    compileDeclaredIdentifier(node);
  }

  @override
  @nonVirtual
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    assert(debugUpdateLine(node));
    compileDeclaredVariablePattern(node);
  }

  @override
  @nonVirtual
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    assert(debugUpdateLine(node));
    compileDefaultFormalParameter(node);
  }

  @override
  @nonVirtual
  void visitDoStatement(DoStatement node) {
    assert(debugUpdateLine(node));
    compileDoStatement(node);
  }

  @override
  @nonVirtual
  void visitDottedName(DottedName node) {
    assert(debugUpdateLine(node));
    compileDottedName(node);
  }

  @override
  @nonVirtual
  void visitDoubleLiteral(DoubleLiteral node) {
    assert(debugUpdateLine(node));
    compileDoubleLiteral(node);
  }

  @override
  @nonVirtual
  void visitEmptyFunctionBody(EmptyFunctionBody node) {
    assert(debugUpdateLine(node));
    compileEmptyFunctionBody(node);
  }

  @override
  @nonVirtual
  void visitEmptyStatement(EmptyStatement node) {
    assert(debugUpdateLine(node));
    compileEmptyStatement(node);
  }

  @override
  @nonVirtual
  void visitEnumConstantArguments(EnumConstantArguments node) {
    assert(debugUpdateLine(node));
    compileEnumConstantArguments(node);
  }

  @override
  @nonVirtual
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    assert(debugUpdateLine(node));
    compileEnumConstantDeclaration(node);
  }

  @override
  @nonVirtual
  void visitEnumDeclaration(EnumDeclaration node) {
    assert(debugUpdateLine(node));
    compileEnumDeclaration(node);
  }

  @override
  @nonVirtual
  void visitExportDirective(ExportDirective node) {
    assert(debugUpdateLine(node));
    compileExportDirective(node);
  }

  @override
  @nonVirtual
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    assert(debugUpdateLine(node));
    compileExpressionFunctionBody(node);
  }

  @override
  @nonVirtual
  void visitExpressionStatement(ExpressionStatement node) {
    assert(debugUpdateLine(node));
    compileExpressionStatement(node);
  }

  @override
  @nonVirtual
  void visitExtendsClause(ExtendsClause node) {
    assert(debugUpdateLine(node));
    compileExtendsClause(node);
  }

  @override
  @nonVirtual
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    assert(debugUpdateLine(node));
    compileExtensionDeclaration(node);
  }

  @override
  @nonVirtual
  void visitExtensionOverride(ExtensionOverride node) {
    assert(debugUpdateLine(node));
    compileExtensionOverride(node);
  }

  @override
  @nonVirtual
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    assert(debugUpdateLine(node));
    compileExtensionTypeDeclaration(node);
  }

  @override
  @nonVirtual
  void visitFieldDeclaration(FieldDeclaration node) {
    assert(debugUpdateLine(node));
    compileFieldDeclaration(node);
  }

  @override
  @nonVirtual
  void visitFieldFormalParameter(FieldFormalParameter node) {
    assert(debugUpdateLine(node));
    compileFieldFormalParameter(node);
  }

  @override
  @nonVirtual
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    assert(debugUpdateLine(node));
    compileForEachPartsWithDeclaration(node);
  }

  @override
  @nonVirtual
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    assert(debugUpdateLine(node));
    compileForEachPartsWithIdentifier(node);
  }

  @override
  @nonVirtual
  void visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    assert(debugUpdateLine(node));
    compileForEachPartsWithPattern(node);
  }

  @override
  @nonVirtual
  void visitForElement(ForElement node) {
    assert(debugUpdateLine(node));
    compileForElement(node);
  }

  @override
  @nonVirtual
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    assert(debugUpdateLine(node));
    compileForPartsWithDeclarations(node);
  }

  @override
  @nonVirtual
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    assert(debugUpdateLine(node));
    compileForPartsWithExpression(node);
  }

  @override
  @nonVirtual
  void visitForPartsWithPattern(ForPartsWithPattern node) {
    assert(debugUpdateLine(node));
    compileForPartsWithPattern(node);
  }

  @override
  @nonVirtual
  void visitForStatement(ForStatement node) {
    assert(debugUpdateLine(node));
    compileForStatement(node);
  }

  @override
  @nonVirtual
  void visitFormalParameterList(FormalParameterList node) {
    assert(debugUpdateLine(node));
    compileFormalParameterList(node);
  }

  @override
  @nonVirtual
  void visitFunctionDeclaration(FunctionDeclaration node) {
    assert(debugUpdateLine(node));
    compileFunctionDeclaration(node);
  }

  @override
  @nonVirtual
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    assert(debugUpdateLine(node));
    compileFunctionDeclarationStatement(node);
  }

  @override
  @nonVirtual
  void visitFunctionExpression(FunctionExpression node) {
    assert(debugUpdateLine(node));
    compileFunctionExpression(node);
  }

  @override
  @nonVirtual
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    assert(debugUpdateLine(node));
    compileFunctionExpressionInvocation(node);
  }

  @override
  @nonVirtual
  void visitFunctionReference(FunctionReference node) {
    assert(debugUpdateLine(node));
    compileFunctionReference(node);
  }

  @override
  @nonVirtual
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    assert(debugUpdateLine(node));
    compileFunctionTypeAlias(node);
  }

  @override
  @nonVirtual
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    assert(debugUpdateLine(node));
    compileFunctionTypedFormalParameter(node);
  }

  @override
  @nonVirtual
  void visitGenericFunctionType(GenericFunctionType node) {
    assert(debugUpdateLine(node));
    compileGenericFunctionType(node);
  }

  @override
  @nonVirtual
  void visitGenericTypeAlias(GenericTypeAlias node) {
    assert(debugUpdateLine(node));
    compileGenericTypeAlias(node);
  }

  @override
  @nonVirtual
  void visitGuardedPattern(GuardedPattern node) {
    assert(debugUpdateLine(node));
    compileGuardedPattern(node);
  }

  @override
  @nonVirtual
  void visitHideCombinator(HideCombinator node) {
    assert(debugUpdateLine(node));
    compileHideCombinator(node);
  }

  @override
  @nonVirtual
  void visitIfElement(IfElement node) {
    assert(debugUpdateLine(node));
    compileIfElement(node);
  }

  @override
  @nonVirtual
  void visitIfStatement(IfStatement node) {
    assert(debugUpdateLine(node));
    compileIfStatement(node);
  }

  @override
  @nonVirtual
  void visitImplementsClause(ImplementsClause node) {
    assert(debugUpdateLine(node));
    compileImplementsClause(node);
  }

  @override
  @nonVirtual
  void visitImplicitCallReference(ImplicitCallReference node) {
    assert(debugUpdateLine(node));
    compileImplicitCallReference(node);
  }

  @override
  @nonVirtual
  void visitImportDirective(ImportDirective node) {
    assert(debugUpdateLine(node));
    compileImportDirective(node);
  }

  @override
  @nonVirtual
  void visitImportPrefixReference(ImportPrefixReference node) {
    assert(debugUpdateLine(node));
    compileImportPrefixReference(node);
  }

  @override
  @nonVirtual
  void visitIndexExpression(IndexExpression node) {
    assert(debugUpdateLine(node));
    compileIndexExpression(node);
  }

  @override
  @nonVirtual
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    assert(debugUpdateLine(node));
    compileInstanceCreationExpression(node);
  }

  @override
  @nonVirtual
  void visitIntegerLiteral(IntegerLiteral node) {
    assert(debugUpdateLine(node));
    compileIntegerLiteral(node);
  }

  @override
  @nonVirtual
  void visitInterpolationExpression(InterpolationExpression node) {
    assert(debugUpdateLine(node));
    compileInterpolationExpression(node);
  }

  @override
  @nonVirtual
  void visitInterpolationString(InterpolationString node) {
    assert(debugUpdateLine(node));
    compileInterpolationString(node);
  }

  @override
  @nonVirtual
  void visitIsExpression(IsExpression node) {
    assert(debugUpdateLine(node));
    compileIsExpression(node);
  }

  @override
  @nonVirtual
  void visitLabel(Label node) {
    assert(debugUpdateLine(node));
    compileLabel(node);
  }

  @override
  @nonVirtual
  void visitLabeledStatement(LabeledStatement node) {
    assert(debugUpdateLine(node));
    compileLabeledStatement(node);
  }

  @override
  @nonVirtual
  void visitLibraryAugmentationDirective(LibraryAugmentationDirective node) {
    assert(debugUpdateLine(node));
    compileLibraryAugmentationDirective(node);
  }

  @override
  @nonVirtual
  void visitLibraryDirective(LibraryDirective node) {
    assert(debugUpdateLine(node));
    compileLibraryDirective(node);
  }

  @override
  @nonVirtual
  void visitLibraryIdentifier(LibraryIdentifier node) {
    assert(debugUpdateLine(node));
    compileLibraryIdentifier(node);
  }

  @override
  @nonVirtual
  void visitListLiteral(ListLiteral node) {
    assert(debugUpdateLine(node));
    compileListLiteral(node);
  }

  @override
  @nonVirtual
  void visitListPattern(ListPattern node) {
    assert(debugUpdateLine(node));
    compileListPattern(node);
  }

  @override
  @nonVirtual
  void visitLogicalAndPattern(LogicalAndPattern node) {
    assert(debugUpdateLine(node));
    compileLogicalAndPattern(node);
  }

  @override
  @nonVirtual
  void visitLogicalOrPattern(LogicalOrPattern node) {
    assert(debugUpdateLine(node));
    compileLogicalOrPattern(node);
  }

  @override
  @nonVirtual
  void visitMapLiteralEntry(MapLiteralEntry node) {
    assert(debugUpdateLine(node));
    compileMapLiteralEntry(node);
  }

  @override
  @nonVirtual
  void visitMapPattern(MapPattern node) {
    assert(debugUpdateLine(node));
    compileMapPattern(node);
  }

  @override
  @nonVirtual
  void visitMapPatternEntry(MapPatternEntry node) {
    assert(debugUpdateLine(node));
    compileMapPatternEntry(node);
  }

  @override
  @nonVirtual
  void visitMethodDeclaration(MethodDeclaration node) {
    assert(debugUpdateLine(node));
    compileMethodDeclaration(node);
  }

  @override
  @nonVirtual
  void visitMethodInvocation(MethodInvocation node) {
    assert(debugUpdateLine(node));
    compileMethodInvocation(node);
  }

  @override
  @nonVirtual
  void visitMixinDeclaration(MixinDeclaration node) {
    assert(debugUpdateLine(node));
    compileMixinDeclaration(node);
  }

  @override
  @nonVirtual
  void visitNamedExpression(NamedExpression node) {
    assert(debugUpdateLine(node));
    compileNamedExpression(node);
  }

  @override
  @nonVirtual
  void visitNamedType(NamedType node) {
    assert(debugUpdateLine(node));
    compileNamedType(node);
  }

  @override
  @nonVirtual
  void visitNativeClause(NativeClause node) {
    assert(debugUpdateLine(node));
    compileNativeClause(node);
  }

  @override
  @nonVirtual
  void visitNativeFunctionBody(NativeFunctionBody node) {
    assert(debugUpdateLine(node));
    compileNativeFunctionBody(node);
  }

  @override
  @nonVirtual
  void visitNullAssertPattern(NullAssertPattern node) {
    assert(debugUpdateLine(node));
    compileNullAssertPattern(node);
  }

  @override
  @nonVirtual
  void visitNullCheckPattern(NullCheckPattern node) {
    assert(debugUpdateLine(node));
    compileNullCheckPattern(node);
  }

  @override
  @nonVirtual
  void visitNullLiteral(NullLiteral node) {
    assert(debugUpdateLine(node));
    compileNullLiteral(node);
  }

  @override
  @nonVirtual
  void visitObjectPattern(ObjectPattern node) {
    assert(debugUpdateLine(node));
    compileObjectPattern(node);
  }

  @override
  @nonVirtual
  void visitOnClause(OnClause node) {
    assert(debugUpdateLine(node));
    compileOnClause(node);
  }

  @override
  @nonVirtual
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    assert(debugUpdateLine(node));
    compileParenthesizedExpression(node);
  }

  @override
  @nonVirtual
  void visitParenthesizedPattern(ParenthesizedPattern node) {
    assert(debugUpdateLine(node));
    compileParenthesizedPattern(node);
  }

  @override
  @nonVirtual
  void visitPartDirective(PartDirective node) {
    assert(debugUpdateLine(node));
    compilePartDirective(node);
  }

  @override
  @nonVirtual
  void visitPartOfDirective(PartOfDirective node) {
    assert(debugUpdateLine(node));
    compilePartOfDirective(node);
  }

  @override
  @nonVirtual
  void visitPatternAssignment(PatternAssignment node) {
    assert(debugUpdateLine(node));
    compilePatternAssignment(node);
  }

  @override
  @nonVirtual
  void visitPatternField(PatternField node) {
    assert(debugUpdateLine(node));
    compilePatternField(node);
  }

  @override
  @nonVirtual
  void visitPatternFieldName(PatternFieldName node) {
    assert(debugUpdateLine(node));
    compilePatternFieldName(node);
  }

  @override
  @nonVirtual
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    assert(debugUpdateLine(node));
    compilePatternVariableDeclaration(node);
  }

  @override
  @nonVirtual
  void visitPatternVariableDeclarationStatement(PatternVariableDeclarationStatement node) {
    assert(debugUpdateLine(node));
    compilePatternVariableDeclarationStatement(node);
  }

  @override
  @nonVirtual
  void visitPostfixExpression(PostfixExpression node) {
    assert(debugUpdateLine(node));
    compilePostfixExpression(node);
  }

  @override
  @nonVirtual
  void visitPrefixExpression(PrefixExpression node) {
    assert(debugUpdateLine(node));
    compilePrefixExpression(node);
  }

  @override
  @nonVirtual
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    assert(debugUpdateLine(node));
    compilePrefixedIdentifier(node);
  }

  @override
  @nonVirtual
  void visitPropertyAccess(PropertyAccess node) {
    assert(debugUpdateLine(node));
    compilePropertyAccess(node);
  }

  @override
  @nonVirtual
  void visitRecordLiteral(RecordLiteral node) {
    assert(debugUpdateLine(node));
    compileRecordLiteral(node);
  }

  @override
  @nonVirtual
  void visitRecordPattern(RecordPattern node) {
    assert(debugUpdateLine(node));
    compileRecordPattern(node);
  }

  @override
  @nonVirtual
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    assert(debugUpdateLine(node));
    compileRecordTypeAnnotation(node);
  }

  @override
  @nonVirtual
  void visitRecordTypeAnnotationNamedField(RecordTypeAnnotationNamedField node) {
    assert(debugUpdateLine(node));
    compileRecordTypeAnnotationNamedField(node);
  }

  @override
  @nonVirtual
  void visitRecordTypeAnnotationNamedFields(RecordTypeAnnotationNamedFields node) {
    assert(debugUpdateLine(node));
    compileRecordTypeAnnotationNamedFields(node);
  }

  @override
  @nonVirtual
  void visitRecordTypeAnnotationPositionalField(RecordTypeAnnotationPositionalField node) {
    assert(debugUpdateLine(node));
    compileRecordTypeAnnotationPositionalField(node);
  }

  @override
  @nonVirtual
  void visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    assert(debugUpdateLine(node));
    compileRedirectingConstructorInvocation(node);
  }

  @override
  @nonVirtual
  void visitRelationalPattern(RelationalPattern node) {
    assert(debugUpdateLine(node));
    compileRelationalPattern(node);
  }

  @override
  @nonVirtual
  void visitRepresentationConstructorName(RepresentationConstructorName node) {
    assert(debugUpdateLine(node));
    compileRepresentationConstructorName(node);
  }

  @override
  @nonVirtual
  void visitRepresentationDeclaration(RepresentationDeclaration node) {
    assert(debugUpdateLine(node));
    compileRepresentationDeclaration(node);
  }

  @override
  @nonVirtual
  void visitRestPatternElement(RestPatternElement node) {
    assert(debugUpdateLine(node));
    compileRestPatternElement(node);
  }

  @override
  @nonVirtual
  void visitRethrowExpression(RethrowExpression node) {
    assert(debugUpdateLine(node));
    compileRethrowExpression(node);
  }

  @override
  @nonVirtual
  void visitReturnStatement(ReturnStatement node) {
    assert(debugUpdateLine(node));
    compileReturnStatement(node);
  }

  @override
  @nonVirtual
  void visitScriptTag(ScriptTag node) {
    assert(debugUpdateLine(node));
    compileScriptTag(node);
  }

  @override
  @nonVirtual
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    assert(debugUpdateLine(node));
    compileSetOrMapLiteral(node);
  }

  @override
  @nonVirtual
  void visitShowCombinator(ShowCombinator node) {
    assert(debugUpdateLine(node));
    compileShowCombinator(node);
  }

  @override
  @nonVirtual
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    assert(debugUpdateLine(node));
    compileSimpleFormalParameter(node);
  }

  @override
  @nonVirtual
  void visitSimpleIdentifier(SimpleIdentifier node) {
    assert(debugUpdateLine(node));
    compileSimpleIdentifier(node);
  }

  @override
  @nonVirtual
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    assert(debugUpdateLine(node));
    compileSimpleStringLiteral(node);
  }

  @override
  @nonVirtual
  void visitSpreadElement(SpreadElement node) {
    assert(debugUpdateLine(node));
    compileSpreadElement(node);
  }

  @override
  @nonVirtual
  void visitStringInterpolation(StringInterpolation node) {
    assert(debugUpdateLine(node));
    compileStringInterpolation(node);
  }

  @override
  @nonVirtual
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    assert(debugUpdateLine(node));
    compileSuperConstructorInvocation(node);
  }

  @override
  @nonVirtual
  void visitSuperExpression(SuperExpression node) {
    assert(debugUpdateLine(node));
    compileSuperExpression(node);
  }

  @override
  @nonVirtual
  void visitSuperFormalParameter(SuperFormalParameter node) {
    assert(debugUpdateLine(node));
    compileSuperFormalParameter(node);
  }

  @override
  @nonVirtual
  void visitSwitchCase(SwitchCase node) {
    assert(debugUpdateLine(node));
    compileSwitchCase(node);
  }

  @override
  @nonVirtual
  void visitSwitchDefault(SwitchDefault node) {
    assert(debugUpdateLine(node));
    compileSwitchDefault(node);
  }

  @override
  @nonVirtual
  void visitSwitchExpression(SwitchExpression node) {
    assert(debugUpdateLine(node));
    compileSwitchExpression(node);
  }

  @override
  @nonVirtual
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    assert(debugUpdateLine(node));
    compileSwitchExpressionCase(node);
  }

  @override
  @nonVirtual
  void visitSwitchPatternCase(SwitchPatternCase node) {
    assert(debugUpdateLine(node));
    compileSwitchPatternCase(node);
  }

  @override
  @nonVirtual
  void visitSwitchStatement(SwitchStatement node) {
    assert(debugUpdateLine(node));
    compileSwitchStatement(node);
  }

  @override
  @nonVirtual
  void visitSymbolLiteral(SymbolLiteral node) {
    assert(debugUpdateLine(node));
    compileSymbolLiteral(node);
  }

  @override
  @nonVirtual
  void visitThisExpression(ThisExpression node) {
    assert(debugUpdateLine(node));
    compileThisExpression(node);
  }

  @override
  @nonVirtual
  void visitThrowExpression(ThrowExpression node) {
    assert(debugUpdateLine(node));
    compileThrowExpression(node);
  }

  @override
  @nonVirtual
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    assert(debugUpdateLine(node));
    compileTopLevelVariableDeclaration(node);
  }

  @override
  @nonVirtual
  void visitTryStatement(TryStatement node) {
    assert(debugUpdateLine(node));
    compileTryStatement(node);
  }

  @override
  @nonVirtual
  void visitTypeArgumentList(TypeArgumentList node) {
    assert(debugUpdateLine(node));
    compileTypeArgumentList(node);
  }

  @override
  @nonVirtual
  void visitTypeLiteral(TypeLiteral node) {
    assert(debugUpdateLine(node));
    compileTypeLiteral(node);
  }

  @override
  @nonVirtual
  void visitTypeParameter(TypeParameter node) {
    assert(debugUpdateLine(node));
    compileTypeParameter(node);
  }

  @override
  @nonVirtual
  void visitTypeParameterList(TypeParameterList node) {
    assert(debugUpdateLine(node));
    compileTypeParameterList(node);
  }

  @override
  @nonVirtual
  void visitVariableDeclaration(VariableDeclaration node) {
    assert(debugUpdateLine(node));
    compileVariableDeclaration(node);
  }

  @override
  @nonVirtual
  void visitVariableDeclarationList(VariableDeclarationList node) {
    assert(debugUpdateLine(node));
    compileVariableDeclarationList(node);
  }

  @override
  @nonVirtual
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    assert(debugUpdateLine(node));
    compileVariableDeclarationStatement(node);
  }

  @override
  @nonVirtual
  void visitWhenClause(WhenClause node) {
    assert(debugUpdateLine(node));
    compileWhenClause(node);
  }

  @override
  @nonVirtual
  void visitWhileStatement(WhileStatement node) {
    assert(debugUpdateLine(node));
    compileWhileStatement(node);
  }

  @override
  @nonVirtual
  void visitWildcardPattern(WildcardPattern node) {
    assert(debugUpdateLine(node));
    compileWildcardPattern(node);
  }

  @override
  @nonVirtual
  void visitWithClause(WithClause node) {
    assert(debugUpdateLine(node));
    compileWithClause(node);
  }

  @override
  @nonVirtual
  void visitYieldStatement(YieldStatement node) {
    assert(debugUpdateLine(node));
    compileYieldStatement(node);
  }
}
