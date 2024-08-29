



class Note {

  String title;
  String path;
  String length;

  // Constructor
  Note({
    required this.title,
    required this.path,
    required this.length,
  });

  // Convert a Note object to a Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'path': path,
      'length': length,
    };
  }

  // Create a Note object from a Map (JSON)
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      title: json['title'],
      path: json['path'],
      length: json['length'],
    );
  }
}
