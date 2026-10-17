class HermesConfig {
  final String activeModel;
  final String activeProvider;
  final String reasoningEffort; // none, low, medium, high, ultra
  final List<String> enabledTools;
  final Map<String, dynamic> rawConfig;

  const HermesConfig({
    this.activeModel = 'custom/AG-gemini',
    this.activeProvider = 'custom',
    this.reasoningEffort = 'high',
    this.enabledTools = const ['terminal', 'read_file', 'write_file', 'patch', 'search_files'],
    this.rawConfig = const {},
  });

  factory HermesConfig.fromJson(Map<String, dynamic> json) {
    final toolsList = (json['tools'] as List?)?.map((e) => e.toString()).toList() ??
        ['terminal', 'read_file', 'write_file', 'patch', 'search_files'];

    return HermesConfig(
      activeModel: json['model'] as String? ?? 'custom/AG-gemini',
      activeProvider: json['provider'] as String? ?? 'custom',
      reasoningEffort: json['reasoning_effort'] as String? ?? 'high',
      enabledTools: toolsList,
      rawConfig: json,
    );
  }

  HermesConfig copyWith({
    String? activeModel,
    String? activeProvider,
    String? reasoningEffort,
    List<String>? enabledTools,
    Map<String, dynamic>? rawConfig,
  }) {
    return HermesConfig(
      activeModel: activeModel ?? this.activeModel,
      activeProvider: activeProvider ?? this.activeProvider,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      enabledTools: enabledTools ?? this.enabledTools,
      rawConfig: rawConfig ?? this.rawConfig,
    );
  }
}
