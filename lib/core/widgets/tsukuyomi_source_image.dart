import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/forward/octo_image/octo_image.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

class TsukuyomiSourceImage extends StatelessWidget {
  const TsukuyomiSourceImage({
    super.key,
    required this.source,
    required this.image,
    this.placeholderBuilder,
    this.imageBuilder,
    this.errorBuilder,
  });

  final Source source;

  final SourceImage image;

  final OctoPlaceholderBuilder? placeholderBuilder;

  final OctoImageBuilder? imageBuilder;

  final OctoErrorBuilder? errorBuilder;

  ImageProvider _getImageProvider() {
    switch (image) {
      case LocalSourceImage():
        return FileImage(File(image.url));
      case HttpSourceImage():
        return CachedNetworkImageProvider(image.url, cacheManager: source.getImageCacheManager(image));
    }
  }

  @override
  Widget build(BuildContext context) {
    return OctoImage(
      fit: BoxFit.cover,
      image: _getImageProvider(),
      placeholderBuilder: placeholderBuilder ?? (_) => const SizedBox.shrink(),
      imageBuilder: imageBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
