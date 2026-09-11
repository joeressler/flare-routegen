"""Small string helpers for scanner code paths."""


def text_len(text: String) -> Int:
    return text.byte_length()


def text_slice(text: String, start: Int, end: Int) -> String:
    return String(text[byte=start:end])


def text_drop_prefix(text: String, count: Int) -> String:
    return text_slice(text, count, text_len(text))


def text_char_at(text: String, index: Int) -> String:
    return String(text[byte = index : index + 1])


def remove_extension(path: String) -> String:
    if path.endswith(".mojo"):
        return String(path.removesuffix(".mojo"))
    if path.endswith(".🔥"):
        return String(path.removesuffix(".🔥"))
    return path
