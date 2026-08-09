import os
import tempfile

from fpdf import FPDF


def create_result_pdf(
    result: dict, subject: str, difficulty: str, exam_type: str
) -> str:
    """Build a simple result PDF and return the file path."""
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", size=14)

    pdf.cell(200, 10, f"{exam_type} Practice Result", ln=True)
    pdf.set_font("Arial", size=12)
    pdf.cell(200, 10, f"Subject: {subject}  |  Difficulty: {difficulty}", ln=True)
    pdf.ln(4)

    pdf.cell(200, 10, f"Total Questions: {result['total']}", ln=True)
    pdf.cell(200, 10, f"Correct Answers: {result['correct']}", ln=True)
    pdf.cell(200, 10, f"Wrong Answers: {result['wrong']}", ln=True)
    pdf.cell(200, 10, f"Percentage: {result['percentage']:.2f}%", ln=True)
    pdf.cell(200, 10, f"Grade: {result['grade']}", ln=True)

    descriptor, path = tempfile.mkstemp(suffix=".pdf")
    os.close(descriptor)
    pdf.output(path)
    return path


def _latin(value: object) -> str:
    return str(value).encode("latin-1", "replace").decode("latin-1")


def _paragraph(pdf: FPDF, height: float, text: object) -> None:
    """Write a full-width paragraph and reset the cursor for fpdf2.

    Newer fpdf2 releases leave the cursor at the right edge after
    ``multi_cell`` by default.  A following full-width cell then has no room
    and raises ``Not enough horizontal space to render a single character``.
    """
    pdf.set_x(pdf.l_margin)
    pdf.multi_cell(0, height, _latin(text), new_x="LMARGIN", new_y="NEXT")


def create_practice_paper_pdf(
    *,
    title: str,
    exam_type: str,
    minutes: int,
    questions: list[dict],
    negative_marking: float,
) -> str:
    """Build an original printable paper plus an answer/explanation key."""
    pdf = FPDF()
    pdf.set_auto_page_break(auto=True, margin=14)
    pdf.add_page()
    pdf.set_font("Arial", "B", 16)
    _paragraph(pdf, 9, title)
    pdf.set_font("Arial", size=10)
    _paragraph(
        pdf,
        6,
            f"{exam_type} original practice paper | {len(questions)} questions | "
            f"{minutes} minutes | Negative marking: {negative_marking:g}",
    )
    pdf.set_font("Arial", "I", 9)
    _paragraph(
        pdf,
        5,
            "Compact offline pack: representative original questions following "
            "the listed exam pattern. It is not a reproduction of an official paper.",
    )
    pdf.ln(3)

    for index, question in enumerate(questions, 1):
        pdf.set_font("Arial", "B", 10)
        _paragraph(pdf, 6, f"{index}. {question['question']}")
        pdf.set_font("Arial", size=9)
        for option in question.get("options", []):
            _paragraph(pdf, 5, f"   {option}")
        pdf.ln(2)

    pdf.add_page()
    pdf.set_font("Arial", "B", 15)
    pdf.cell(0, 9, "Answer and explanation key", ln=True)
    for index, question in enumerate(questions, 1):
        correct = question.get("correct_option", "")
        explanation = question.get("explanation") or ""
        concept = question.get("concept") or question.get("topic") or ""
        pdf.set_font("Arial", "B", 10)
        _paragraph(pdf, 6, f"{index}. Correct answer: {correct}")
        pdf.set_font("Arial", size=9)
        if explanation:
            _paragraph(pdf, 5, explanation)
        if concept:
            _paragraph(pdf, 5, f"Revise: {concept}")
        pdf.ln(2)

    descriptor, path = tempfile.mkstemp(suffix=".pdf")
    os.close(descriptor)
    pdf.output(path)
    return path
