class UserModel {
  final int id;
  final String username;
  final String email;
  final DateTime? examDate;
  final String? gender;
  final String? phone;
  final String targetExam;
  final bool emailVerified;
  final bool phoneVerified;
  final String verificationMethod;
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
    this.phoneVerified = false,
    this.verificationMethod = 'email',
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
      phoneVerified: json['phone_verified'] ?? false,
      verificationMethod: json['verification_method'] ?? 'email',
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

class PastPaperSummary {
  final String id;
  final String title;
  final int totalQuestions;
  final int quizMinutes;

  PastPaperSummary({
    required this.id,
    required this.title,
    required this.totalQuestions,
    required this.quizMinutes,
  });

  factory PastPaperSummary.fromJson(Map<String, dynamic> json) {
    return PastPaperSummary(
      id: json['id'],
      title: json['title'],
      totalQuestions: json['total_questions'],
      quizMinutes: json['quiz_minutes'],
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
    );
  }
}

class MCQItem {
  final String question;
  final List<String> options;

  MCQItem({
    required this.question,
    required this.options,
  });

  factory MCQItem.fromJson(Map<String, dynamic> json) {
    return MCQItem(
      question: json['question'],
      options: List<String>.from(json['options']),
    );
  }
}

class QuizSet {
  final int id;
  final String subject;
  final String difficulty;
  final int quizMinutes;
  final List<MCQItem> questions;

  QuizSet({
    required this.id,
    required this.subject,
    required this.difficulty,
    required this.quizMinutes,
    required this.questions,
  });

  factory QuizSet.fromJson(Map<String, dynamic> json) {
    return QuizSet(
      id: json['id'],
      subject: json['subject'],
      difficulty: json['difficulty'],
      quizMinutes: json['quiz_minutes'],
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

  QuestionReview({
    required this.index,
    required this.question,
    required this.options,
    required this.selectedOption,
    required this.correctOption,
    required this.correctAnswer,
    required this.isCorrect,
    this.explanation,
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
    );
  }
}

class ProgressPoint {
  final int attemptId;
  final int quizSetId;
  final String subject;
  final String difficulty;
  final double percentage;
  final String grade;
  final DateTime? finishedAt;

  ProgressPoint({
    required this.attemptId,
    required this.quizSetId,
    required this.subject,
    required this.difficulty,
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
      percentage: (json['percentage'] as num).toDouble(),
      grade: json['grade'],
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'])
          : null,
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
