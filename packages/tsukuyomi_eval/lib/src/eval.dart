import 'check.dart';
import 'compiler.dart';
import 'declaration/declaration.dart';
import 'property.dart';
import 'resolver.dart';
import 'vm.dart';

dynamic eval(String source, {List<DartLibrary> libraries = const [], bool debug = false}) async {
  assert(isLibrariesValid([...dartLibraries, ...libraries]));
  final context = [...dartLibraries, ...libraries];
  final resolved = await resolve(source, context);
  final compiler = Compiler(debug: debug, debugLineInfo: resolved.lineInfo);
  final function = compiler.compile(node: resolved.unit);
  return VM(debug: debug, globals: context.props).interpret(function);
}
