/// Categories of failures the UI knows how to present.
enum AppErrorType {
  timeout,
  network,
  notFound,
  server,
  invalidData,
  cancelled,
  unknown,
}

/// A failure that is safe to show to the user.
///
/// The repository converts Dio errors and malformed responses into this type
/// so that state and UI code never deal with raw exceptions or stack traces.
class AppException implements Exception {
  AppException(this.type, {this.statusCode});

  /// Wraps any error so callers can always work with an [AppException].
  factory AppException.from(Object error) =>
      error is AppException ? error : AppException(AppErrorType.unknown);

  final AppErrorType type;
  final int? statusCode;

  bool get isCancelled => type == AppErrorType.cancelled;

  String get message => switch (type) {
    AppErrorType.timeout => 'หมดเวลาการเชื่อมต่อ กรุณาลองใหม่อีกครั้ง',
    AppErrorType.network =>
      'เชื่อมต่ออินเทอร์เน็ตไม่ได้ ตรวจสอบการเชื่อมต่อแล้วลองใหม่',
    AppErrorType.notFound => 'ไม่พบสินค้า',
    AppErrorType.server => 'เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่ภายหลัง',
    AppErrorType.invalidData => 'ได้รับข้อมูลที่ไม่ถูกต้องจากเซิร์ฟเวอร์',
    AppErrorType.cancelled => 'ยกเลิกคำขอแล้ว',
    AppErrorType.unknown => 'เกิดข้อผิดพลาด กรุณาลองใหม่',
  };

  @override
  String toString() => 'AppException($type, statusCode: $statusCode)';
}
