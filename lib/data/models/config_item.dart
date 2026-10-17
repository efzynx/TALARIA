class HermesModelProvider {
  final String slug;
  final String name;
  final List<String> models;

  const HermesModelProvider({
    required this.slug,
    required this.name,
    this.models = const [],
  });

  factory HermesModelProvider.fromJson(Map<String, dynamic> json) {
    final rawModels = (json['models'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return HermesModelProvider(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? json['slug'] as String? ?? 'Provider',
      models: rawModels,
    );
  }
}

class HermesConfig {
  final String activeModel;
  final String activeProvider;
  final String reasoningEffort; // none, low, medium, high, ultra
  final List<String> enabledTools;
  final List<HermesModelProvider> availableProviders;
  final Map<String, dynamic> rawConfig;

  const HermesConfig({
    this.activeModel = 'AG-gemini',
    this.activeProvider = 'custom',
    this.reasoningEffort = 'high',
    this.enabledTools = const ['terminal', 'read_file', 'write_file', 'patch', 'search_files'],
    this.availableProviders = const [],
    this.rawConfig = const {},
  });

  List<String> get allAvailableModels {
    final list = <String>[];
    for (final p in availableProviders) {
      for (final m in p.models) {
        if (!list.contains(m)) {
          list.add(m);
        }
      }
    }
    if (activeModel.isNotEmpty && !list.contains(activeModel)) {
      list.insert(0, activeModel);
    }
    return list;
  }

  factory HermesConfig.fromModelOptions(Map<String, dynamic> json, {String? reasoning}) {
    final providersJson = json['providers'] as List? ?? [];
    final providers = providersJson
        .map((e) => HermesModelProvider.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final model = json['model'] as String? ?? 'AG-gemini';
    final provider = json['provider'] as String? ?? 'custom';

    return HermesConfig(
      activeModel: model,
      activeProvider: provider,
      reasoningEffort: reasoning ?? 'high',
      availableProviders: providers,
      rawConfig: json,
    );
  }

  factory HermesConfig.fromJson(Map<String, dynamic> json) {
    final toolsList = (json['tools'] as List?)?.map((e) => e.toString()).toList() ??
        ['terminal', 'read_file', 'write_file', 'patch', 'search_files'];

    return HermesConfig(
      activeModel: json['model'] as String? ?? 'AG-gemini',
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
    List<HermesModelProvider>? availableProviders,
    Map<String, dynamic>? rawConfig,
  }) {
    return HermesConfig(
      activeModel: activeModel ?? this.activeModel,
      activeProvider: activeProvider ?? this.activeProvider,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      enabledTools: enabledTools ?? this.enabledTools,
      availableProviders: availableProviders ?? this.availableProviders,
      rawConfig: rawConfig ?? this.rawConfig,
    );
  }
}
