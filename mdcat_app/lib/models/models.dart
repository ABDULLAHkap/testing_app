class UserModel {
  final int id;
  final String username;
  final String email;
  final DateTime? examDate;
  final String? gender;
  final String? phone;
  final String targetExam;
  final bool emailVerified;
  final bool isAdmin;
  final int freeTestsRemaining;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.examDate,
    this.gender,
    this.phone,
    this.targetExam = 'MDCAT',
    this.emailVerified = false,
    this.isAdmin = false,
    this.freeTestsRemaining = 3,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      examDate: json['exam_date'] != null
          ? DateTime.parse(json['exam_date'])
          : null,
      gender: json['gender'],
      phone: json['phone'],
      targetExam: json['target_exam'] ?? 'MDCAT',
      emailVerified: json['email_verified'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      freeTestsRemaining: json['free_tests_remaining'] ?? 3,
    );
  }
}

class DashboardStats {
  final DateTime? examDate;
  final int testsDone;
  final double avgScore;
  final double bestScore;
  final int streakDays;

  DashboardStats({
    required this.examDate,
    required this.testsDone,
    required this.avgScore,
    required this.bestScore,
    required this.streakDays,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      examDate: json['exam_date'] != null
          ? DateTime.parse(json['exam_date'])
          : null,
      testsDone: json['tests_done'],
      avgScore: (json['avg_score'] as num).toDouble(),
      bestScore: (json['best_score'] as num).toDouble(),
      streakDays: json['streak_days'],
    );
  }
}

class TopicListItem {
  final String subject;
  final List<String> topics;

  TopicListItem({required this.subject, required this.topics});

  factory TopicListItem.fromJson(Map<String, dynamic> json) {
    return TopicListItem(
      subject: json['subject'],
      topics: List<String>.from(json['topics']),
    );
  }
}

class ExamSection {
  final String name;
  final String kind;
  final int? questions;
  final int? minutes;

  const ExamSection({
    required this.name,
    required this.kind,
    this.questions,
    this.minutes,
  });

  factory ExamSection.fromJson(Map<String, dynamic> json) => ExamSection(
    name: json['name']?.toString() ?? '',
    kind: json['kind']?.toString() ?? 'mcq',
    questions: (json['questions'] as num?)?.toInt(),
    minutes: (json['minutes'] as num?)?.toInt(),
  );
}

class ExamFormat {
  final String examType;
  final String title;
  final String version;
  final int durationMinutes;
  final int totalQuestions;
  final double negativeMarking;
  final String delivery;
  final bool supportsFullMcqMock;
  final String? officialSource;
  final List<ExamSection> sections;
  final List<String> notes;

  const ExamFormat({
    required this.examType,
    required this.title,
    required this.version,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.negativeMarking,
    required this.delivery,
    required this.supportsFullMcqMock,
    required this.sections,
    required this.notes,
    this.officialSource,
  });

  factory ExamFormat.fromJson(Map<String, dynamic> json) => ExamFormat(
    examType: json['exam_type']?.toString() ?? 'Exam',
    title: json['title']?.toString() ?? 'Exam format',
    version: json['version']?.toString() ?? '',
    durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
    totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
    negativeMarking: (json['negative_marking'] as num?)?.toDouble() ?? 0,
    delivery: json['delivery']?.toString() ?? '',
    supportsFullMcqMock: json['supports_full_mcq_mock'] == true,
    officialSource: json['official_source']?.toString(),
    sections: (json['sections'] as List? ?? [])
        .map((item) => ExamSection.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    notes: List<String>.from(json['notes'] as List? ?? const []),
  );
}

class PastPaperSummary {
  final String id;
  final String title;
  final int totalQuestions;
  final int quizMinutes;
  final String examType;
  final int year;
  final String subject;
  final String board;
  final String sourceType;
  final bool isOfficial;
  final bool downloadAvailable;
  final String? officialSource;

  PastPaperSummary({
    required this.id,
    required this.title,
    required this.totalQuestions,
    required this.quizMinutes,
    required this.examType,
    required this.year,
    required this.subject,
    required this.board,
    required this.sourceType,
    required this.isOfficial,
    required this.downloadAvailable,
    this.officialSource,
  });

  factory PastPaperSummary.fromJson(Map<String, dynamic> json) {
    return PastPaperSummary(
      id: json['id'],
      title: json['title'],
      totalQuestions: json['total_questions'],
      quizMinutes: json['quiz_minutes'],
      examType: json['exam_type'] ?? 'Exam',
      year: (json['year'] as num?)?.toInt() ?? 0,
      subject: json['subject'] ?? 'All Subjects',
      board: json['board'] ?? '',
      sourceType: json['source_type'] ?? 'practice',
      isOfficial: json['is_official'] == true,
      downloadAvailable: json['download_available'] != false,
      officialSource: json['official_source'],
    );
  }
}

class SubjectBreakdownItem {
  final String subject;
  final double weightPercent;
  final int mcqCount;

  SubjectBreakdownItem({
    required this.subject,
    required this.weightPercent,
    required this.mcqCount,
  });

  factory SubjectBreakdownItem.fromJson(Map<String, dynamic> json) {
    return SubjectBreakdownItem(
      subject: json['subject'],
      weightPercent: (json['weight_percent'] as num).toDouble(),
      mcqCount: json['mcq_count'],
    );
  }
}

class PastPaperDetail {
  final String id;
  final String title;
  final int totalQuestions;
  final int quizMinutes;
  final int totalMarks;
  final double marksPerCorrect;
  final double marksPenaltyPerWrong;
  final List<SubjectBreakdownItem> subjectBreakdown;
  final List<String> instructions;
  final String examType;
  final int year;
  final String subject;
  final String board;
  final String sourceType;
  final bool isOfficial;
  final String? officialSource;

  PastPaperDetail({
    required this.id,
    required this.title,
    required this.totalQuestions,
    required this.quizMinutes,
    required this.totalMarks,
    required this.marksPerCorrect,
    required this.marksPenaltyPerWrong,
    required this.subjectBreakdown,
    required this.instructions,
    required this.examType,
    required this.year,
    required this.subject,
    required this.board,
    required this.sourceType,
    required this.isOfficial,
    this.officialSource,
  });

  factory PastPaperDetail.fromJson(Map<String, dynamic> json) {
    return PastPaperDetail(
      id: json['id'],
      title: json['title'],
      totalQuestions: json['total_questions'],
      quizMinutes: json['quiz_minutes'],
      totalMarks: json['total_marks'],
      marksPerCorrect: (json['marks_per_correct'] as num).toDouble(),
      marksPenaltyPerWrong: (json['marks_penalty_per_wrong'] as num).toDouble(),
      subjectBreakdown: (json['subject_breakdown'] as List)
          .map((e) => SubjectBreakdownItem.fromJson(e))
          .toList(),
      instructions: List<String>.from(json['instructions']),
      examType: json['exam_type'] ?? 'Exam',
      year: (json['year'] as num?)?.toInt() ?? 0,
      subject: json['subject'] ?? 'All Subjects',
      board: json['board'] ?? '',
      sourceType: json['source_type'] ?? 'practice',
      isOfficial: json['is_official'] == true,
      officialSource: json['official_source'],
    );
  }
}

class MCQItem {
  final String question;
  final List<String> options;
  final String? subject;
  final String? topic;
  final String? section;

  MCQItem({
    required this.question,
    required this.options,
    this.subject,
    this.topic,
    this.section,
  });

  factory MCQItem.fromJson(Map<String, dynamic> json) {
    return MCQItem(
      question: json['question'],
      options: List<String>.from(json['options']),
      subject: json['subject'],
      topic: json['topic'],
      section: json['section'],
    );
  }
}

class QuizSet {
  final int id;
  final String subject;
  final String difficulty;
  final int quizMinutes;
  final String examType;
  final String mode;
  final double negativeMarking;
  final String? formatVersion;
  final List<Map<String, dynamic>> sectionConfig;
  final List<MCQItem> questions;

  QuizSet({
    required this.id,
    required this.subject,
    required this.difficulty,
    required this.quizMinutes,
    required this.questions,
    this.examType = 'MDCAT',
    this.mode = 'topic',
    this.negativeMarking = 0,
    this.formatVersion,
    this.sectionConfig = const [],
  });

  factory QuizSet.fromJson(Map<String, dynamic> json) {
    return QuizSet(
      id: json['id'],
      subject: json['subject'],
      difficulty: json['difficulty'],
      quizMinutes: json['quiz_minutes'],
      examType: json['exam_type'] ?? 'MDCAT',
      mode: json['mode'] ?? 'topic',
      negativeMarking: (json['negative_marking'] as num?)?.toDouble() ?? 0,
      formatVersion: json['format_version'],
      sectionConfig: (json['section_config'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      questions: (json['questions'] as List)
          .map((q) => MCQItem.fromJson(q))
          .toList(),
    );
  }
}

class QuizSetSummary {
  final int id;
  final String subject;
  final String difficulty;
  final int questionCount;
  final DateTime createdAt;

  QuizSetSummary({
    required this.id,
    required this.subject,
    required this.difficulty,
    required this.questionCount,
    required this.createdAt,
  });

  factory QuizSetSummary.fromJson(Map<String, dynamic> json) {
    return QuizSetSummary(
      id: json['id'],
      subject: json['subject'],
      difficulty: json['difficulty'],
      questionCount: json['question_count'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AttemptResult {
  final int id;
  final int quizSetId;
  final int correct;
  final int wrong;
  final int total;
  final double percentage;
  final String grade;
  final double score;
  final double maxScore;
  final double negativeMarking;
  final int totalTimeSeconds;
  final DateTime? finishedAt;
  final List<QuestionReview> review;

  AttemptResult({
    required this.id,
    required this.quizSetId,
    required this.correct,
    required this.wrong,
    required this.total,
    required this.percentage,
    required this.grade,
    this.score = 0,
    this.maxScore = 0,
    this.negativeMarking = 0,
    this.totalTimeSeconds = 0,
    this.finishedAt,
    this.review = const [],
  });

  factory AttemptResult.fromJson(Map<String, dynamic> json) {
    return AttemptResult(
      id: json['id'],
      quizSetId: json['quiz_set_id'],
      correct: json['correct'],
      wrong: json['wrong'],
      total: json['total'],
      percentage: (json['percentage'] as num).toDouble(),
      grade: json['grade'],
      score: (json['score'] as num?)?.toDouble() ?? 0,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 0,
      negativeMarking: (json['negative_marking'] as num?)?.toDouble() ?? 0,
      totalTimeSeconds: (json['total_time_seconds'] as num?)?.toInt() ?? 0,
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'])
          : null,
      review: (json['review'] as List? ?? [])
          .map((item) => QuestionReview.fromJson(item))
          .toList(),
    );
  }
}

class QuestionReview {
  final int index;
  final String question;
  final List<String> options;
  final String? selectedOption;
  final String correctOption;
  final String correctAnswer;
  final bool isCorrect;
  final String? explanation;
  final Map<String, String> optionExplanations;
  final String? subject;
  final String? topic;
  final String? concept;
  final int timeSpentSeconds;

  QuestionReview({
    required this.index,
    required this.question,
    required this.options,
    required this.selectedOption,
    required this.correctOption,
    required this.correctAnswer,
    required this.isCorrect,
    this.explanation,
    this.optionExplanations = const {},
    this.subject,
    this.topic,
    this.concept,
    this.timeSpentSeconds = 0,
  });

  factory QuestionReview.fromJson(Map<String, dynamic> json) {
    return QuestionReview(
      index: json['index'],
      question: json['question'],
      options: List<String>.from(json['options']),
      selectedOption: json['selected_option'],
      correctOption: json['correct_option'],
      correctAnswer: json['correct_answer'],
      isCorrect: json['is_correct'],
      explanation: json['explanation'],
      optionExplanations: Map<String, String>.from(
        json['option_explanations'] as Map? ?? const {},
      ),
      subject: json['subject'],
      topic: json['topic'],
      concept: json['concept'],
      timeSpentSeconds: (json['time_spent_seconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProgressPoint {
  final int attemptId;
  final int quizSetId;
  final String subject;
  final String difficulty;
  final String examType;
  final int totalTimeSeconds;
  final double percentage;
  final String grade;
  final DateTime? finishedAt;

  ProgressPoint({
    required this.attemptId,
    required this.quizSetId,
    required this.subject,
    required this.difficulty,
    this.examType = 'MDCAT',
    this.totalTimeSeconds = 0,
    required this.percentage,
    required this.grade,
    this.finishedAt,
  });

  factory ProgressPoint.fromJson(Map<String, dynamic> json) {
    return ProgressPoint(
      attemptId: json['attempt_id'],
      quizSetId: json['quiz_set_id'],
      subject: json['subject'],
      difficulty: json['difficulty'],
      examType: json['exam_type'] ?? 'MDCAT',
      totalTimeSeconds: (json['total_time_seconds'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num).toDouble(),
      grade: json['grade'],
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'])
          : null,
    );
  }
}

class PerformanceMetric {
  final String name;
  final String? subject;
  final double accuracy;
  final int correct;
  final int questions;
  final double averageTimeSeconds;

  const PerformanceMetric({
    required this.name,
    required this.accuracy,
    required this.correct,
    required this.questions,
    required this.averageTimeSeconds,
    this.subject,
  });

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) =>
      PerformanceMetric(
        name: json['name']?.toString() ?? '',
        subject: json['subject']?.toString(),
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        correct: (json['correct'] as num?)?.toInt() ?? 0,
        questions: (json['questions'] as num?)?.toInt() ?? 0,
        averageTimeSeconds:
            (json['average_time_seconds'] as num?)?.toDouble() ?? 0,
      );
}

class WeeklyPerformance {
  final DateTime weekStart;
  final double averageScore;
  final int tests;

  const WeeklyPerformance({
    required this.weekStart,
    required this.averageScore,
    required this.tests,
  });

  factory WeeklyPerformance.fromJson(Map<String, dynamic> json) =>
      WeeklyPerformance(
        weekStart: DateTime.parse(json['week_start']),
        averageScore: (json['average_score'] as num?)?.toDouble() ?? 0,
        tests: (json['tests'] as num?)?.toInt() ?? 0,
      );
}

class AdvancedAnalytics {
  final List<PerformanceMetric> subjectScores;
  final List<PerformanceMetric> topicScores;
  final List<PerformanceMetric> strongestTopics;
  final List<PerformanceMetric> weakestTopics;
  final List<WeeklyPerformance> weeklyImprovement;
  final int testsCompleted;
  final double averageScore;
  final double bestScore;
  final int totalTimeSeconds;
  final double? latestScore;
  final double? previousScore;
  final double? change;

  const AdvancedAnalytics({
    required this.subjectScores,
    required this.topicScores,
    required this.strongestTopics,
    required this.weakestTopics,
    required this.weeklyImprovement,
    required this.testsCompleted,
    required this.averageScore,
    required this.bestScore,
    required this.totalTimeSeconds,
    this.latestScore,
    this.previousScore,
    this.change,
  });

  factory AdvancedAnalytics.fromJson(Map<String, dynamic> json) {
    List<PerformanceMetric> metrics(String key) =>
        (json[key] as List? ?? const [])
            .map(
              (item) =>
                  PerformanceMetric.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
    final summary = Map<String, dynamic>.from(json['summary'] ?? const {});
    final comparison = Map<String, dynamic>.from(
      json['latest_comparison'] ?? const {},
    );
    return AdvancedAnalytics(
      subjectScores: metrics('subject_scores'),
      topicScores: metrics('topic_scores'),
      strongestTopics: metrics('strongest_topics'),
      weakestTopics: metrics('weakest_topics'),
      weeklyImprovement: (json['weekly_improvement'] as List? ?? const [])
          .map(
            (item) =>
                WeeklyPerformance.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      testsCompleted: (summary['tests_completed'] as num?)?.toInt() ?? 0,
      averageScore: (summary['average_score'] as num?)?.toDouble() ?? 0,
      bestScore: (summary['best_score'] as num?)?.toDouble() ?? 0,
      totalTimeSeconds: (summary['total_time_seconds'] as num?)?.toInt() ?? 0,
      latestScore: (comparison['latest_score'] as num?)?.toDouble(),
      previousScore: (comparison['previous_score'] as num?)?.toDouble(),
      change: (comparison['change'] as num?)?.toDouble(),
    );
  }
}

class UploadResult {
  final String filename;
  final int words;
  final int characters;
  final int lines;
  final String cleanedText;

  UploadResult({
    required this.filename,
    required this.words,
    required this.characters,
    required this.lines,
    required this.cleanedText,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      filename: json['filename'],
      words: json['stats']['words'],
      characters: json['stats']['characters'],
      lines: json['stats']['lines'],
      cleanedText: json['cleaned_text'],
    );
  }
}
