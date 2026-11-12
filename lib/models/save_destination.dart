enum SaveDestination {
  photos,
  files;

  String get actionKey => this == photos ? 'saveToPhotos' : 'saveToFiles';
  String get successKey => this == photos ? 'savedToPhotos' : 'savedToFiles';
}
