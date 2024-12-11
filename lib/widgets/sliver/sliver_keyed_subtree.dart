import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SliverKeyedSubtree extends SingleChildRenderObjectWidget {
  const SliverKeyedSubtree({
    super.key,
    required Widget sliver,
  }) : super(child: sliver);

  @override
  RenderSliverKeyedSubtree createRenderObject(BuildContext context) {
    return RenderSliverKeyedSubtree();
  }
}

class RenderSliverKeyedSubtree extends RenderProxySliver {
  RenderSliverKeyedSubtree();
}
