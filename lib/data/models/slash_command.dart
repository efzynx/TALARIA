enum SlashCommandType {
  system,
  model,
  reasoning,
  skill,
}

class SlashCommandItem {
  final String trigger; // e.g. "/model", "/reverse-engineer-anything"
  final String title;
  final String description;
  final SlashCommandType type;
  final String? category;

  const SlashCommandItem({
    required this.trigger,
    required this.title,
    required this.description,
    required this.type,
    this.category,
  });

  bool matches(String query) {
    final cleanQuery = query.startsWith('/') ? query.substring(1).toLowerCase() : query.toLowerCase();
    if (cleanQuery.isEmpty) return true;

    final cleanTrigger = trigger.startsWith('/') ? trigger.substring(1).toLowerCase() : trigger.toLowerCase();
    return cleanTrigger.contains(cleanQuery) ||
        title.toLowerCase().contains(cleanQuery) ||
        description.toLowerCase().contains(cleanQuery);
  }
}
