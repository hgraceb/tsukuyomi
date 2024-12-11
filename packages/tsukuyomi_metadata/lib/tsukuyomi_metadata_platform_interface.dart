import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tsukuyomi_metadata_method_channel.dart';

abstract class TsukuyomiMetadataPlatform extends PlatformInterface {
  /// Constructs a TsukuyomiMetadataPlatform.
  TsukuyomiMetadataPlatform() : super(token: _token);

  static final Object _token = Object();

  static TsukuyomiMetadataPlatform _instance = MethodChannelTsukuyomiMetadata();

  /// The default instance of [TsukuyomiMetadataPlatform] to use.
  ///
  /// Defaults to [MethodChannelTsukuyomiMetadata].
  static TsukuyomiMetadataPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TsukuyomiMetadataPlatform] when
  /// they register themselves.
  static set instance(TsukuyomiMetadataPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<int?> getStatusBarHeight() {
    throw UnimplementedError('statusBarHeight() has not been implemented.');
  }
}
