class ReminderItem {
  final String id;
  final String type; // 'appointment' | 'medication'
  final DateTime scheduledTime;
  final bool isSent;
  final String? groupId;

  // Appointment-specific
  final String? doctorName;
  final String? specialty;
  final String? location;
  final String? appointmentType;
  final DateTime? appointmentDate;
  final String? notes;

  // Medication-specific 
  final String? medicineName;
  final String? dosage;
  final String? form;
  final String? frequency;
  final int? timesPerDay;
  final DateTime? startDate;
  final DateTime? endDate;

  const ReminderItem({
    required this.id,
    required this.type,
    required this.scheduledTime,
    required this.isSent,
    this.groupId,
    this.doctorName,
    this.specialty,
    this.location,
    this.appointmentType,
    this.appointmentDate,
    this.notes,
    this.medicineName,
    this.dosage,
    this.form,
    this.frequency,
    this.timesPerDay,
    this.startDate,
    this.endDate,
  });

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) {
        return value.isUtc ? value.toLocal() : value;
      }
      final s = value.toString().trim();
      if (s.isEmpty) return null;
      final parsed = DateTime.tryParse(s);
      if (parsed == null) return null;
      return parsed.isUtc ? parsed.toLocal() : parsed;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final s = value.toString().trim();
      if (s.isEmpty) return null;
      return int.tryParse(s);
    }

    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final type = json['type']?.toString() ?? '';
    final scheduledTime =
        parseDate(json['scheduledTime']) ??
            DateTime.fromMillisecondsSinceEpoch(0);

    final isSentValue = json['isSent'];
    final isSent = isSentValue == true ||
        (isSentValue is String &&
            (isSentValue.toLowerCase() == 'true' ||
                isSentValue.toLowerCase() == '1'));

    return ReminderItem(
      id: id,
      type: type,
      scheduledTime: scheduledTime,
      isSent: isSent,
      groupId: json['groupId']?.toString(),
      doctorName: json['doctorName']?.toString(),
      specialty: json['specialty']?.toString(),
      location: json['location']?.toString(),
      appointmentType: json['appointmentType']?.toString(),
      appointmentDate: parseDate(json['appointmentDate']),
      notes: json['notes']?.toString(),
      medicineName: json['medicineName']?.toString(),
      dosage: json['dosage']?.toString(),
      form: json['form']?.toString(),
      frequency: json['frequency']?.toString(),
      timesPerDay: parseInt(json['timesPerDay']),
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
    );
  }
}

