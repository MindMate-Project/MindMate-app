/// Optional lead-time alerts
class NotifyBeforeOptions {
  const NotifyBeforeOptions({this.remind24h = false, this.remind1h = false});

  final bool remind24h;
  final bool remind1h;

  static const offset24h = '24h';
  static const offset1h = '1h';

  List<String> get selectedOffsets => [
        if (remind24h) offset24h,
        if (remind1h) offset1h,
      ];

  bool get hasAny => remind24h || remind1h;
}
