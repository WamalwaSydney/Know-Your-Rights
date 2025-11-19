import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final String _userId = 'local_user'; // Or get from your local auth system

  Future<String> uploadFile(String filePath, String fileName) async {
    try {
      File sourceFile = File(filePath);

      // Verify source file exists
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist');
      }

      // Get the application documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();

      // Create the user's contracts directory
      final Directory userContractsDir = Directory(
          path.join(appDocDir.path, 'users', _userId, 'contracts')
      );

      // Create directory if it doesn't exist
      if (!await userContractsDir.exists()) {
        await userContractsDir.create(recursive: true);
      }

      // Create destination path
      final String destinationPath = path.join(userContractsDir.path, fileName);

      // Copy the file to the new location
      final File destinationFile = await sourceFile.copy(destinationPath);

      // Return the local file path (similar to download URL)
      return destinationFile.path;
    } catch (e) {
      print('Local Storage Error: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Delete Error: $e');
      rethrow;
    }
  }

  // Get a file from storage
  Future<File?> getFile(String fileName) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filePath = path.join(
          appDocDir.path, 'users', _userId, 'contracts', fileName
      );

      final File file = File(filePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Get File Error: $e');
      return null;
    }
  }

  // List all files in the contracts directory
  Future<List<FileSystemEntity>> listFiles() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory userContractsDir = Directory(
          path.join(appDocDir.path, 'users', _userId, 'contracts')
      );

      if (await userContractsDir.exists()) {
        return userContractsDir.listSync();
      }
      return [];
    } catch (e) {
      print('List Files Error: $e');
      return [];
    }
  }
}