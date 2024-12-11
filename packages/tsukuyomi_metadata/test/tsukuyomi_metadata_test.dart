import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tsukuyomi_metadata/tsukuyomi_metadata.dart';
import 'package:tsukuyomi_metadata/tsukuyomi_metadata_method_channel.dart';
import 'package:tsukuyomi_metadata/tsukuyomi_metadata_platform_interface.dart';

class MockTsukuyomiMetadataPlatform with MockPlatformInterfaceMixin implements TsukuyomiMetadataPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<int?> getStatusBarHeight() => Future.value(108);
}

void main() {
  final TsukuyomiMetadataPlatform initialPlatform = TsukuyomiMetadataPlatform.instance;

  test('$MethodChannelTsukuyomiMetadata is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTsukuyomiMetadata>());
  });

  test('getPlatformVersion', () async {
    TsukuyomiMetadata tsukuyomiMetadataPlugin = TsukuyomiMetadata();
    MockTsukuyomiMetadataPlatform fakePlatform = MockTsukuyomiMetadataPlatform();
    TsukuyomiMetadataPlatform.instance = fakePlatform;

    expect(await tsukuyomiMetadataPlugin.getPlatformVersion(), '42');
  });

  test('getStatusBarHeight', () async {
    TsukuyomiMetadata tsukuyomiMetadataPlugin = TsukuyomiMetadata();
    MockTsukuyomiMetadataPlatform fakePlatform = MockTsukuyomiMetadataPlatform();
    TsukuyomiMetadataPlatform.instance = fakePlatform;

    expect(await tsukuyomiMetadataPlugin.getStatusBarHeight(), 108);
  });
}
