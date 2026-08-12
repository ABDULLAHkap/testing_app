from app.exam_catalog import ensure_exam


def test_selected_exam_values_are_canonical():
    for exam in ("MDCAT", "ECAT", "NUST NET", "NTS", "CSS", "LAT", "IELTS", "PMS", "SAT"):
        assert ensure_exam(exam) == exam
