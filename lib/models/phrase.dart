class Phrase {
  final String phrase;
  final String translation;

  const Phrase({required this.phrase, required this.translation});

  Map<String, dynamic> toFirestore() => {
    'phrase': phrase,
    'translation': translation,
  };

  factory Phrase.fromFirestore(Map<String, dynamic> data) => Phrase(
    phrase: (data['phrase'] as String? ?? '').trim(),
    translation: (data['translation'] as String? ?? '').trim(),
  );
}
