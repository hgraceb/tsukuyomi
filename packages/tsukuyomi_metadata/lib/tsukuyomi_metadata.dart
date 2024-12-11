import 'tsukuyomi_metadata_platform_interface.dart';

class TsukuyomiMetadata {
  Future<String?> getPlatformVersion() {
    return TsukuyomiMetadataPlatform.instance.getPlatformVersion();
  }

  Future<int?> getStatusBarHeight() {
    return TsukuyomiMetadataPlatform.instance.getStatusBarHeight();
  }
}
