import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:college_resale_app/firebase_options.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test Firebase Storage Upload', (WidgetTester tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    File dummy = File('test_dummy.txt');
    await dummy.writeAsString('hello world');

    try {
      Reference ref = FirebaseStorage.instance.ref().child('test/test_dummy.txt');
      print('Uploading to ${ref.fullPath} in bucket ${ref.bucket}');
      
      TaskSnapshot snapshot = await ref.putFile(dummy);
      print('Upload state: ${snapshot.state}');
      
      String url = await snapshot.ref.getDownloadURL();
      print('Download URL: $url');
      
    } catch (e) {
      print('ERROR OCCURRED: $e');
    }
  });
}
