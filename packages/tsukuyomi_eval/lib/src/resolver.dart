// ignore_for_file: implementation_imports
import 'dart:convert';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';

import 'object.dart';
import 'property.dart';

typedef _DartMethodParameters = ({bool Function(Object?) accepts, DartParameters parameters});

typedef _DartMethodDeclaration = ({InterfaceElement type, _DartMethodParameters method});

Future<ResolvedUnitResult> resolve(String content, List<DartLibrary> libraries) {
  // TODO 判断是否可以通过每次都重新创建一个名称唯一的文件并在解析完成后清除以优化运行时间
  return _Resolver(libraries).resolve(content);
}

Map<String, Property> resolveProperties(ResolvedUnitResult resolved, List<DartLibrary> libraries) {
  final declarations = <String, DartLibrary>{};
  for (final library in libraries) {
    final path = resolved.session.uriConverter.uriToPath(Uri.parse(library.uri));
    if (path != null) declarations[path] = library;
  }
  final props = libraries.props;
  final visited = <LibraryElement>{};

  void registerLibrary(LibraryElement library) {
    if (!visited.add(library)) return;
    // 主文件和 part 的匹配器、桥接父类都使用 analyzer 解析出的所属库身份
    for (final unit in library.units) {
      final declaration = declarations[unit.source.fullName];
      if (declaration == null) continue;
      for (final entry in declaration.props.entries) {
        if (entry.key.endsWith('.with') || entry.key.endsWith('.class')) {
          props['${library.source.uri}::${entry.key}'] = entry.value;
        }
      }
    }
    for (final dependency in [...library.importedLibraries, ...library.exportedLibraries]) {
      registerLibrary(dependency);
    }
  }

  registerLibrary(resolved.libraryElement);
  final methods = <String, List<_DartMethodDeclaration>>{};
  for (final library in visited) {
    final types = <String, InterfaceElement>{
      for (final unit in library.units) ...{
        for (final type in unit.classes) type.name: type,
        for (final alias in unit.typeAliases) ...{
          if (alias.aliasedType case final InterfaceType type) alias.name: type.element,
        },
      },
    };
    for (final unit in library.units) {
      final declaration = declarations[unit.source.fullName];
      if (declaration == null) continue;
      for (final entry in declaration.props.entries) {
        if (!entry.key.endsWith('.with')) continue;
        final name = entry.key.substring(0, entry.key.length - '.with'.length);
        final type = types[name];
        final accepts = entry.value.typeMatcher;
        if (type == null || accepts == null) continue;
        for (final method in type.methods) {
          if (method.isStatic) continue;
          final key = method.isOperator ? method.name : '.${method.name}';
          final parameters = _resolveParameters(method.parameters);
          final methodParameters = (accepts: accepts, parameters: parameters);
          methods.putIfAbsent(key, () => []).add((type: type, method: methodParameters));
        }
      }
    }
  }
  for (final entry in methods.entries) {
    final property = props[entry.key];
    if (property is! DartProperty) continue;
    props[entry.key] = DartProperty(
      getter: property.getter,
      setter: property.setter,
      parameters: _resolveMethodParameters(_orderMethodParameters(entry.value)),
    );
  }
  return props;
}

DartParameters _resolveParameters(List<ParameterElement> parameters) {
  final positional = parameters.where((parameter) => parameter.isPositional).toList();
  return (
    positionalCallbacks: {
      for (var i = 0; i < positional.length; i++) ...{
        if (positional[i].type is FunctionType) i,
      },
    },
    namedCallbacks: {
      for (final parameter in parameters) ...{
        if (parameter.isNamed && parameter.type is FunctionType) Symbol(parameter.name),
      },
    },
  );
}

List<_DartMethodParameters> _orderMethodParameters(List<_DartMethodDeclaration> declarations) {
  final ordered = <_DartMethodDeclaration>[];
  for (final declaration in declarations.reversed) {
    final supertypes = declaration.type.allSupertypes.map((type) => type.element).toSet();
    // 子类覆写优先于父类，其他声明保留原来的匹配顺序
    final index = ordered.indexWhere((other) => supertypes.contains(other.type));
    ordered.insert(index < 0 ? ordered.length : index, declaration);
  }
  return [for (final declaration in ordered) declaration.method];
}

DartParameters? Function(Object?) _resolveMethodParameters(List<_DartMethodParameters> methods) {
  // 运行时只保留宿主匹配器和参数角色，避免闭包携带 analyzer 状态进入 isolate
  return (receiver) {
    if (receiver is Obj) return null;
    for (final method in methods) {
      if (method.accepts(receiver)) return method.parameters;
    }
    return null;
  };
}

class _Resolver with ResourceProviderMixin {
  _Resolver(List<DartLibrary> libraries) {
    final lib = sdkRoot.getChildAssumingFolder('lib');
    final libInternal = lib.getChildAssumingFolder('_internal');
    final librariesBuffer = StringBuffer();
    final packageConfigFileBuilder = PackageConfigFileBuilder();
    librariesBuffer.writeln('const Map<String, LibraryInfo> libraries = const {');
    for (final library in libraries) {
      if (library.name.startsWith('dart:')) {
        // 核心依赖库
        lib.getChildAssumingFile(library.path).writeAsStringSync(library.source);
        librariesBuffer.writeln('  "${library.name.split('dart:').last}": const LibraryInfo("${library.path}"),');
      } else {
        // 其他依赖库
        final packageRoot = packagesRoot.getChildAssumingFolder(library.name);
        packageRoot.getChildAssumingFile(join('lib', library.path)).writeAsStringSync(library.source);
        // TODO 优化同个依赖库多个导出文件的处理，如：将一个 library 分为多个 unit 对象并遍历处理
        if (packageRoot.getChildAssumingFolder('lib').getChildren().length == 1) {
          packageConfigFileBuilder.add(name: library.name, rootPath: packageRoot.path);
        }
      }
    }
    librariesBuffer.writeln('};');
    libInternal.getChildAssumingFile('sdk_library_metadata/lib/libraries.dart').writeAsStringSync('$librariesBuffer');
    libInternal.getChildAssumingFile('allowed_experiments.json').writeAsStringSync(json.encode({}));
    newPackageConfigJsonFile(workspaceRoot.path, packageConfigFileBuilder.toContent(toUriStr: toUriStr));
    sdkRoot.getChildAssumingFile('version').writeAsStringSync('${ExperimentStatus.currentVersion}');
  }

  Folder get sdkRoot => newFolder('/sdk');

  Folder get workspaceRoot => newFolder('/home');

  Folder get packagesRoot => newFolder('/packages');

  late final AnalysisContextCollection analysisContextCollection = () {
    // TODO 判断是否需要通过自定义参数以优化运行速度，如：byteStore、enableIndex、fileContentCache...
    return AnalysisContextCollectionImpl(
      includedPaths: [workspaceRoot.path],
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
    );
  }();

  Future<ResolvedUnitResult> resolve(String content) async {
    final mainFile = workspaceRoot.getChildAssumingFile('main.dart')..writeAsStringSync(content);
    final analysisContext = analysisContextCollection.contextFor(mainFile.path);
    final analysisSession = analysisContext.currentSession;
    return await analysisSession.getResolvedUnit(mainFile.path) as ResolvedUnitResult;
  }
}
