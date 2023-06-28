import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:aws_common/vm.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

class StorageService {
  StorageService({
    required Ref ref,
  });

  ValueNotifier<double> uploadProgress = ValueNotifier<double>(0);
  Future<String> getImageUrl(String key) async {
    try {
      final result = await Amplify.Storage.getUrl(
        key: key,
        // options: const S3GetUrlOperation(pluginOptions: S3GetUrlPluginOptions(expiresIn: Duration(minutes: 1))),
        options: const StorageGetUrlOptions(
            pluginOptions: S3GetUrlPluginOptions(
                expiresIn: Duration(days: 1))
        ),
      ).result;
      return result.url.toString();
    } on StorageException catch (e) {
      safePrint('Could not get a downloadable URL: ${e.message}');
      rethrow;
    }
  }

  ValueNotifier<double> getUploadProgress() {
    return uploadProgress;
  }

  Future<String?> uploadFile(File file) async {
    try {
      final extension = p.extension(file.path);
      final key = const Uuid().v1() + extension;
      final awsFile = AWSFilePlatform.fromFile(file);
      await Amplify.Storage.uploadFile(
          localFile: awsFile,
          key: key,
          onProgress: (progress) {
            uploadProgress.value = progress.fractionCompleted;
          });

      return key;
    } on Exception catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  void resetUploadProgress() {
    uploadProgress.value = 0;
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref: ref);
});

final imageUrlProvider = FutureProvider.autoDispose.family<String, String>((ref, key) {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getImageUrl(key);
});