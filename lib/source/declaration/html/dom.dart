import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_html/dom.dart';

DartClass get _$CssClassSet => DartClass<CssClassSet>(($) => '''
abstract class CssClassSet implements Set<String> {
  // ${$.debug('toggle', ($, $$) => $.toggle)}
  bool toggle(String value, [bool? shouldAdd]);

  // ${$.debug('frozen', ($, $$) => $.frozen)}
  bool get frozen;

  // ${$.debug('toggleAll', ($, $$) => $.toggleAll)}
  void toggleAll(Iterable<String> iterable, [bool? shouldAdd]);
}
''');

DartClass get _$AttributeName => DartClass<AttributeName>(($) => '''
class AttributeName implements Comparable<Object> {
  // ${$.debug('prefix', ($, $$) => $.prefix)}
  final String? prefix;

  // ${$.debug('name', ($, $$) => $.name)}
  final String name;

  // ${$.debug('namespace', ($, $$) => $.namespace)}
  final String namespace;

  // ${$.empty('AttributeName.new', () => AttributeName.new)}
  const AttributeName(this.prefix, this.name, this.namespace);
}
''');

DartClass get __$ParentNode => DartClass<Document>(($) => '''
mixin _ParentNode implements Node {
  // ${$.debug('querySelector', ($, $$) => $.querySelector)}
  external Element? querySelector(String selector);

  // ${$.debug('querySelectorAll', ($, $$) => $.querySelectorAll)}
  external List<Element> querySelectorAll(String selector);
}
''');

DartClass get __$NonElementParentNode => DartClass<Document>(($) => '''
mixin _NonElementParentNode implements _ParentNode {
  // ${$.debug('getElementById', ($, $$) => $.getElementById)}
  external Element? getElementById(String id);
}
''');

DartClass get __$ElementAndDocument => DartClass<Document>(($) => '''
abstract class _ElementAndDocument implements _ParentNode {
  // ${$.debug('getElementsByTagName', ($, $$) => $.getElementsByTagName)}
  external List<Element> getElementsByTagName(String localName);

  // ${$.debug('getElementsByClassName', ($, $$) => $.getElementsByClassName)}
  external List<Element> getElementsByClassName(String classNames);
}
''');

DartClass get _$Node => DartClass<Node>(($) => '''
abstract class Node {
  // ${$.empty('Node.ATTRIBUTE_NODE', () => Node.ATTRIBUTE_NODE)}
  static const int ATTRIBUTE_NODE = 2;
  // ${$.empty('Node.CDATA_SECTION_NODE', () => Node.CDATA_SECTION_NODE)}
  static const int CDATA_SECTION_NODE = 4;
  // ${$.empty('Node.COMMENT_NODE', () => Node.COMMENT_NODE)}
  static const int COMMENT_NODE = 8;
  // ${$.empty('Node.DOCUMENT_FRAGMENT_NODE', () => Node.DOCUMENT_FRAGMENT_NODE)}
  static const int DOCUMENT_FRAGMENT_NODE = 11;
  // ${$.empty('Node.DOCUMENT_NODE', () => Node.DOCUMENT_NODE)}
  static const int DOCUMENT_NODE = 9;
  // ${$.empty('Node.DOCUMENT_TYPE_NODE', () => Node.DOCUMENT_TYPE_NODE)}
  static const int DOCUMENT_TYPE_NODE = 10;
  // ${$.empty('Node.ELEMENT_NODE', () => Node.ELEMENT_NODE)}
  static const int ELEMENT_NODE = 1;
  // ${$.empty('Node.ENTITY_NODE', () => Node.ENTITY_NODE)}
  static const int ENTITY_NODE = 6;
  // ${$.empty('Node.ENTITY_REFERENCE_NODE', () => Node.ENTITY_REFERENCE_NODE)}
  static const int ENTITY_REFERENCE_NODE = 5;
  // ${$.empty('Node.NOTATION_NODE', () => Node.NOTATION_NODE)}
  static const int NOTATION_NODE = 12;
  // ${$.empty('Node.PROCESSING_INSTRUCTION_NODE', () => Node.PROCESSING_INSTRUCTION_NODE)}
  static const int PROCESSING_INSTRUCTION_NODE = 7;
  // ${$.empty('Node.TEXT_NODE', () => Node.TEXT_NODE)}
  static const int TEXT_NODE = 3;

  Node._();

  // ${$.debug('parentNode', ($, $$) => $.parentNode = $.parentNode)}
  Node? parentNode;

  // ${$.debug('parent', ($, $$) => $.parent)}
  external Element? get parent;

  // ${$.debug('attributes', ($, $$) => $.attributes = $.attributes)}
  external LinkedHashMap<Object, String> attributes;

  // ${$.debug('nodes', ($, $$) => $.nodes)}
  external final NodeList nodes;

  // ${$.debug('children', ($, $$) => $.children)}
  external final List<Element> children;

  // ${$.debug('sourceSpan', ($, $$) => $.sourceSpan = $.sourceSpan)}
  FileSpan? sourceSpan;

  // ${$.debug('attributeSpans', ($, $$) => $.attributeSpans)}
  external LinkedHashMap<Object, FileSpan>? get attributeSpans;

  // ${$.debug('attributeValueSpans', ($, $$) => $.attributeValueSpans)}
  external LinkedHashMap<Object, FileSpan>? get attributeValueSpans;

  // ${$.debug('clone', ($, $$) => $.clone)}
  Node clone(bool deep);

  // ${$.debug('nodeType', ($, $$) => $.nodeType)}
  int get nodeType;

  // ${$.debug('text', ($, $$) => $.text)}
  external String? get text;

  // ${$.debug('text', ($, $$) => $.text = $$)}
  external set text(String? value);

  // ${$.debug('append', ($, $$) => $.append)}
  external void append(Node node);

  // ${$.debug('firstChild', ($, $$) => $.firstChild)}
  external Node? get firstChild;

  // ${$.debug('remove', ($, $$) => $.remove)}
  external Node remove();

  // ${$.debug('insertBefore', ($, $$) => $.insertBefore)}
  external void insertBefore(Node node, Node? refNode);

  // ${$.debug('replaceWith', ($, $$) => $.replaceWith)}
  external Node replaceWith(Node otherNode);

  // ${$.debug('hasContent', ($, $$) => $.hasContent)}
  external bool hasContent();

  // ${$.debug('reparentChildren', ($, $$) => $.reparentChildren)}
  external void reparentChildren(Node newParent);

  // ${$.debug('hasChildNodes', ($, $$) => $.hasChildNodes)}
  external bool hasChildNodes();

  // ${$.debug('contains', ($, $$) => $.contains)}
  external bool contains(Node node);
}
''');

DartClass get _$Document => DartClass<Document>(($) => '''
class Document extends Node with _ParentNode, _NonElementParentNode, _ElementAndDocument {
  // ${$.empty('Document.new', () => Document.new)}
  external Document();

  // ${$.empty('Document.html', () => Document.html)}
  external factory Document.html(String html);

  // ${$.debug('documentElement', ($, $$) => $.documentElement)}
  external Element? get documentElement;

  // ${$.debug('head', ($, $$) => $.head)}
  external Element? get head;

  // ${$.debug('body', ($, $$) => $.body)}
  external Element? get body;

  // ${$.debug('outerHtml', ($, $$) => $.outerHtml)}
  external String get outerHtml;

  // ${$.debug('createElement', ($, $$) => $.createElement)}
  external Element createElement(String tag);

  // ${$.debug('createElementNS', ($, $$) => $.createElementNS)}
  external Element createElementNS(String? namespaceUri, String? tag);

  // ${$.debug('createDocumentFragment', ($, $$) => $.createDocumentFragment)}
  external DocumentFragment createDocumentFragment();
}
''');

DartClass get _$DocumentFragment => DartClass<DocumentFragment>(($) => '''
class DocumentFragment extends Node with _ParentNode, _NonElementParentNode {
  // ${$.empty('DocumentFragment.new', () => DocumentFragment.new)}
  external DocumentFragment();

  // ${$.empty('DocumentFragment.html', () => DocumentFragment.html)}
  external factory DocumentFragment.html(String html);

  // ${$.debug('outerHtml', ($, $$) => $.outerHtml)}
  external String get outerHtml;
}
''');

DartClass get _$DocumentType => DartClass<DocumentType>(($) => '''
class DocumentType extends Node {
  // ${$.debug('name', ($, $$) => $.name)}
  final String? name;
  // ${$.debug('publicId', ($, $$) => $.publicId)}
  final String? publicId;
  // ${$.debug('systemId', ($, $$) => $.systemId)}
  final String? systemId;

  // ${$.empty('DocumentType.new', () => DocumentType.new)}
  external DocumentType(this.name, this.publicId, this.systemId);

  // ${$.debug('clone', ($, $$) => $.clone)}
  external Node clone(bool deep);

  // ${$.debug('nodeType', ($, $$) => $.nodeType)}
  external int get nodeType;
}
''');

DartClass get _$Text => DartClass<Text>(($) => '''
class Text extends Node {
  // ${$.empty('Text.new', () => Text.new)}
  external Text(String? data);

  // ${$.debug('nodeType', ($, $$) => $.nodeType)}
  external int get nodeType;

  // ${$.debug('data', ($, $$) => $.data)}
  external String get data;

  // ${$.debug('data', ($, $$) => $.data = $$)}
  external set data(String value);

  // ${$.debug('clone', ($, $$) => $.clone)}
  external Text clone(bool deep);

  // ${$.debug('appendData', ($, $$) => $.appendData)}
  external void appendData(String data);
}
''');

DartClass get _$Element => DartClass<Element>(($) => '''
class Element extends Node with _ParentNode, _ElementAndDocument {
  // ${$.debug('namespaceUri', ($, $$) => $.namespaceUri)}
  final String? namespaceUri;

  // ${$.debug('localName', ($, $$) => $.localName)}
  final String? localName;

  // ${$.debug('endSourceSpan', ($, $$) => $.endSourceSpan)}
  FileSpan? endSourceSpan;

  // ${$.empty('Element.tag', () => Element.tag)}
  external Element.tag(this.localName);

  // ${$.empty('Element.html', () => Element.html)}
  external factory Element.html(String html);

  // ${$.debug('nodeType', ($, $$) => $.nodeType)}
  external int get nodeType;

  // ${$.debug('previousElementSibling', ($, $$) => $.previousElementSibling)}
  external Element? get previousElementSibling;

  // ${$.debug('nextElementSibling', ($, $$) => $.nextElementSibling)}
  external Element? get nextElementSibling;

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();

  // ${$.debug('text', ($, $$) => $.text)}
  external String get text;

  // ${$.debug('text', ($, $$) => $.text = $$)}
  external set text(String? value);

  // ${$.debug('outerHtml', ($, $$) => $.outerHtml)}
  external String get outerHtml;

  // ${$.debug('innerHtml', ($, $$) => $.innerHtml)}
  external String get innerHtml;

  // ${$.debug('innerHtml', ($, $$) => $.innerHtml = $$)}
  external set innerHtml(String value);

  // ${$.debug('clone', ($, $$) => $.clone)}
  external Element clone(bool deep);

  // ${$.debug('id', ($, $$) => $.id)}
  external String get id;

  // ${$.debug('id', ($, $$) => $.id = $$)}
  external set id(String value);

  // ${$.debug('className', ($, $$) => $.className)}
  external String get className;

  // ${$.debug('className', ($, $$) => $.className = $$)}
  external set className(String value);

  // ${$.debug('classes', ($, $$) => $.classes)}
  external CssClassSet get classes;
}
''');

DartClass get _$Comment => DartClass<Comment>(($) => '''
class Comment extends Node {
  // ${$.debug('data', ($, $$) => $.data = $$)}
  String? data;

  // ${$.empty('Comment.new', () => Comment.new)}
  external Comment(this.data);

  // ${$.debug('nodeType', ($, $$) => $.nodeType)}
  external int get nodeType;

  // ${$.debug('clone', ($, $$) => $.clone)}
  external Comment clone(bool deep);
}
''');

// TODO 处理继承私有内部类的情况
DartClass get _$NodeList => DartClass<NodeList>(($) => '''
class NodeList extends ListProxy<Node>{
  NodeList._();

  // ${$.debug('add', ($, $$) => $.add)}
  external void add(Node element);

  // ${$.debug('addLast', ($, $$) => $.addLast)}
  external void addLast(Node value);

  // ${$.debug('addAll', ($, $$) => $.addAll)}
  external void addAll(Iterable<Node> iterable);

  // ${$.debug('insert', ($, $$) => $.insert)}
  external void insert(int index, Node element);

  // ${$.debug('removeLast', ($, $$) => $.removeLast)}
  external Node removeLast();

  // ${$.debug('removeAt', ($, $$) => $.removeAt)}
  external Node removeAt(int index);

  // ${$.debug('clear', ($, $$) => $.clear)}
  external void clear();

  // ${$.debug('[]=', ($, $$) => $[$$] = $$)}
  external void operator []=(int index, Node value);

  // ${$.debug('setRange', ($, $$) => $.setRange)}
  external void setRange(int start, int end, Iterable<Node> iterable, [int skipCount = 0]);

  // ${$.debug('replaceRange', ($, $$) => $.replaceRange)}
  external void replaceRange(int start, int end, Iterable<Node> newContents);

  // ${$.debug('removeRange', ($, $$) => $.removeRange)}
  external void removeRange(int start, int end);

  // ${$.debug('removeWhere', ($, $$) => $.removeWhere)}
  external void removeWhere(bool Function(Node) test);

  // ${$.debug('retainWhere', ($, $$) => $.retainWhere)}
  external void retainWhere(bool Function(Node) test);

  // ${$.debug('insertAll', ($, $$) => $.insertAll)}
  external void insertAll(int index, Iterable<Node> iterable);
}
''');

DartClass get _$FilteredElementList => DartClass<FilteredElementList>(($) => '''
class FilteredElementList extends IterableBase<Element> with ListMixin<Element> implements List<Element> {
  // ${$.empty('FilteredElementList.new', () => FilteredElementList.new)}
  external FilteredElementList(Node node);

  // ${$.debug('[]=', ($, $$) => $[$$] = $$)}
  external void operator []=(int index, Element value);

  // ${$.debug('length', ($, $$) => $.length = $$)}
  external set length(int newLength);

  // ${$.debug('[]', ($, $$) => $[$$])}
  external Element operator [](int index);
}
''');

DartLibrary get htmlDomLibrary {
  return DartLibrary('html', path: 'dom.dart', source: 'library dom;', declarations: [
    _$CssClassSet,
    _$AttributeName,
    __$ParentNode,
    __$NonElementParentNode,
    __$ElementAndDocument,
    _$Node,
    _$Document,
    _$DocumentFragment,
    _$DocumentType,
    _$Text,
    _$Element,
    _$Comment,
    _$NodeList,
    _$FilteredElementList,
  ]);
}
