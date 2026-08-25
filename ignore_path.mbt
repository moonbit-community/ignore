///|
fn normalize_path(pathname : String) -> String {
  let buf = StringBuilder(size_hint=pathname.length())
  for i in 0..<pathname.length() {
    let ch = pathname.code_unit_at(i)
    if ch == '\\'.to_int().to_uint16() {
      buf.write_char('/')
    } else {
      buf.write_char(UInt16::unsafe_to_char(ch))
    }
  }
  buf.to_string()
}

///|
fn path_to_segments(pathname : String) -> Array[String] {
  let segments = []
  if pathname.is_empty() {
    return segments
  }

  let text = if ends_with_slash(pathname) {
    pathname[:pathname.length() - 1].to_owned()
  } else {
    pathname
  }

  if text.is_empty() {
    return segments
  }

  let mut start = 0
  for i in 0..<text.length() {
    if text.code_unit_at(i) == '/'.to_int().to_uint16() {
      if i > start {
        segments.push(text[start:i].to_owned())
      }
      start = i + 1
    }
  }
  if start < text.length() {
    segments.push(text[start:].to_owned())
  }
  segments
}

///|
fn join_segments(segments : Array[String], start : Int, end_ : Int) -> String {
  if start >= end_ {
    return ""
  }

  let buf = StringBuilder(size_hint=0)
  for i in start..<end_ {
    if i > start {
      buf.write_char('/')
    }
    buf.write_string(segments[i])
  }
  buf.to_string()
}

///|
fn ends_with_slash(text : String) -> Bool {
  !text.is_empty() &&
  text.code_unit_at(text.length() - 1) == '/'.to_int().to_uint16()
}

///|
fn is_windows_abs(pathname : String) -> Bool {
  pathname =~ re"^[a-zA-Z]:[\\/]"
}
