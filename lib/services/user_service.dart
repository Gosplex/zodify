import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:astrology_app/client/model/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String usersCollection = 'users';

  /// Fetches user details by ID
  Future<UserModel?> getUserDetails(String userId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user details: $e');
    }
  }

  /// Updates user online status
  Future<void> updateUserStatus(String userId, bool isOnline, String lastDashboardLoggedIn) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update({
        'isOnline': isOnline,
        'lastActive': DateTime.now().toIso8601String(),
        'lastDashboardLoggedIn': lastDashboardLoggedIn,
      });
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  /// Updates user online status
  Future<void> updateAstrologerAvailability(String userId, {required Map<String, bool> user_availability}) async {
    try {
      print("updateAstrologerAvailability Update Called:::$userId");
      print("updateAstrologerAvailability Update Values:::$user_availability");
      await _firestore.collection(usersCollection).doc(userId).update({
        'astrologerProfile.availability': user_availability,
      });
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  Future<dynamic> getAstrologerAvailability(String userId,) async {
    try {
      print("getAstrologerAvailability Called:::$userId");
      DocumentSnapshot<Map<String, dynamic>> b=await _firestore.collection(usersCollection).doc(userId).get();
      return b.get('astrologerProfile')['availability'];
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }


  Future<void> updateAstrologerStatus(String userId, bool isOnline, String lastDashboardLoggedIn) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update({
        'lastActive': DateTime.now().toIso8601String(),
        'astrologerProfile.isOnline': isOnline,
        'lastDashboardLoggedIn': lastDashboardLoggedIn,
      });
    } catch (e) {
      throw Exception('Failed to update astrologer status: $e');
    }
  }
}