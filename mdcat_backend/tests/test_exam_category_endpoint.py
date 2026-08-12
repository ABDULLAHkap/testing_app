from app.exam_catalog import ensure_exam


def test_exam_catalog_accepts_supported_category():
    assert ensure_exam("ECAT") == "ECAT"


def test_exam_catalog_accepts_general_knowledge():
    assert ensure_exam("General Knowledge") == "General Knowledge"
