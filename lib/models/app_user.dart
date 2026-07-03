class AppUser {
  const AppUser({required this.name, required this.email});

  final String name;
  final String email;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'AI';
    }
    if (parts.length == 1) {
      final part = parts.first;
      return part.substring(0, part.length < 2 ? part.length : 2).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
