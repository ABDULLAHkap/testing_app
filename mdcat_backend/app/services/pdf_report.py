import tempfile

from fpdf import FPDF


def create_result_pdf(result: dict, subject: str, difficulty: str) -> str:
    """Build a simple result PDF and return the file path."""
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", size=14)

    pdf.cell(200, 10, "MDCAT AI Quiz Result", ln=True)
    pdf.set_font("Arial", size=12)
    pdf.cell(200, 10, f"Subject: {subject}  |  Difficulty: {difficulty}", ln=True)
    pdf.ln(4)

    pdf.cell(200, 10, f"Total Questions: {result['total']}", ln=True)
    pdf.cell(200, 10, f"Correct Answers: {result['correct']}", ln=True)
    pdf.cell(200, 10, f"Wrong Answers: {result['wrong']}", ln=True)
    pdf.cell(200, 10, f"Percentage: {result['percentage']:.2f}%", ln=True)
    pdf.cell(200, 10, f"Grade: {result['grade']}", ln=True)

    path = tempfile.mktemp(suffix=".pdf")
    pdf.output(path)
    return path
