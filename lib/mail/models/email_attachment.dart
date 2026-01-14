// lib/mail/models/email_attachment.dart

/// Represents a file attached to an email
class EmailAttachment {
  final String name;
  final String mimeType;
  final int sizeBytes;
  final String? contentPreview; // Base64 preview for small images
  final String? downloadUrl; // If stored in cloud storage
  final String? attachmentId; // Gmail API attachment ID

  const EmailAttachment({
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    this.contentPreview,
    this.downloadUrl,
    this.attachmentId,
  });

  /// Create from JSON (Firestore or API)
  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      name: json['name'] ?? 'Untitled',
      mimeType: json['type'] ?? 'application/octet-stream',
      sizeBytes: json['size'] ?? 0,
      contentPreview: json['content_preview'],
      downloadUrl: json['download_url'],
      attachmentId: json['attachment_id'],
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': mimeType,
      'size': sizeBytes,
      if (contentPreview != null) 'content_preview': contentPreview,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (attachmentId != null) 'attachment_id': attachmentId,
    };
  }

  /// Helper to check if it's an image
  bool get isImage => mimeType.startsWith('image/');

  /// Helper to check if it's a PDF
  bool get isPdf => mimeType == 'application/pdf';
}
