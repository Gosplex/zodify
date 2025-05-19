extension StringExtensions on String? {
  String capitalizeFirstWord() {
    if (this == null || this!.isEmpty) {
      return 'Unknown';
    }
    return this![0].toUpperCase() + this!.substring(1).toLowerCase();
  }
}