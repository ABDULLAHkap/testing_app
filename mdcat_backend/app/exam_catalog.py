EXAM_CATALOG = {
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
}


def ensure_exam(exam_type: str) -> str:
    cleaned = exam_type.strip()
    if cleaned not in EXAM_CATALOG:
        raise ValueError("Unsupported exam category")
    return cleaned
