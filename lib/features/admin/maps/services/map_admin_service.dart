import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapAdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> getMapUrl() async {
    final snap = await _db.collection('map').limit(1).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data()['mapPicture'] as String?;
  }

  Future<void> saveMapUrl(String url) async {
    final snap = await _db.collection('map').limit(1).get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({'mapPicture': url});
    } else {
      await _db.collection('map').add({'mapPicture': url});
    }
  }

  Future<String> uploadMap(List<int> bytes, String extension) async {
    const mimeTypes = {'png': 'image/png', 'pdf': 'application/pdf'};
    final contentType = mimeTypes[extension.toLowerCase()];
    if (contentType == null) {
      throw ArgumentError('Only PNG and PDF are supported');
    }
    final ref = _storage.ref().child('maps/zoo_map.$extension');
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(Uint8List.fromList(bytes), metadata);
    final downloadUrl = await ref.getDownloadURL();
    await saveMapUrl(downloadUrl);
    return downloadUrl;
  }
}

final mapAdminServiceProvider = Provider<MapAdminService>(
  (ref) => MapAdminService(),
);
