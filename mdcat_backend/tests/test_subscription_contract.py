from app.exam_catalog import EXAM_CATALOG


def test_subscription_categories_are_real_exam_categories():
    assert "MDCAT" in EXAM_CATALOG
    assert "ECAT" in EXAM_CATALOG
    assert "IELTS" in EXAM_CATALOG
