class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime date;
  final String? imagePath; // New field for image path

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    this.imagePath, // Allow null value for notes without images
  });

  // Convert the Note object to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'imagePath': imagePath, // Include imagePath in the map
    };
  }

  // Create a Note object from a Map
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: DateTime.parse(map['date']),
      imagePath: map['imagePath'], // Retrieve imagePath from the map
    );
  }
}
