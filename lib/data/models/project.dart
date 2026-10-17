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

  factory HermesProject.fromJson(Map<String, dynamic> json) {
    return HermesProject(
      id: json['id'] as String? ?? json['name'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Project',
      path: json['path'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? json['active'] as bool? ?? false,
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
