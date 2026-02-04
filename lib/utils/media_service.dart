import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enhanced_chat_models.dart';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check and request camera permission
  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  /// Check and request microphone permission
  Future<bool> requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  /// Check and request storage permission
  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  /// Show media picker dialog
  Future<void> showMediaPicker(
    BuildContext context, {
    required Function(File) onImageSelected,
    required Function(File) onVideoSelected,
    required Function(File) onDocumentSelected,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Share Media',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildMediaOption(
                          context,
                          Icons.camera_alt,
                          'Camera',
                          Colors.green,
                          () => _captureFromCamera(context, onImageSelected),
                        ),
                        _buildMediaOption(
                          context,
                          Icons.videocam,
                          'Video',
                          Colors.red,
                          () => _captureVideo(context, onVideoSelected),
                        ),
                        _buildMediaOption(
                          context,
                          Icons.photo_library,
                          'Gallery',
                          Colors.blue,
                          () => _pickFromGallery(context, onImageSelected),
                        ),
                        _buildMediaOption(
                          context,
                          Icons.description,
                          'Document',
                          Colors.orange,
                          () => _pickDocument(context, onDocumentSelected),
                        ),
                        _buildMediaOption(
                          context,
                          Icons.location_on,
                          'Location',
                          Colors.purple,
                          () => _shareLocation(context),
                        ),
                        _buildMediaOption(
                          context,
                          Icons.contact_phone,
                          'Contact',
                          Colors.teal,
                          () => _shareContact(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaOption(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureFromCamera(
    BuildContext context,
    Function(File) onImageSelected,
  ) async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        _showPermissionDeniedDialog(context, 'Camera');
        return;
      }
      
      // Simulate image capture - replace with actual image picker
      print('Camera capture initiated');
      // final ImagePicker picker = ImagePicker();
      // final XFile? image = await picker.pickImage(source: ImageSource.camera);
      // if (image != null) {
      //   onImageSelected(File(image.path));
      // }
    } catch (e) {
      _showErrorDialog(context, 'Failed to capture image: \');
    }
  }

  Future<void> _captureVideo(
    BuildContext context,
    Function(File) onVideoSelected,
  ) async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        _showPermissionDeniedDialog(context, 'Camera');
        return;
      }
      
      // Simulate video capture - replace with actual image picker
      print('Video capture initiated');
      // final ImagePicker picker = ImagePicker();
      // final XFile? video = await picker.pickVideo(source: ImageSource.camera);
      // if (video != null) {
      //   onVideoSelected(File(video.path));
      // }
    } catch (e) {
      _showErrorDialog(context, 'Failed to capture video: \');
    }
  }

  Future<void> _pickFromGallery(
    BuildContext context,
    Function(File) onImageSelected,
  ) async {
    try {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        _showPermissionDeniedDialog(context, 'Storage');
        return;
      }
      
      // Simulate gallery pick - replace with actual image picker
      print('Gallery picker initiated');
      // final ImagePicker picker = ImagePicker();
      // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      // if (image != null) {
      //   onImageSelected(File(image.path));
      // }
    } catch (e) {
      _showErrorDialog(context, 'Failed to pick image: \');
    }
  }

  Future<void> _pickDocument(
    BuildContext context,
    Function(File) onDocumentSelected,
  ) async {
    try {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        _showPermissionDeniedDialog(context, 'Storage');
        return;
      }
      
      // Simulate document picker - replace with actual file picker
      print('Document picker initiated');
      // final FilePickerResult? result = await FilePicker.platform.pickFiles();
      // if (result != null) {
      //   onDocumentSelected(File(result.files.single.path!));
      // }
    } catch (e) {
      _showErrorDialog(context, 'Failed to pick document: \');
    }
  }

  Future<void> _shareLocation(BuildContext context) async {
    try {
      print('Location sharing initiated');
      // Implement location sharing
    } catch (e) {
      _showErrorDialog(context, 'Failed to share location: \');
    }
  }

  Future<void> _shareContact(BuildContext context) async {
    try {
      print('Contact sharing initiated');
      // Implement contact sharing
    } catch (e) {
      _showErrorDialog(context, 'Failed to share contact: \');
    }
  }

  /// Upload file to Firebase Storage
  Future<String> uploadFile(
    File file,
    String conversationId,
    MessageType type, {
    Function(double)? onProgress,
  }) async {
    try {
      // Simulate file upload - replace with actual Firebase Storage upload
      if (onProgress != null) {
        // Simulate progress
        for (int i = 0; i <= 100; i += 10) {
          await Future.delayed(Duration(milliseconds: 100));
          onProgress(i / 100.0);
        }
      }
      
      // Return simulated download URL
      return 'https://example.com/uploads/\';
    } catch (e) {
      throw Exception('Failed to upload file: \');
    }
  }

  /// Generate thumbnail for video
  Future<String> generateVideoThumbnail(String videoPath) async {
    try {
      // Simulate thumbnail generation - replace with actual video thumbnail
      return 'https://example.com/thumbnails/\';
    } catch (e) {
      throw Exception('Failed to generate thumbnail: \');
    }
  }

  /// Show calling interface
  Future<void> initiateCall(
    BuildContext context,
    String receiverId,
    String receiverName,
    CallType callType,
  ) async {
    try {
      final hasAudioPermission = await requestMicrophonePermission();
      if (!hasAudioPermission) {
        _showPermissionDeniedDialog(context, 'Microphone');
        return;
      }

      if (callType == CallType.video) {
        final hasVideoPermission = await requestCameraPermission();
        if (!hasVideoPermission) {
          _showPermissionDeniedDialog(context, 'Camera');
          return;
        }
      }

      // Navigate to call screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            receiverId: receiverId,
            receiverName: receiverName,
            callType: callType,
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog(context, 'Failed to initiate call: \');
    }
  }

  void _showPermissionDeniedDialog(BuildContext context, String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text('\ permission is required for this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Call Screen Widget
class CallScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final CallType callType;

  const CallScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.callType,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoOn = true;
  CallStatus _callStatus = CallStatus.ringing;
  DateTime? _callStartTime;

  @override
  void initState() {
    super.initState();
    _initiateCall();
  }

  void _initiateCall() {
    // Simulate call initiation
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _callStatus = CallStatus.answered;
          _callStartTime = DateTime.now();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Call info
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        widget.receiverName.isNotEmpty 
                            ? widget.receiverName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      widget.receiverName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _getCallStatusText(),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Call controls
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(
                    Icons.mic_off,
                    _isMuted,
                    () => setState(() => _isMuted = !_isMuted),
                  ),
                  if (widget.callType == CallType.video)
                    _buildCallButton(
                      Icons.videocam_off,
                      !_isVideoOn,
                      () => setState(() => _isVideoOn = !_isVideoOn),
                    ),
                  _buildCallButton(
                    Icons.volume_up,
                    _isSpeakerOn,
                    () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                  ),
                  _buildEndCallButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.call_end,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  String _getCallStatusText() {
    switch (_callStatus) {
      case CallStatus.ringing:
        return 'Calling...';
      case CallStatus.answered:
        if (_callStartTime != null) {
          final duration = DateTime.now().difference(_callStartTime!);
          final minutes = duration.inMinutes;
          final seconds = duration.inSeconds % 60;
          return '\:\';
        }
        return 'Connected';
      default:
        return 'Call ended';
    }
  }
}
