class AccountProfile {
  const AccountProfile({
    this.uid,
    this.name = 'Khách',
    this.email,
    this.photoUrl,
    this.googleLinked = false,
  });

  final String? uid;
  final String name;
  final String? email;
  final String? photoUrl;
  final bool googleLinked;
  bool get signedIn => uid != null;

  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'UTH';
    // Initials include the user's given names, e.g. Nguyễn Minh Anh → MA.
    return words
        .skip(words.length > 2 ? words.length - 2 : 0)
        .map((word) => String.fromCharCode(word.runes.first))
        .join()
        .toUpperCase();
  }
}
