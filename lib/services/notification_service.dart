import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:astrology_app/common/utils/colors.dart';
import 'package:astrology_app/main.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../astrologer/screens/accept_reject_chat_request.dart';
import '../astrologer/screens/pending_chat_request.dart';
import '../common/screens/ongoing_call_screen.dart';
import '../common/screens/ongoing_video_calling_screen.dart';
import '../common/screens/video_call_screen.dart';
import 'agora_services.dart'; // Updated AgoraService with CallType

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _channelKey = 'call_notification';
  static const String _channelName = 'Call Notification';
  static const String _channelDescription = 'Notifications for incoming call';
  static GlobalKey<NavigatorState>? _navigatorKey;
  final _callRejectionController = StreamController<String>.broadcast();
  final _callMissedController =
      StreamController<String>.broadcast(); // New stream for missed calls

  Stream<String> get callRejection => _callRejectionController.stream;

  Stream<String> get callMissed =>
      _callMissedController.stream; // Expose missed call stream

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    debugPrint('Initializing NotificationService...');
    try {
      _navigatorKey = navigatorKey;

      final permission = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM permission status: $permission');

      // Save FCM token to Firestore
      await _updateFcmToken();

      // Initialize Awesome Notifications
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: _channelKey,
            channelName: _channelName,
            channelDescription: _channelDescription,
            importance: NotificationImportance.Max,
            playSound: true,
            soundSource: 'resource://raw/notification',
            vibrationPattern: highVibrationPattern,
            defaultColor: AppColors.primaryDark,
            ledColor: Colors.white,
            enableLights: true,
            enableVibration: true,
            channelShowBadge: true,
            locked: true,
          ),
        ],
      );

      // Check Awesome Notifications permission
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        debugPrint('Notifications disabled; consider prompting user later');
      }

      // Set up notification action handler
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: (ReceivedAction action) async {
          debugPrint('AwesomeNotifications tapped: ${action.payload}');

          if (action.payload != null &&
              action.payload!['type'] == 'chat_request') {
            debugPrint('Processing chat_request tap (foreground)');
            final payload = action.payload!;

            final requestId = payload['requestId'] ?? '';
            final userId = payload['userId'] ?? '';

            // Fetch the request data from Firestore
            final docSnapshot = await FirebaseFirestore.instance
                .collection('chat_requests')
                .doc(requestId)
                .get();

            Future.microtask(() {
              // _navigatorKey?.currentState?.push(
              //   MaterialPageRoute(
              //     builder: (context) => AcceptRejectScreen(
              //       requestData: docSnapshot.data() as Map<String, dynamic>,
              //       requestId: requestId,
              //       userId: userId,
              //     ),
              //   ),
              // );
              _navigatorKey?.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => ChatRequestsListScreen(
                  ),
                ),
              );
            });
          } else {
            await NotificationService.onActionReceived(action);
          }
        },
      );
      // AwesomeNotifications().setListeners(
      //   onActionReceivedMethod: NotificationService.onActionReceived,
      // );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            'Foreground message received: ${message.notification?.title}, Data: ${message.data}');
        if (message.data['type'] == 'call_rejected') {
          final channelName = message.data['channelName'] ?? '';
          debugPrint("Channel Name === $channelName");
          _callRejectionController.add(channelName);
        } else if (message.data['type'] == 'chat_request' ||
            message.data['type'] == 'chat_rejected' ||
            message.data['type'] == 'chat_accepted') {
          // Handle generic notification without buttons
          _showSimpleLocalNotification(message);
        } else {
          _showLocalNotification(message);
        }
      });

      // Handle background/terminated messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle app opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
            'App opened from notification: ${message.notification?.title}, Data: ${message.data}');
        _handleMessageOpened(message);
      });

      // Get initial message (app opened from terminated state)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            'Initial message received: ${initialMessage.notification?.title}, Data: ${initialMessage.data}');
        _handleMessageOpened(initialMessage);
      }

      debugPrint('NotificationService initialization completed');
    } catch (e) {
      debugPrint('Error during NotificationService initialization: $e');
    }
  }

  // Unified method to handle notification actions (foreground and background)
  static Future<void> _handleNotificationAction({
    required String? channelName,
    required String? receiverId,
    required String? callerId,
    required String? callerFcmToken,
    required String? callType, // Added callType
    required String action,
    String? callerName, // Added for VideoCallScreen
  }) async {
    print("Notification Action called()");
    if (_navigatorKey == null) {
      debugPrint('Navigator key not available');
      return;
    }

    if (action == 'accept' &&
        channelName != null &&
        receiverId != null &&
        callerId != null) {
      debugPrint(
          'Accept action triggered for channel: $channelName, receiver: $receiverId, caller: $callerId, callType: $callType');
      final agoraService = AgoraService();
      try {
        // Initialize and join call based on callType
        await agoraService
            .initialize(callType == 'video' ? CallType.video : CallType.voice);
        await agoraService.joinCall(
          channelName,
          receiverId,
          callType == 'video' ? CallType.video : CallType.voice,
        );
        // Navigate to appropriate screen based on callType
        if (callType == 'video') {
          _navigatorKey!.currentState?.push(
            MaterialPageRoute(
              builder: (context) => OngoingVideoCallScreen(
                receiverId: callerId,
                channelName: channelName,
                isCaller: false,
              ),
            ),
          );
        } else {
          _navigatorKey!.currentState?.push(
            MaterialPageRoute(
              builder: (context) => OngoingCallScreen(
                receiverId: callerId,
                channelName: channelName,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to join Agora call: $e');
      }
    } else if (action == 'reject' &&
        receiverId != null &&
        callerId != null &&
        callerFcmToken != null) {
      debugPrint(
          'Reject action triggered for receiver: $receiverId, notifying caller: $callerId');
      _instance._sendRejectionNotification(
        receiverId: receiverId,
        callerId: callerId,
        channelName: channelName ?? '',
        callerFcmToken: callerFcmToken,
      );
    }
  }

  // Static method for background notification actions
  @pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction action) async {
    debugPrint(
        'Background action received: ${action.buttonKeyPressed}, Payload: ${action.payload}');

    final payload = action.payload;
    if (payload == null) return;

    final channelName = payload['channelName'];
    final receiverId = payload['receiverId'];
    final callerId = payload['callerId'];
    final callerFcmToken = payload['callerFcmToken'];
    final callType = payload['callType']; // Added callType
    final callerName = payload['callerName']; // Added for VideoCallScreen

    await _handleNotificationAction(
      channelName: channelName,
      receiverId: receiverId,
      callerId: callerId,
      callerFcmToken: callerFcmToken,
      callType: callType,
      action: action.buttonKeyPressed,
      callerName: callerName,
    );
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    debugPrint(
        'Background message received: ${message.notification?.title}, Data: ${message.data}');
    // Optionally show local notification in background if needed
  }

  // Add this new method to show simple notifications without action buttons
  Future<void> _showSimpleLocalNotification(RemoteMessage message) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      debugPrint('Cannot show notification: permission not granted');
      return;
    }

    final notification = message.notification;
    final data = message.data;

    if (notification == null) {
      debugPrint('No notification payload in message');
      return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notification.hashCode,
        channelKey: _channelKey,
        title: notification.title,
        body: notification.body,
        payload: data.cast<String, String>(),
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        fullScreenIntent: false,
        // Set to false for generic notifications
        autoDismissible: true,
        displayOnForeground: true,
        displayOnBackground: true,
        locked: false,
        // Not locked for generic notifications
        category: NotificationCategory.Message, // Changed from Call to Message
      ),
      // No action buttons for generic notifications
    );

    debugPrint('Simple local notification displayed');
  }

  // Show local notification with action buttons
  Future<void> _showLocalNotification(RemoteMessage message) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      debugPrint('Cannot show notification: permission not granted');
      return;
    }

    final notification = message.notification;
    final data = message.data;

    if (notification == null) {
      debugPrint('No notification payload in message');
      return;
    }

    final notificationId = notification.hashCode;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: _channelKey,
        title: notification.title,
        body: notification.body,
        payload: data.cast<String, String>(),
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        displayOnForeground: true,
        displayOnBackground: true,
        locked: true,
        category: NotificationCategory.Call,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'accept',
          label: 'Accept',
          color: Colors.green.shade600,
          actionType: ActionType.Default,
          enabled: true,
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'reject',
          label: 'Reject',
          color: Colors.red.shade600,
          actionType: ActionType.Default,
          enabled: true,
          autoDismissible: true,
        ),
      ],
    );

    // Start a timer to detect missed call
    _startMissedCallTimer(
      notificationId: notificationId,
      channelName: data['channelName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      callerId: data['callerId'] ?? '',
      callerFcmToken: data['callerFcmToken'] ?? '',
    );
    debugPrint('Local notification displayed');
  }

  // Handle app opened from notification
  Future<void> _handleMessageOpened(RemoteMessage message) async {
    final data = message.data;
    debugPrint('Message opened: Data: $data');
    final channelName = data['channelName'] as String?;
    final receiverId = data['receiverId'] as String?;
    final callerId = data['callerId'] as String?;
    final callerFcmToken = data['callerFcmToken'] as String?;
    final callType = data['callType'] as String?; // Added callType
    final callerName =
        data['callerName'] as String?; // Added for VideoCallScreen

    if (channelName != null && receiverId != null && callerId != null) {
      // Treat this as an "accept" action, since the user tapped the notification
      await _handleNotificationAction(
        channelName: channelName,
        receiverId: receiverId,
        callerId: callerId,
        callerFcmToken: callerFcmToken,
        callType: callType,
        action: 'accept',
        callerName: callerName,
      );
    }

    if (data['type'] == 'chat_request' && data['screen'] == 'accept_reject') {
      debugPrint("Chat Request");
      if (_navigatorKey?.currentState != null) {
        try {
          final requestId = data['requestId'] ?? '';
          final userId = data['userId'] ?? '';

          // Fetch the request data from Firestore
          final docSnapshot = await FirebaseFirestore.instance
              .collection('chat_requests')
              .doc(requestId)
              .get();

          if (docSnapshot.exists) {
            // _navigatorKey!.currentState?.push(
            //   MaterialPageRoute(
            //     builder: (context) => AcceptRejectScreen(
            //       requestId: requestId,
            //       userId: userId,
            //       requestData: docSnapshot.data() as Map<String, dynamic>,
            //     ),
            //   ),
            // );
            _navigatorKey?.currentState?.push(
              MaterialPageRoute(
                builder: (context) => ChatRequestsListScreen(
                ),
              ),
            );
          } else {
            debugPrint('Request document not found');
          }
        } catch (e) {
          debugPrint('Error fetching request data: $e');
        }
      }
      return;
    }
  }

  // Start a timer to detect missed calls
  void _startMissedCallTimer({
    required int notificationId,
    required String channelName,
    required String receiverId,
    required String callerId,
    required String callerFcmToken,
  }) {
    const timeoutDuration = Duration(seconds: 30); // Adjust as needed
    Timer(timeoutDuration, () async {
      // Check if the notification still exists (i.e., not accepted or rejected)
      final notifications =
          await AwesomeNotifications().listScheduledNotifications();
      bool notificationExists =
          notifications.any((n) => n.content?.id == notificationId);

      if (notificationExists) {
        debugPrint('Call missed for channel: $channelName');
        // Cancel the incoming call notification
        await AwesomeNotifications().cancel(notificationId);
        // Send missed call notification to the caller
        await _sendMissedCallNotification(
          receiverId: receiverId,
          callerId: callerId,
          channelName: channelName,
          callerFcmToken: callerFcmToken,
        );
      }
    });
  }

  // Send call notification to a user using service account
  Future<void> sendCallNotification({
    required String receiverId,
    required String channelName,
    required String callerName,
    required String fcmToken,
    required String callerId,
    required String callerFcmToken,
    required CallType callType, // Added callType
    String? callerImageUrl,
  }) async {
    try {
      debugPrint('Sending $callType call notification to token: $fcmToken');
      final serviceAccountJson = await DefaultAssetBundle.of(
              WidgetsBinding.instance!.rootElement!)
          .loadString(
              'assets/zodify-6ff17-firebase-adminsdk-fbsvc-93837edb1e.json');
      final serviceAccount = jsonDecode(serviceAccountJson);
      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      final client = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      try {
        final payload = {
          'message': {
            'token': fcmToken,
            'notification': {
              'title':
                  'Incoming ${callType == CallType.video ? 'Video' : 'Voice'} Call from $callerName',
              'body': 'Tap to answer or reject the call.',
            },
            'data': {
              'type': 'call',
              'channelName': channelName,
              'receiverId': receiverId,
              'callerId': callerId,
              'callerFcmToken': callerFcmToken,
              'callerName': callerName,
              'callType': callType == CallType.video ? 'video' : 'voice',
              // Added callType
              'callerImageUrl': callerImageUrl ?? '',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
            'android': {
              'priority': 'high',
              'notification': {
                'sound': 'notification',
                'channelId': _channelKey,
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'notification.wav',
                },
              },
            },
          },
        };

        final response = await client.post(
          Uri.parse(
              'https://fcm.googleapis.com/v1/projects/${serviceAccount['project_id']}/messages:send'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        debugPrint(
            'Notification response: ${response.statusCode}, ${response.body}');
        if (response.statusCode == 200) {
          debugPrint('$callType call notification sent successfully');
        } else {
          debugPrint(
              'Failed to send $callType call notification: ${response.body}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error sending $callType call notification: $e');
    }
  }

  // Send rejection notification to the caller
  Future<void> _sendRejectionNotification({
    required String receiverId,
    required String callerId,
    required String channelName,
    required String callerFcmToken,
  }) async {
    try {
      debugPrint(
          'Sending rejection notification to caller: $callerId, token: $callerFcmToken');
      final serviceAccountJson = await DefaultAssetBundle.of(
              WidgetsBinding.instance!.rootElement!)
          .loadString(
              'assets/zodify-6ff17-firebase-adminsdk-fbsvc-93837edb1e.json');
      final serviceAccount = jsonDecode(serviceAccountJson);
      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      final client = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      try {
        final payload = {
          'message': {
            'token': callerFcmToken,
            'notification': {
              'title': 'Call Rejected',
              'body': 'Your call was rejected.',
            },
            'data': {
              'type': 'call_rejected',
              'channelName': channelName,
              'receiverId': receiverId,
              'callerId': callerId,
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channelId': _channelKey,
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                },
              },
            },
          },
        };

        final response = await client.post(
          Uri.parse(
              'https://fcm.googleapis.com/v1/projects/${serviceAccount['project_id']}/messages:send'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        debugPrint(
            'Rejection notification response: ${response.statusCode}, ${response.body}');
        if (response.statusCode == 200) {
          debugPrint('Rejection notification sent successfully');
        } else {
          debugPrint('Failed to send rejection notification: ${response.body}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error sending rejection notification: $e');
    }
  }

  // Update FCM token in Firestore
  Future<void> _updateFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set({'fcmToken': token}, SetOptions(merge: true));
          userStore.user!.copyWith(fcmToken: token);
        }
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  // Send missed call notification to the caller
  Future<void> _sendMissedCallNotification({
    required String receiverId,
    required String callerId,
    required String channelName,
    required String callerFcmToken,
  }) async {
    try {
      debugPrint(
          'Sending missed call notification to caller: $callerId, token: $callerFcmToken');
      final serviceAccountJson = await DefaultAssetBundle.of(
              WidgetsBinding.instance!.rootElement!)
          .loadString(
              'assets/zodify-6ff17-firebase-adminsdk-fbsvc-93837edb1e.json');
      final serviceAccount = jsonDecode(serviceAccountJson);
      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      final client = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      try {
        final payload = {
          'message': {
            'token': callerFcmToken,
            'notification': {
              'title': 'Missed Call',
              'body': 'You have a missed call.',
            },
            'data': {
              'type': 'call_missed',
              'channelName': channelName,
              'receiverId': receiverId,
              'callerId': callerId,
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channelId': _channelKey,
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                },
              },
            },
          },
        };

        final response = await client.post(
          Uri.parse(
              'https://fcm.googleapis.com/v1/projects/${serviceAccount['project_id']}/messages:send'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        debugPrint(
            'Missed call notification response: ${response.statusCode}, ${response.body}');
        if (response.statusCode == 200) {
          debugPrint('Missed call notification sent successfully');
        } else {
          debugPrint(
              'Failed to send missed call notification: ${response.body}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error sending missed call notification: $e');
    }
  }

  // Method to cancel notification and send missed call notification
  Future<void> handleCallerLeft({
    required int notificationId,
    required String channelName,
    required String receiverId,
    required String callerId,
    required String callerFcmToken,
  }) async {
    debugPrint('Caller left for channel: $channelName, handling missed call');
    // Cancel the incoming call notification
    await AwesomeNotifications().cancel(notificationId);
    // Send missed call notification to the caller
    await _sendMissedCallNotification(
      receiverId: receiverId,
      callerId: callerId,
      channelName: channelName,
      callerFcmToken: callerFcmToken,
    );
  }

  Future<void> sendGenericNotification({
    required String fcmToken,
    required String title,
    required String body,
    required String type,
    Map<String, String>? data,
    String? clickAction,
  }) async {
    try {
      debugPrint('Sending generic notification to token: $fcmToken');
      final serviceAccountJson = await DefaultAssetBundle.of(
              WidgetsBinding.instance!.rootElement!)
          .loadString(
              'assets/zodify-6ff17-firebase-adminsdk-fbsvc-93837edb1e.json');
      final serviceAccount = jsonDecode(serviceAccountJson);
      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      final client = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      try {
        final payload = {
          'message': {
            'token': fcmToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'type': type, // Changed from dynamic type to 'generic'
              if (data != null) ...data,
              if (clickAction != null) 'click_action': clickAction,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channelId': _channelKey,
                // Remove sound if not needed or keep it
                'sound': 'default',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                },
              },
            },
          },
        };

        final response = await client.post(
          Uri.parse(
              'https://fcm.googleapis.com/v1/projects/${serviceAccount['project_id']}/messages:send'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        debugPrint(
            'Generic notification response: ${response.statusCode}, ${response.body}');
        if (response.statusCode != 200) {
          debugPrint('Failed to send generic notification: ${response.body}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error sending generic notification: $e');
    }
  }

  void dispose() {
    _callRejectionController.close();
  }
}
