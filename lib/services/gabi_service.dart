import 'package:flutter/foundation.dart';
import 'openai_service.dart';

class GabiService {
  static Future<String> generateLessonPlanFromTranscript({
    required String transcript,
    required String language,
  }) async {
    const systemPrompt = '''
You are Gabi, a language coach. Create a concise, actionable LESSON PLAN in Markdown
based on the user's spoken transcript and target language. Use this structure:

# Lesson Plan: <Language>
## Objectives
- 3–5 bullets
## Vocabulary
- word — short gloss
## Drills
1) ...
2) ...
## Practice Prompt
One short prompt in the target language.

Keep it under ~250–400 words. Do not include code fences.
''';

    final userMsg = 'Language: $language\nLearner said:\n"$transcript"';

    try {
      final md = await OpenAIService.instance.chat(systemPrompt, userMsg);
      if (md.trim().isEmpty) return _fallbackPlan(language);
      return md;
    } catch (e) {
      // Log and **fallback** so the app flow continues.
      debugPrint('Lesson plan failed: $e');
      return _fallbackPlan(language);
    }
  }

  static String _fallbackPlan(String language) => '''
# Lesson Plan: $language Basics
## Objectives
- Share what you did last weekend
- Use past tense with time markers
- Practice 6 core verbs

## Vocabulary
- fin de semana — weekend
- hice — I did
- fui — I went
- comí — I ate
- vi — I saw
- con — with

## Drills
1) Repeat: "El fin de semana pasado, yo ___".
2) Fill in verbs: hice / fui / comí / vi.
3) Describe 2 activities you did.

## Practice Prompt
En $language, describe lo que hiciste el fin de semana pasado en 3–4 frases.
''';
}
