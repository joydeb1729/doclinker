import 'package:flutter/material.dart';

/* 
FIREBASE STORAGE AND IMAGE PICKER SETUP REQUIRED:

To enable profile photo upload functionality, add these dependencies to pubspec.yaml:

dependencies:
  firebase_storage: ^11.6.0
  image_picker: ^1.0.7
  path: ^1.8.3

Then configure Firebase Storage security rules:
service firebase.storage {
  match /b/{bucket}/o {
    match /doctor_profiles/{imageId} {
      allow read, write: if request.auth != null;
    }
  }
}

USAGE:
1. User clicks profile photo
2. Shows ImageSourceHelper.showImageSourceSelection()
3. User selects camera or gallery
4. Image is picked and uploaded via ImageUploadService.uploadDoctorProfilePhoto()
5. URL is saved to DoctorProfile.profileImageUrl

For now, this service provides placeholders and structure.
*/

class ImageUploadService {
  // Placeholder for image upload - requires firebase_storage package
  static Future<String> uploadDoctorProfilePhoto({
    required String doctorId,
    required String imagePath,
  }) async {
    throw UnimplementedError(
      'Image upload requires firebase_storage package. '
      'Add firebase_storage: ^11.6.0 to pubspec.yaml to enable this feature.',
    );
  }

  // Placeholder for image selection - requires image_picker package
  static Future<void> pickImageFromGallery() async {
    throw UnimplementedError(
      'Image picker requires image_picker package. '
      'Add image_picker: ^1.0.7 to pubspec.yaml to enable this feature.',
    );
  }

  // Placeholder for camera - requires image_picker package
  static Future<void> pickImageFromCamera() async {
    throw UnimplementedError(
      'Camera requires image_picker package. '
      'Add image_picker: ^1.0.7 to pubspec.yaml to enable this feature.',
    );
  }

  // Validate file size (utility that works without packages)
  static bool isValidFileSize(int fileSizeBytes, {double maxSizeMB = 5.0}) {
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    return fileSizeBytes <= maxSizeBytes;
  }
}

// UI helper for photo selection
class PhotoUploadWidget extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onTap;
  final double size;

  const PhotoUploadWidget({
    super.key,
    this.imageUrl,
    this.onTap,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder();
                  },
                ),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: size * 0.3, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          'Add Photo',
          style: TextStyle(color: Colors.grey.shade600, fontSize: size * 0.1),
        ),
      ],
    );
  }
}

// Show coming soon dialog for photo upload
class PhotoUploadHelper {
  static void showPhotoUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Upload'),
        content: const Text(
          'Photo upload functionality will be available after adding:\n\n'
          '• firebase_storage: ^11.6.0\n'
          '• image_picker: ^1.0.7\n\n'
          'to pubspec.yaml dependencies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
