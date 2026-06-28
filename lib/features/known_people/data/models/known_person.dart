/// Whether the form registers a new person or adds photos to an existing one.
enum KnownPersonFormMode {
  register,
  addPhotos,
}

/// Relationship chips shown when registering a new known person.
abstract final class KnownPersonRelationships {
  static const List<String> options = [
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Husband',
    'Wife',
    'Grandchild',
    'Friend',
    'Doctor',
    'Nurse',
    'Neighbour',
    'Other',
  ];
}
