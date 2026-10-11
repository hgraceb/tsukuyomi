// ignore_for_file: implementation_imports
import 'dart:convert';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';

import 'property.dart';

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
  return props;
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
