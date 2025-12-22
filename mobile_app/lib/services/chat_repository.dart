import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/services/auth_service.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatRepository(this._firestore, this._auth);

  Stream<QuerySnapshot> getChatHistory() {
    final userId = _auth.currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addMessage(String text, bool isFromUser) async {
    final userId = _auth.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .add({
      'text': text,
      'isFromUser': isFromUser,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  ),
);

// Provider for the chat history stream
final chatHistoryProvider = StreamProvider.autoDispose((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getChatHistory();
});
