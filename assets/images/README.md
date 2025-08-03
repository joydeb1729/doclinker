# Assets/Images Folder

This folder is for storing your app's images and icons.

## Usage

### Adding Images
1. Place your image files (PNG, JPG, SVG, etc.) in this folder
2. Reference them in your Flutter code like this:

```dart
Image.asset('assets/images/your_image.png')
```

### Adding Icons
1. Place your icon files in this folder
2. Use them in your Flutter widgets:

```dart
// For regular images
Image.asset('assets/images/icon.png')

// For SVG icons (if using flutter_svg package)
SvgPicture.asset('assets/images/icon.svg')
```

### Recommended File Structure
```
assets/images/
├── icons/
│   ├── app_icon.png
│   ├── google_icon.png
│   └── facebook_icon.png
├── logos/
│   ├── logo_primary.png
│   └── logo_secondary.png
└── backgrounds/
    ├── splash_bg.png
    └── auth_bg.png
```

### File Naming Convention
- Use lowercase letters
- Separate words with underscores
- Use descriptive names
- Examples: `google_signin_icon.png`, `app_logo_primary.png`

### Supported Formats
- PNG (recommended for icons and logos)
- JPG/JPEG (good for photos)
- SVG (scalable, good for icons)
- WebP (modern, efficient)

### Performance Tips
- Optimize images for mobile (compress when possible)
- Use appropriate sizes (don't use 4K images for small icons)
- Consider using different resolutions for different screen densities 