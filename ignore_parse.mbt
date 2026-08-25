///|
fn parse_rule(line0 : String) -> IgnoreRule? {
  let line1 = trim_bom(line0)
  let line = normalize_trailing_spaces(line1)

  if line.trim(char_set=" \t").is_empty() {
    return None
  }
  if has_odd_trailing_backslash(line) {
    return None
  }
  if line.has_prefix("#") {
    return None
  }

  let mut pattern = if line.has_prefix("\\#") {
    line[1:].to_owned()
  } else {
    line
  }

  let mut negative = false
  if pattern.has_prefix("\\!") {
    pattern = pattern[1:].to_owned()
  } else if pattern.has_prefix("!") {
    negative = true
    pattern = pattern[1:].to_owned()
  }

  if pattern.is_empty() {
    return None
  }

  let mut anchored = false
  if pattern.has_prefix("/") {
    anchored = true
    pattern = pattern[1:].to_owned()
  }

  let mut directory_only = false
  if ends_with_slash(pattern) {
    directory_only = true
    pattern = pattern[:pattern.length() - 1].to_owned()
  }

  let has_slash = pattern.find("/") is Some(_)
  let segments = path_to_segments(pattern)
  if segments.is_empty() {
    return None
  }

  Some({
    raw: line,
    pattern,
    negative,
    directory_only,
    anchored,
    has_slash,
    segments,
  })
}

///|
fn split_lines(text : String) -> Array[String] {
  let lines = []
  let buf = StringBuilder(size_hint=text.length())

  for i in 0..<text.length() {
    let ch = text.code_unit_at(i)
    if ch == '\n'.to_int().to_uint16() {
      lines.push(buf.to_string())
      buf.reset()
    } else if ch == '\r'.to_int().to_uint16() {
      ()
    } else {
      buf.write_char(UInt16::unsafe_to_char(ch))
    }
  }

  lines.push(buf.to_string())
  lines
}

///|
fn trim_bom(line : String) -> String {
  if line.is_empty() {
    return line
  }
  if line.code_unit_at(0) == 0xFEFF {
    return line[1:].to_owned()
  }
  line
}

///|
fn normalize_trailing_spaces(line : String) -> String {
  if line.is_empty() {
    return line
  }

  let mut end_ = line.length()
  while end_ > 0 && line.code_unit_at(end_ - 1) == ' '.to_int().to_uint16() {
    end_ = end_ - 1
  }
  if end_ == line.length() {
    return line
  }
  if end_ == 0 {
    return ""
  }

  let mut slash_count = 0
  let mut idx = end_ - 1
  while true {
    if line.code_unit_at(idx) == '\\'.to_int().to_uint16() {
      slash_count = slash_count + 1
      if idx == 0 {
        break
      }
      idx = idx - 1
      continue
    }
    break
  }

  if slash_count % 2 == 1 {
    "\{line[:end_ - 1]} "
  } else {
    line[:end_].to_owned()
  }
}

///|
fn has_odd_trailing_backslash(line : String) -> Bool {
  if line.is_empty() {
    return false
  }
  if line.code_unit_at(line.length() - 1) != '\\'.to_int().to_uint16() {
    return false
  }

  let mut i = line.length() - 1
  let mut count = 0
  while true {
    if line.code_unit_at(i) == '\\'.to_int().to_uint16() {
      count = count + 1
      if i == 0 {
        break
      }
      i = i - 1
      continue
    }
    break
  }
  count % 2 == 1
}
