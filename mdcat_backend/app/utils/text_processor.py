"""
Text Processing Module
MDCAT AI Preparation System
"""


def clean_text(text: str) -> str:
    """Remove extra spaces, tabs, and blank lines."""
    text = text.replace("\t", " ")
    text = text.replace("\r", "")

    cleaned_lines = []
    for line in text.split("\n"):
        line = line.strip()
        if line:
            cleaned_lines.append(line)

    return "\n".join(cleaned_lines)


def split_into_chunks(text: str, chunk_size: int = 500) -> list[str]:
    """Split text into chunks of approximately chunk_size words."""
    words = text.split()
    chunks = []
    for i in range(0, len(words), chunk_size):
        chunk = " ".join(words[i:i + chunk_size])
        chunks.append(chunk)
    return chunks


def get_text_statistics(text: str) -> dict:
    """Return basic statistics of the extracted text."""
    return {
        "words": len(text.split()),
        "characters": len(text),
        "lines": len(text.splitlines()),
    }
