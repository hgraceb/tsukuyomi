import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' hide RenderFittedBox, RenderFlex;
import 'package:flutter/widgets.dart';
import 'package:tsukuyomi_pixel_snap/src/tsukuyomi/rendering/flex.dart';
import 'package:tsukuyomi_pixel_snap/src/tsukuyomi/rendering/proxy_box.dart';

part 'package:tsukuyomi_pixel_snap/src/flutter/widgets/basic.dart';

class TsukuyomiPixelFittedBox extends FittedBox {
  final double? scale;

  const TsukuyomiPixelFittedBox({
    super.key,
    super.fit,
    super.alignment,
    super.clipBehavior,
    super.child,
    this.scale,
  });

  @override
  TsukuyomiPixelRenderFittedBox createRenderObject(BuildContext context) {
    final renderFittedBox = super.createRenderObject(context);
    return TsukuyomiPixelRenderFittedBox(
      scale: scale,
      fit: renderFittedBox.fit,
      alignment: renderFittedBox.alignment,
      textDirection: renderFittedBox.textDirection,
      clipBehavior: renderFittedBox.clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, TsukuyomiPixelRenderFittedBox renderObject) {
    super.updateRenderObject(context, renderObject..scale = scale);
  }
}

class TsukuyomiPixelFlex extends Flex {
  const TsukuyomiPixelFlex({
    super.key,
    required super.direction,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline, // NO DEFAULT: we don't know what the text's baseline should be
    super.clipBehavior,
    super.spacing,
    super.children,
  });

  @override
  TsukuyomiPixelRenderFlex createRenderObject(BuildContext context) {
    final renderFlex = super.createRenderObject(context);
    return TsukuyomiPixelRenderFlex(
      direction: renderFlex.direction,
      mainAxisAlignment: renderFlex.mainAxisAlignment,
      mainAxisSize: renderFlex.mainAxisSize,
      crossAxisAlignment: renderFlex.crossAxisAlignment,
      textDirection: renderFlex.textDirection,
      verticalDirection: renderFlex.verticalDirection,
      textBaseline: renderFlex.textBaseline,
      clipBehavior: renderFlex.clipBehavior,
      spacing: renderFlex.spacing,
    );
  }

  @override
  void updateRenderObject(BuildContext context, TsukuyomiPixelRenderFlex renderObject) {
    super.updateRenderObject(context, renderObject);
  }
}

class TsukuyomiPixelRow extends Row {
  const TsukuyomiPixelRow({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline, // NO DEFAULT: we don't know what the text's baseline should be
    super.spacing,
    super.children,
  });
}

class TsukuyomiPixelColumn extends Column {
  const TsukuyomiPixelColumn({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.spacing,
    super.children,
  });
}
