import 'package:cloud_firestore/cloud_firestore.dart';
import 'phrase.dart';
import 'vocab.dart';

class Category {
  final String id;
  final String name;
  final int order;
  final List<String> goals;
  final List<Phrase> keyPhrases;
  final List<Vocab> vocab;
  final List<String> practiceTasks;
  final String? chatSystemPrompt;

  final int? attemptsCount;
  final DateTime? lastPracticedAt;
  final num? masteryScore;
  final String? activeSessionId;

  const Category({
    required this.id,
    required this.name,
    this.order = 99,
    this.goals = const [],
    this.keyPhrases = const [],
    this.vocab = const [],
    this.practiceTasks = const [],
    this.chatSystemPrompt,
    this.attemptsCount,
    this.lastPracticedAt,
    this.masteryScore,
    this.activeSessionId,
  });

  Category copyWith({
    String? id,
    String? name,
    int? order,
    List<String>? goals,
    List<Phrase>? keyPhrases,
    List<Vocab>? vocab,
    List<String>? practiceTasks,
    String? chatSystemPrompt,
    int? attemptsCount,
    DateTime? lastPracticedAt,
    num? masteryScore,
    String? activeSessionId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      goals: goals ?? this.goals,
      keyPhrases: keyPhrases ?? this.keyPhrases,
      vocab: vocab ?? this.vocab,
      practiceTasks: practiceTasks ?? this.practiceTasks,
      chatSystemPrompt: chatSystemPrompt ?? this.chatSystemPrompt,
      attemptsCount: attemptsCount ?? this.attemptsCount,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      masteryScore: masteryScore ?? this.masteryScore,
      activeSessionId: activeSessionId ?? this.activeSessionId,
    );
  }

  static Category fromFirestore(String id, Map<String, dynamic> data) {
    DateTime? practiced;
    final lp = data['lastPracticedAt'];
    if (lp is Timestamp) practiced = lp.toDate();
    if (lp is DateTime) practiced = lp;

    return Category(
      id: id,
      name: (data['name'] as String? ?? '').trim(),
      order: (data['order'] as num?)?.toInt() ?? 99,
      goals:
          (data['goals'] as List<dynamic>?)
              ?.map((e) => (e as String?)?.trim() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      keyPhrases:
          (data['keyPhrases'] as List<dynamic>?)
              ?.map(
                (e) =>
                    Phrase.fromFirestore(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          const [],
      vocab:
          (data['vocab'] as List<dynamic>?)
              ?.map(
                (e) => Vocab.fromFirestore(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          const [],
      practiceTasks:
          (data['practiceTasks'] as List<dynamic>?)
              ?.map((e) => (e as String?)?.trim() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      chatSystemPrompt: (data['chatSystemPrompt'] as String?)?.trim(),
      attemptsCount: (data['attemptsCount'] as num?)?.toInt(),
      lastPracticedAt: practiced,
      masteryScore: data['masteryScore'] as num?,
      activeSessionId: data['activeSessionId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'order': order,
    'goals': goals,
    'keyPhrases': keyPhrases.map((p) => p.toFirestore()).toList(),
    'vocab': vocab.map((v) => v.toFirestore()).toList(),
    'practiceTasks': practiceTasks,
    if (chatSystemPrompt != null) 'chatSystemPrompt': chatSystemPrompt,
    if (attemptsCount != null) 'attemptsCount': attemptsCount,
    if (lastPracticedAt != null)
      'lastPracticedAt': Timestamp.fromDate(lastPracticedAt!),
    if (masteryScore != null) 'masteryScore': masteryScore,
    if (activeSessionId != null) 'activeSessionId': activeSessionId,
  };
}
