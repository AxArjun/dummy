with open("verification_output.txt", "rb") as f:
    text = f.read().decode("utf-16le")
with open("safe_output.txt", "w", encoding="utf-8") as f:
    f.write(text)
