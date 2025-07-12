// lib/services/lesson_plan_storage.dart

class LessonPlanStorage {
  static String? _lessonPlan;

  static void saveLessonPlan(String lessonPlan) {
    _lessonPlan = lessonPlan;
  }

  static String getLessonPlan() {
    return _lessonPlan ?? 'No lesson plan saved.';
  }

  static void clearLessonPlan() {
    _lessonPlan = null;
  }
}
