const Map<String, List<String>> examSubjects = {
  "MDCAT": ["Biology", "Chemistry", "Physics", "English", "Logical Reasoning"],
  "ECAT": ["Mathematics", "Physics", "Chemistry", "English"],
  "NUST NET": ["Mathematics", "Physics", "Chemistry", "English", "Intelligence"],
  "NTS": ["Quantitative", "Analytical", "Verbal", "Subject Knowledge"],
  "CSS": ["English Essay", "Precis and Composition", "General Science", "Current Affairs", "Pakistan Affairs", "Islamic Studies"],
  "LAT": ["English", "General Knowledge", "Pakistan Studies", "Islamic Studies", "Mathematics", "Urdu"],
  "IELTS": ["Listening", "Reading", "Writing", "Speaking"],
  "PMS": ["English", "General Knowledge", "Pakistan Affairs", "Current Affairs", "Optional Subjects"],
  "SAT": ["Reading and Writing", "Mathematics"],
  "General Knowledge": ["Pakistan", "World", "Science", "Current Affairs"],
};

String examSubjectSummary(String exam) {
  final subjects = examSubjects[exam] ?? const ["All subjects"];
  return subjects.join(", ");
}

String mockTestDescription(String exam) {
  if (exam == "MDCAT") {
    return "Mixes ${examSubjectSummary(exam)} according to the $exam subject weighting — no material upload needed.";
  }
  if (exam == "IELTS") {
    return "Covers IELTS Listening, Reading, Writing, and Speaking skills using IELTS-focused practice questions — no material upload needed.";
  }
  return "Covers ${examSubjectSummary(exam)} for a complete $exam practice test — no material upload needed.";
}
