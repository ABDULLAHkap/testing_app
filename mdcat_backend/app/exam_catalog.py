EXAM_CATALOG = {
    "MDCAT": ["Biology", "Chemistry", "Physics", "English", "Logical Reasoning"],
    "ECAT": ["Mathematics", "Physics", "Chemistry", "English"],
    "NUST NET": ["Mathematics", "Physics", "English"],
    "NTS": ["English", "Analytical", "Quantitative", "Subject Knowledge"],
    "CSS": ["English", "General Abilities", "General Knowledge", "Islamic Studies", "Urdu"],
    "LAT": ["English", "General Knowledge", "Pakistan Studies", "Islamic Studies", "Mathematics", "Urdu"],
    "IELTS": ["Listening", "Reading", "Writing", "Speaking"],
    "PMS": ["English", "General Knowledge", "Pakistan Affairs", "Current Affairs", "Optional Subjects"],
    "SAT": ["Reading and Writing", "Mathematics"],
    "General Knowledge": ["Pakistan", "World", "Science", "Current Affairs"],
}


# Data-driven test structures. Volatile rules remain linked to the official
# authority so an administrator can verify them before a new admission cycle.
# `mock_breakdown` contains only objectively gradable sections; writing and
# speaking sections are practised separately in the Flutter app with the tutor.
EXAM_FORMATS: dict[str, dict] = {
    "MDCAT": {
        "title": "PM&DC MDCAT 2026",
        "version": "2026",
        "duration_minutes": 180,
        "total_questions": 180,
        "negative_marking": 0.0,
        "delivery": "Paper-based MCQs in English",
        "supports_full_mcq_mock": True,
        "official_source": (
            "https://pmdc.pk/Documents/Others/Public%20Notice%20Regarding%20"
            "Opening%20of%20Online%20Registration%20Portal%20for%20MDCAT-2026.pdf"
        ),
        "sections": [
            {"name": "Biology", "kind": "mcq", "questions": 81, "minutes": None},
            {"name": "Chemistry", "kind": "mcq", "questions": 45, "minutes": None},
            {"name": "Physics", "kind": "mcq", "questions": 36, "minutes": None},
            {"name": "English", "kind": "mcq", "questions": 9, "minutes": None},
            {"name": "Logical Reasoning", "kind": "mcq", "questions": 9, "minutes": None},
        ],
        "mock_breakdown": {
            "Biology": 81,
            "Chemistry": 45,
            "Physics": 36,
            "English": 9,
            "Logical Reasoning": 9,
        },
        "notes": ["No negative marking", "Difficulty mix: 15% easy, 70% moderate, 15% difficult"],
    },
    "ECAT": {
        "title": "UET ECAT 2026",
        "version": "2026",
        "duration_minutes": 100,
        "total_questions": 100,
        "negative_marking": 0.0,
        "delivery": "Computer-based MCQs",
        "supports_full_mcq_mock": True,
        "official_source": "https://ecat.uet.edu.pk/General/Ecat",
        "sections": [
            {"name": "English", "kind": "mcq", "questions": 10, "minutes": None},
            {"name": "Mathematics", "kind": "mcq", "questions": 30, "minutes": None},
            {"name": "Physics", "kind": "mcq", "questions": 30, "minutes": None},
            {"name": "Chemistry", "kind": "mcq", "questions": 30, "minutes": None},
        ],
        "mock_breakdown": {"English": 10, "Mathematics": 30, "Physics": 30, "Chemistry": 30},
        "notes": ["No negative marking in ECAT 2026", "The third science subject varies by candidate combination"],
    },
    "NUST NET": {
        "title": "NUST NET Engineering/Computing",
        "version": "2026",
        "duration_minutes": 180,
        "total_questions": 200,
        "negative_marking": 0.0,
        "delivery": "Computer- or paper-based MCQs",
        "supports_full_mcq_mock": True,
        "official_source": "https://nust.edu.pk/admissions/undergraduates/subjects-included-in-net-with-weightings/",
        "sections": [
            {"name": "Mathematics", "kind": "mcq", "questions": 100, "minutes": None},
            {"name": "Physics", "kind": "mcq", "questions": 60, "minutes": None},
            {"name": "English", "kind": "mcq", "questions": 40, "minutes": None},
        ],
        "mock_breakdown": {"Mathematics": 100, "Physics": 60, "English": 40},
        "notes": ["This profile is for Engineering and Computing programmes", "Other NUST programmes use different weightings"],
    },
    "NTS": {
        "title": "NTS NAT-ICS practice profile",
        "version": "2026",
        "duration_minutes": 120,
        "total_questions": 90,
        "negative_marking": 0.0,
        "delivery": "Paper-based MCQs",
        "supports_full_mcq_mock": True,
        "official_source": "https://nts.org.pk/products/ntsnat/nat-paper-pattern.php",
        "sections": [
            {"name": "English", "kind": "mcq", "questions": 20, "minutes": None},
            {"name": "Analytical", "kind": "mcq", "questions": 20, "minutes": None},
            {"name": "Quantitative", "kind": "mcq", "questions": 20, "minutes": None},
            {"name": "Subject Knowledge", "kind": "mcq", "questions": 30, "minutes": None},
        ],
        "mock_breakdown": {"English": 20, "Analytical": 20, "Quantitative": 20, "Subject Knowledge": 30},
        "notes": ["NTS NAT content changes by education group; this is the ICS/general app profile"],
    },
    "CSS": {
        "title": "FPSC CSS MPT and Written Examination",
        "version": "2027 syllabus",
        "duration_minutes": 200,
        "total_questions": 200,
        "negative_marking": 0.0,
        "delivery": "MPT MCQs followed by descriptive written papers",
        "supports_full_mcq_mock": True,
        "official_source": "https://www.fpsc.gov.pk/uploads/content/1785754052817_MPT_Rules.pdf",
        "sections": [
            {"name": "MPT Objective Paper", "kind": "mcq", "questions": 200, "minutes": 200},
            {"name": "Compulsory Written Papers", "kind": "writing", "questions": None, "minutes": 1080},
            {"name": "Optional Written Papers", "kind": "writing", "questions": None, "minutes": 1080},
        ],
        "mock_breakdown": {
            "English": 50,
            "General Abilities": 60,
            "General Knowledge": 50,
            "Islamic Studies": 20,
            "Urdu": 20,
        },
        "notes": ["The app mock simulates the MPT objective stage", "Use section practice for descriptive papers"],
    },
    "LAT": {
        "title": "HEC Law Admission Test",
        "version": "2026",
        "duration_minutes": 140,
        "total_questions": 75,
        "negative_marking": 0.0,
        "delivery": "75 MCQs plus essay and personal statement",
        "supports_full_mcq_mock": True,
        "official_source": "https://www.hec.gov.pk/english/services/students/etc/PublishingImages/LAT%20Final-1.pdf",
        "sections": [
            {"name": "English", "kind": "mcq", "questions": 20, "minutes": None},
            {"name": "General Knowledge", "kind": "mcq", "questions": 20, "minutes": None},
            {"name": "Pakistan Studies", "kind": "mcq", "questions": 10, "minutes": None},
            {"name": "Islamic Studies", "kind": "mcq", "questions": 10, "minutes": None},
            {"name": "Mathematics", "kind": "mcq", "questions": 5, "minutes": None},
            {"name": "Urdu", "kind": "mcq", "questions": 10, "minutes": None},
            {"name": "Written Response", "kind": "writing", "questions": 2, "minutes": 40},
        ],
        "mock_breakdown": {"English": 20, "General Knowledge": 20, "Pakistan Studies": 10, "Islamic Studies": 10, "Mathematics": 5, "Urdu": 10},
        "notes": ["The objective section allows 100 minutes", "The essay and personal statement share a separate 40-minute written section"],
    },
    "IELTS": {
        "title": "IELTS Academic",
        "version": "Current official format",
        "duration_minutes": 165,
        "total_questions": 80,
        "negative_marking": 0.0,
        "delivery": "Listening, Reading, Writing and Speaking",
        "supports_full_mcq_mock": False,
        "official_source": "https://ielts.org/take-a-test/test-types/ielts-academic-test",
        "sections": [
            {"name": "Listening", "kind": "listening", "questions": 40, "minutes": 30},
            {"name": "Reading", "kind": "reading", "questions": 40, "minutes": 60},
            {"name": "Writing", "kind": "writing", "questions": 2, "minutes": 60},
            {"name": "Speaking", "kind": "speaking", "questions": 3, "minutes": 14},
        ],
        "mock_breakdown": {"Listening": 40, "Reading": 40},
        "notes": ["Writing contains two tasks", "Speaking contains three parts", "Listening and Reading scores convert to band scores"],
    },
    "PMS": {
        "title": "Punjab PMS Written Examination",
        "version": "Current PPSC syllabus",
        "duration_minutes": 180,
        "total_questions": 100,
        "negative_marking": 0.0,
        "delivery": "Descriptive compulsory and optional papers",
        "supports_full_mcq_mock": False,
        "official_source": "https://www.ppsc.gop.pk/Downloads.aspx",
        "sections": [
            {"name": "English Essay", "kind": "writing", "questions": None, "minutes": 180},
            {"name": "English Precis", "kind": "writing", "questions": None, "minutes": 180},
            {"name": "General Knowledge", "kind": "mcq", "questions": 100, "minutes": 180},
            {"name": "Pakistan Studies", "kind": "writing", "questions": None, "minutes": 180},
            {"name": "Islamic Studies", "kind": "writing", "questions": None, "minutes": 180},
            {"name": "Optional Subjects", "kind": "writing", "questions": None, "minutes": 540},
        ],
        "mock_breakdown": {"General Knowledge": 100},
        "notes": ["Paper combinations and syllabi should be checked against the latest PPSC notice"],
    },
    "SAT": {
        "title": "Digital SAT",
        "version": "Current digital format",
        "duration_minutes": 134,
        "total_questions": 98,
        "negative_marking": 0.0,
        "delivery": "Two-stage adaptive digital test",
        "supports_full_mcq_mock": False,
        "official_source": "https://satsuite.collegeboard.org/sat/whats-on-the-test/structure",
        "sections": [
            {"name": "Reading and Writing", "kind": "mcq", "questions": 54, "minutes": 64},
            {"name": "Mathematics", "kind": "mcq", "questions": 44, "minutes": 70},
        ],
        "mock_breakdown": {"Reading and Writing": 54, "Mathematics": 44},
        "notes": [
            "Each section has two modules",
            "The real second module adapts to first-module performance",
            "Some Math questions require a typed response, so the app does not label a fixed MCQ set as a full official simulation",
        ],
    },
    "General Knowledge": {
        "title": "General Knowledge Practice",
        "version": "App practice format",
        "duration_minutes": 120,
        "total_questions": 100,
        "negative_marking": 0.0,
        "delivery": "Practice MCQs",
        "supports_full_mcq_mock": True,
        "official_source": None,
        "sections": [
            {"name": "Pakistan", "kind": "mcq", "questions": 25, "minutes": None},
            {"name": "World", "kind": "mcq", "questions": 25, "minutes": None},
            {"name": "Science", "kind": "mcq", "questions": 25, "minutes": None},
            {"name": "Current Affairs", "kind": "mcq", "questions": 25, "minutes": None},
        ],
        "mock_breakdown": {"Pakistan": 25, "World": 25, "Science": 25, "Current Affairs": 25},
        "notes": ["This is an app practice profile, not a single official examination"],
    },
}


EXAM_TOPIC_CATALOG: dict[str, dict[str, list[str]]] = {
    "ECAT": {
        "Mathematics": ["Algebra", "Trigonometry", "Calculus", "Vectors", "Analytical Geometry"],
        "Physics": ["Mechanics", "Waves", "Thermodynamics", "Electricity", "Modern Physics"],
        "Chemistry": ["Physical Chemistry", "Inorganic Chemistry", "Organic Chemistry"],
        "English": ["Vocabulary", "Grammar", "Comprehension"],
    },
    "NUST NET": {
        "Mathematics": ["Algebra", "Trigonometry", "Calculus", "Coordinate Geometry"],
        "Physics": ["Mechanics", "Waves", "Electricity", "Modern Physics"],
        "English": ["Vocabulary", "Grammar", "Comprehension"],
    },
    "NTS": {
        "English": ["Sentence Completion", "Analogy", "Antonyms", "Comprehension", "Synonyms"],
        "Analytical": ["Scenario Reasoning", "Statement Reasoning"],
        "Quantitative": ["Arithmetic", "Algebra", "Geometry"],
        "Subject Knowledge": ["Computer Science", "General Science", "Core Subject Review"],
    },
    "IELTS": {
        "Listening": ["Form Completion", "Map Labelling", "Multiple Choice", "Note Completion"],
        "Reading": ["Matching Headings", "True False Not Given", "Summary Completion", "Multiple Choice"],
        "Writing": ["Task 1 Visual Report", "Task 2 Essay"],
        "Speaking": ["Part 1 Interview", "Part 2 Long Turn", "Part 3 Discussion"],
    },
    "SAT": {
        "Reading and Writing": ["Information and Ideas", "Craft and Structure", "Expression of Ideas", "Standard English Conventions"],
        "Mathematics": ["Algebra", "Advanced Math", "Problem Solving and Data Analysis", "Geometry and Trigonometry"],
    },
}


def get_exam_format(exam_type: str) -> dict:
    return EXAM_FORMATS[ensure_exam(exam_type)]


def get_exam_topics(exam_type: str) -> dict[str, list[str]]:
    selected = ensure_exam(exam_type)
    return EXAM_TOPIC_CATALOG.get(
        selected,
        {subject: [subject] for subject in EXAM_CATALOG[selected]},
    )


def ensure_exam(exam_type: str) -> str:
    cleaned = exam_type.strip()
    if cleaned not in EXAM_CATALOG:
        raise ValueError("Unsupported exam category")
    return cleaned
