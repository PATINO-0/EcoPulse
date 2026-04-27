class AppConfigurationException implements Exception {
  final String message;

  const AppConfigurationException(this.message);

  @override
  String toString() {
    return message;
  }
}