class HermesProject {
  final String id;
  final String name;
  final String path;
  final bool isActive;
  final String? repoUrl;
  final String? description;

  const HermesProject({
    required this.id,
    required this.name,
    required this.path,
    this.isActive = false,
    this.repoUrl,
    this.description,
  });

  factory HermesProject.fromJson(Map<String, dynamic> json, {String? activeId}) {
    String resolvedPath = json['primary_path'] as String? ??
        json['path'] as String? ??
        json['cwd'] as String? ??
        '';
    if (resolvedPath.isEmpty && json['folders'] is List && (json['folders'] as List).isNotEmpty) {
      final firstFolder = json['folders'][0];
      if (firstFolder is Map) {
        resolvedPath = firstFolder['path']?.toString() ?? '';
      }
    }

    final id = json['id'] as String? ?? json['slug'] as String? ?? json['name'] as String? ?? '';
    final isActive = (activeId != null && activeId.isNotEmpty)
        ? (id == activeId)
        : (json['is_active'] as bool? ?? json['active'] as bool? ?? false);

    return HermesProject(
      id: id,
      name: json['name'] as String? ?? json['slug'] as String? ?? 'Untitled Project',
      path: resolvedPath,
      isActive: isActive,
      repoUrl: json['repo_url'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'is_active': isActive,
        if (repoUrl != null) 'repo_url': repoUrl,
        if (description != null) 'description': description,
      };

  HermesProject copyWith({
    String? id,
    String? name,
    String? path,
    bool? isActive,
    String? repoUrl,
    String? description,
  }) {
    return HermesProject(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      isActive: isActive ?? this.isActive,
      repoUrl: repoUrl ?? this.repoUrl,
      description: description ?? this.description,
    );
  }
}
