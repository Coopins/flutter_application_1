class Vocab {
  final String term;
  final String translation;

  const Vocab({required this.term, required this.translation});

  Map<String, dynamic> toFirestore() => {
    'term': term,
    'translation': translation,
  };

  factory Vocab.fromFirestore(Map<String, dynamic> data) => Vocab(
    term: (data['term'] as String? ?? '').trim(),
    translation: (data['translation'] as String? ?? '').trim(),
  );
}
