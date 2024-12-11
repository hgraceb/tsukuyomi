import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tsukuyomi_metadata_platform_interface.dart';

/// An implementation of [TsukuyomiMetadataPlatform] that uses method channels.
class MethodChannelTsukuyomiMetadata extends TsukuyomiMetadataPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tsukuyomi_metadata');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<int?> getStatusBarHeight() async {
    if (Platform.isAndroid) {
      return await methodChannel.invokeMethod<int>('getStatusBarHeight');
    }
    return null;
  }
}
