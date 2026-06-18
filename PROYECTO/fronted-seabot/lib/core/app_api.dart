class AppCore {
  // ⚠️ No colocar claves reales de OpenAI en frontend si la app será distribuida.
  static const String openAIKey = "";

  // Backend URLs
  static const String cloudRunBaseUrl =
      "https://seabot-backend-993787742289.us-central1.run.app";

  static const String localBaseUrl =
      "http://192.168.0.6:8080";

  // Cambia solo esta línea según dónde quieras apuntar:
  static const String baseApiUrl = cloudRunBaseUrl;
  // static const String baseApiUrl = localBaseUrl;
}