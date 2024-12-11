abstract class Source {
  abstract final int id;

  abstract final String name;

  Future<String> getCover(String url);
}

abstract class HttpSource extends Source {
  @override
  late final int id = name.hashCode;

  abstract final String url;
}

class StubSource extends HttpSource {
  @override
  late String name;

  @override
  late String url;

  @override
  Future<String> getCover(String name) async => '$url$name';
}

final props = <String, Function>{
  'HttpSource': StubSource.new,
  'id': (StubSource source) => source.id,
  'name': (StubSource source) => source.name,
  'name.set': (StubSource source, String name) => source.name = name,
  'url': (StubSource source) => source.url,
  'url.set': (StubSource source, String url) => source.url = url,
  'getCover': (StubSource source) => source.getCover,
};

void main() async {
  final source = props['HttpSource']!();
  props['name.set']!(source, 'stub');
  props['url.set']!(source, 'https://example.com/');
  print('source.id = "${props['id']!(source)}"');
  print('source.name = "${props['name']!(source)}"');
  print('source.url = "${props['url']!(source)}"');
  print('source.getCover = "${await props['getCover']!(source)('cover')}"');
}
