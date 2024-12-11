final result = [];

abstract class Parent {
  Parent({required this.param}) {
    result.add(param);
    result.add('Parent');
  }

  final String param;
}

class Child extends Parent {
  Child() : super(param: 'Param') {
    result.add('Child');
  }
}

void main() {
  Child();
  print(result); // [Param, Parent, Child]
}
