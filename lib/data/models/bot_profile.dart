import 'package:flutter/material.dart';

/// Represents a specialist agent / bot profile configured on the Hermes daemon.
/// (e.g. default, pixel, forge, helm, atlas, sentry, ian)
class BotProfile {
  final String name;
  final String displayName;
  final String description;
  final String path;
  final String? model;
  final String? provider;
  final int skillCount;
  final bool isDefault;
  final Color badgeColor;
  final String badgeLetter;
  final String? lastSessionTitle;
  final DateTime? lastActive;

  const BotProfile({
    required this.name,
    required this.displayName,
    required this.description,
    required this.path,
    this.model,
    this.provider,
    this.skillCount = 0,
    this.isDefault = false,
    required this.badgeColor,
    required this.badgeLetter,
    this.lastSessionTitle,
    this.lastActive,
  });

  static const Map<String, Map<String, dynamic>> _knownPresets = {
    'default': {
      'display': 'Hermes Core',
      'role': 'General Purpose Agent & Orchestrator',
      'color': Color(0xFF00E5FF),
      'letter': 'H',
    },
    'pixel': {
      'display': 'Pixel',
      'role': 'Frontend, UI/UX & Mobile Specialist',
      'color': Color(0xFFF43F5E),
      'letter': 'P',
    },
    'forge': {
      'display': 'Forge',
      'role': 'Backend Systems, APIs & Databases',
      'color': Color(0xFF10B981),
      'letter': 'F',
    },
    'helm': {
      'display': 'Helm',
      'role': 'DevOps, Containers, CI/CD & Cloud Infra',
      'color': Color(0xFFF59E0B),
      'letter': 'H',
    },
    'atlas': {
      'display': 'Atlas',
      'role': 'System Architect & Knowledge Graph',
      'color': Color(0xFF6366F1),
      'letter': 'A',
    },
    'sentry': {
      'display': 'Sentry',
      'role': 'QA, Security Audit & Code Verification',
      'color': Color(0xFFEC4899),
      'letter': 'S',
    },
    'ian': {
      'display': 'Ian',
      'role': 'Research, Reconnaissance & Telemetry',
      'color': Color(0xFF38BDF8),
      'letter': 'I',
    },
  };

  factory BotProfile.fromRow(Map<String, dynamic> row) {
    final name = (row['name'] as String? ?? 'default').toLowerCase();
    final preset = _knownPresets[name] ?? {};

    final presetDisplay = preset['display'] as String?;
    final presetRole = preset['role'] as String?;
    final presetColor = preset['color'] as Color?;
    final presetLetter = preset['letter'] as String?;

    final displayName = (row['display_name'] as String?)?.trim().isNotEmpty == true
        ? row['display_name'] as String
        : (presetDisplay ?? name.toUpperCase());

    final description = (row['description'] as String?)?.trim().isNotEmpty == true
        ? row['description'] as String
        : (presetRole ?? 'Specialist Agent on this host');

    final color = presetColor ?? _deriveColor(name);
    final letter = presetLetter ?? (displayName.isNotEmpty ? displayName[0].toUpperCase() : 'B');

    String? lastTitle;
    final lastSession = row['last_session'];
    if (lastSession is Map) {
      lastTitle = lastSession['title'] as String?;
    }

    return BotProfile(
      name: name,
      displayName: displayName,
      description: description,
      path: row['path'] as String? ?? '',
      model: row['model'] as String?,
      provider: row['provider'] as String?,
      skillCount: (row['skill_count'] as num?)?.toInt() ?? 0,
      isDefault: row['is_default'] as bool? ?? (name == 'default'),
      badgeColor: color,
      badgeLetter: letter,
      lastSessionTitle: lastTitle,
    );
  }

  static List<BotProfile> defaultFallbackBots() {
    return _knownPresets.entries.map((e) {
      return BotProfile(
        name: e.key,
        displayName: e.value['display'] as String,
        description: e.value['role'] as String,
        path: '/home/efzyn/.hermes/profiles/${e.key}',
        badgeColor: e.value['color'] as Color,
        badgeLetter: e.value['letter'] as String,
        isDefault: e.key == 'default',
        skillCount: e.key == 'default' ? 36 : 18,
      );
    }).toList();
  }

  static Color _deriveColor(String name) {
    final colors = [
      const Color(0xFF00E5FF),
      const Color(0xFFF43F5E),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF38BDF8),
      const Color(0xFF8B5CF6),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}
