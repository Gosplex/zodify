import 'dart:convert';
import 'dart:io';

import 'package:astrology_app/common/screens/video_call_screen.dart';
import 'package:astrology_app/common/utils/common.dart';
import 'package:astrology_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:astrology_app/client/model/message_model.dart';
import 'package:astrology_app/client/model/user_model.dart';
import 'package:astrology_app/common/utils/app_text_styles.dart';
import 'package:astrology_app/common/utils/colors.dart';
import 'package:astrology_app/common/utils/images.dart';
import 'package:astrology_app/services/message_service.dart';
import 'package:astrology_app/services/user_service.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import 'calling_screen.dart';

class ChatMessageScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;

  const ChatMessageScreen({
    super.key,
    required this.chatId,
    required this.receiverId,
  });

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();
  final TextEditingController _textController = TextEditingController();
  final String currentUserId = userStore.user!.id!;
  bool _showOptions = false;
  final ImagePicker _picker = ImagePicker();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _recordedFilePath;
  String? imageUrl = '';

  @override
  void initState() {
    print(widget.chatId.toString()+":::CHeck Chat ID");
    super.initState();
    _initRecorder();
  }

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _handleImageMessage() async {
    setState(() => _showOptions = false);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      await _messageService.sendImageMessage(
        chatId: widget.chatId,
        senderId: currentUserId,
        receiverId: widget.receiverId,
        imageFile: image,
      );
    } catch (e) {
      debugPrint("Error sending message $e");
      CommonUtilities.showError(context, "Something went wrong");
    } finally {
      setState(() => _showOptions = false);
    }
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        CommonUtilities.showError(context,
            "Microphone permission is required to record voice messages");
        return;
      }
      final String path =
          '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(toFile: path);
      setState(() {
        _isRecording = true;
        _recordedFilePath = path;
      });
    } catch (e) {
      CommonUtilities.showError(context, "Something went wrong");
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      if (_recordedFilePath != null) {
        final file = XFile(_recordedFilePath!);
        await _messageService.sendVoiceMessage(
          chatId: widget.chatId,
          senderId: currentUserId,
          receiverId: widget.receiverId,
          voiceFile: file,
        );
      }
    } catch (e) {
      CommonUtilities.showError(context, "Something went wrong");
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: FutureBuilder<UserModel?>(
          future: _userService.getUserDetails(widget.receiverId),
          builder: (context, snapshot) {
            String userName = 'Astrologer';
            bool isOnline = false;

            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              userName = snapshot.data!.name!;
              imageUrl = snapshot.data?.userProfile ?? "";
              isOnline = snapshot.data!.isOnline ?? false;
            }

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl!)
                      : AssetImage(AppImages.ic_male),
                  child: imageUrl == null
                      ? const FaIcon(
                    FontAwesomeIcons.userAstronaut,
                    color: AppColors.zodiacGold,
                    size: 16,
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: AppTextStyles.captionText(
                        color: isOnline
                            ? AppColors.successGreen
                            : AppColors.textWhite70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.phone,
              color: AppColors.textWhite,
              size: 20,
            ),
            onPressed: () {
              print("pressed");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallingScreen(
                    receiverId: widget.receiverId,
                    receiverImageUrl: imageUrl,
                    isVideoCall: false,
                    channelName: 'call_${widget.chatId}',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.video,
              color: AppColors.textWhite,
              size: 20,
            ),
            onPressed: () {
              print("CheckRoomID::${widget.chatId}");
              print("receiverId::${widget.receiverId}");
              // CheckRoomID::higCpUVGbFUdSTB4PyW6WLoGskL2_higCpUVGbFUdSTB4PyW6WLoGskL2
              // receiverId::higCpUVGbFUdSTB4PyW6WLoGskL2

              // CheckRoomID::higCpUVGbFUdSTB4PyW6WLoGskL2_qYYiTqiaG6Q84NkGblucV0GtJZx2
              // receiverId::higCpUVGbFUdSTB4PyW6WLoGskL2
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoCallingScreen(
                    receiverId: widget.receiverId,
                    receiverImageUrl: imageUrl,
                    channelName: 'call_${widget.chatId}',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.zodiacGold.withOpacity(0.3),
                ),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search in conversation...',
                  hintStyle:
                  AppTextStyles.bodyMedium(color: AppColors.textWhite70),
                  prefixIcon: Icon(Icons.search, color: AppColors.textWhite70),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: AppTextStyles.bodyMedium(color: AppColors.textWhite),
              ),
            ),
          ),
          // Messages List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(AppImages.ic_background_user),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.7),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: StreamBuilder<List<MessageModel>>(
                stream: _messageService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.zodiacGold,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading messages',
                        style: TextStyle(color: AppColors.textWhite),
                      ),
                    );
                  }
                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Start the conversation!',
                        style: TextStyle(color: AppColors.textWhite70),
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true, // Newest messages at bottom
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSentByMe = message.senderId == currentUserId;
                      final time = DateFormat('h:mm a')
                          .format(message.timestamp.toDate());

                      if (message.messageType == MessageType.text) {
                        return isSentByMe
                            ? _SentMessage(text: message.content, time: time)
                            : _ReceivedMessage(
                            text: message.content, time: time);
                      } else if (message.messageType == MessageType.image) {
                        return isSentByMe
                            ? _SentImageMessage(
                            imageUrl: message.content, time: time)
                            : _ReceivedImageMessage(
                            imageUrl: message.content, time: time);
                      } else if (message.messageType == MessageType.video) {
                        return isSentByMe
                            ? _SentVideoMessage(
                            videoUrl: message.content, time: time)
                            : _ReceivedVideoMessage(
                            videoUrl: message.content, time: time);
                      } else if (message.messageType == MessageType.voice) {
                        return isSentByMe
                            ? _SentVoiceMessage(
                            voiceUrl: message.content, time: time)
                            : _ReceivedVoiceMessage(
                            voiceUrl: message.content, time: time);
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
            ),
          ),
          // Message Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.7),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Options Row (only shown when not recording)
                if (!_isRecording)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _showOptions ? 60 : 0,
                    curve: Curves.easeInOut,
                    child: _showOptions
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: _handleImageMessage,
                          splashColor:
                          AppColors.zodiacGold.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                              AppColors.primaryDark.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                AppColors.zodiacGold.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.camera,
                                  color: AppColors.zodiacGold,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Photo',
                                  style: AppTextStyles.bodyMedium(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            setState(() => _showOptions = false);
                            final XFile? video = await _picker.pickVideo(
                              source: ImageSource.gallery,
                            );
                            if (video != null) {
                              await _messageService.sendVideoMessage(
                                chatId: widget.chatId,
                                senderId: currentUserId,
                                receiverId: widget.receiverId,
                                videoFile: video,
                              );
                            }
                          },
                          splashColor:
                          AppColors.zodiacGold.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                              AppColors.primaryDark.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                AppColors.zodiacGold.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.video,
                                  color: AppColors.zodiacGold,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Video',
                                  style: AppTextStyles.bodyMedium(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                        : null,
                  ),
                if (!_isRecording && _showOptions) const SizedBox(height: 8),
                // Input Row or Recording UI
                _isRecording
                    ? Row(
                  children: [
                    // Wavy animation (placeholder with Icon, replace with Lottie if available)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.zodiacGold.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Lottie.asset(
                            "assets/animations/record.json",
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send button with stop and send logic
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.zodiacGold,
                      ),
                      child: IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.solidPaperPlane,
                          color: AppColors.textWhite,
                        ),
                        onPressed: () async {
                          try {
                            await _recorder.stopRecorder();
                            setState(() {
                              _isRecording = false;
                            });
                            if (_recordedFilePath != null) {
                              final file = XFile(_recordedFilePath!);
                              await _messageService.sendVoiceMessage(
                                chatId: widget.chatId,
                                senderId: currentUserId,
                                receiverId: widget.receiverId,
                                voiceFile: file,
                              );
                            }
                          } catch (e) {
                            CommonUtilities.showError(
                                context, "Something went wrong");
                          }
                        },
                      ),
                    ),
                  ],
                )
                    : Row(
                  children: [
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.paperclip,
                        color: AppColors.zodiacGold,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _showOptions = !_showOptions);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.zodiacGold.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                style: AppTextStyles.bodyMedium(
                                    color: AppColors.textWhite),
                                decoration: InputDecoration(
                                  hintText: 'Type your message...',
                                  hintStyle: AppTextStyles.bodyMedium(
                                      color: AppColors.textWhite70),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.microphone,
                                color: AppColors.zodiacGold,
                                size: 20,
                              ),
                              onPressed: _startRecording,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.zodiacGold,
                      ),
                      child: IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.solidPaperPlane,
                          color: AppColors.textWhite,
                        ),
                        onPressed: () async {
                          final content = _textController.text.trim();
                          if (content.isNotEmpty) {
                            _textController.clear();
                            await _messageService.sendMessage(
                              chatId: widget.chatId,
                              senderId: currentUserId,
                              receiverId: widget.receiverId,
                              content: content,
                              messageType: MessageType.text,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Message Widgets
class _ReceivedMessage extends StatelessWidget {
  final String text;
  final String time;

  const _ReceivedMessage({required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withOpacity(0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: AppTextStyles.bodyMedium(color: AppColors.textWhite),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: AppTextStyles.captionText(
                color: AppColors.textWhite70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentMessage extends StatelessWidget {
  final String text;
  final String time;

  const _SentMessage({required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.zodiacGold.withOpacity(0.3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          border: Border.all(
            color: AppColors.zodiacGold.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: AppTextStyles.bodyMedium(color: AppColors.textWhite),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: AppTextStyles.captionText(
                color: AppColors.textWhite70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentVideoMessage extends StatefulWidget {
  final String videoUrl;
  final String time;

  const _SentVideoMessage({
    required this.videoUrl,
    required this.time,
  });

  @override
  _SentVideoMessageState createState() => _SentVideoMessageState();
}

class _SentVideoMessageState extends State<_SentVideoMessage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _isInitialized
                        ? VideoPlayer(_controller)
                        : Container(
                      color: AppColors.primaryDark.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.zodiacGold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.zodiacGold.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: AppColors.textWhite,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              widget.time,
              style: AppTextStyles.captionText(
                color: AppColors.textWhite70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedVideoMessage extends StatefulWidget {
  final String videoUrl;
  final String time;

  const _ReceivedVideoMessage({
    required this.videoUrl,
    required this.time,
  });

  @override
  _ReceivedVideoMessageState createState() => _ReceivedVideoMessageState();
}

class _ReceivedVideoMessageState extends State<_ReceivedVideoMessage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _isInitialized
                        ? VideoPlayer(_controller)
                        : Container(
                      color: AppColors.primaryDark.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.zodiacGold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.zodiacGold.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: AppColors.textWhite,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              widget.time,
              style: AppTextStyles.captionText(
                color: AppColors.textWhite70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentImageMessage extends StatelessWidget {
  final String imageUrl;
  final String time;

  const _SentImageMessage({
    required this.imageUrl,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl, // Use content directly as URL
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
              child: Text(
                time,
                style: AppTextStyles.captionText(
                  color: AppColors.textWhite70,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedImageMessage extends StatelessWidget {
  final String imageUrl;
  final String time;
  final String? caption;

  const _ReceivedImageMessage({
    required this.imageUrl,
    required this.time,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            Text(
              time,
              style: AppTextStyles.captionText(
                color: AppColors.textWhite70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentVoiceMessage extends StatefulWidget {
  final String voiceUrl;
  final String time;

  const _SentVoiceMessage({
    required this.voiceUrl,
    required this.time,
  });

  @override
  _SentVoiceMessageState createState() => _SentVoiceMessageState();
}

class _SentVoiceMessageState extends State<_SentVoiceMessage> {
  late FlutterSoundPlayer _player;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _player = FlutterSoundPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (!_isInitialized) return;
    try {
      if (_isPlaying) {
        await _player.stopPlayer();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _player.startPlayer(
          fromURI: widget.voiceUrl,
          // codec: Codec.aacADTS,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
            });
          },
        );
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play voice message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.zodiacGold.withOpacity(0.3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          border: Border.all(
            color: AppColors.zodiacGold.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.zodiacGold.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: AppColors.textWhite,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Placeholder waveform
                Container(
                  width: 100,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.waves,
                      color: AppColors.zodiacGold,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.time,
              style: AppTextStyles.captionText(
                color: AppColors.textWhite70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedVoiceMessage extends StatefulWidget {
  final String voiceUrl;
  final String time;

  const _ReceivedVoiceMessage({
    required this.voiceUrl,
    required this.time,
  });

  @override
  _ReceivedVoiceMessageState createState() => _ReceivedVoiceMessageState();
}

class _ReceivedVoiceMessageState extends State<_ReceivedVoiceMessage> {
  late FlutterSoundPlayer _player;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _player = FlutterSoundPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (!_isInitialized) return;
    try {
      if (_isPlaying) {
        await _player.stopPlayer();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _player.startPlayer(
          fromURI: widget.voiceUrl,
          // codec: Codec.aacADTS,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
            });
          },
        );
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play voice message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withOpacity(0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.zodiacGold.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: AppColors.textWhite,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Placeholder waveform
                Container(
                  width: 100,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.waves,
                      color: AppColors.zodiacGold,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.time,
              style: AppTextStyles.captionText(
                color: AppColors.textWhite70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}