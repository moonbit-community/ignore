///|
fn match_rule(
  rule : IgnoreRule,
  path_segments : Array[String],
  is_dir : Bool,
  allow_empty_last_star : Bool,
) -> Bool {
  if !rule.has_slash {
    let target = rule.segments[0]
    if rule.anchored {
      if path_segments.is_empty() {
        return false
      }
      if !match_segment_pattern(target, path_segments[0]) {
        return false
      }
      if !rule.directory_only {
        return path_segments.length() == 1
      }
      return path_segments.length() == 1 && is_dir
    }

    for i in 0..<path_segments.length() {
      if match_segment_pattern(target, path_segments[i]) {
        if !rule.directory_only {
          if i == path_segments.length() - 1 {
            return true
          }
          continue
        }
        if i == path_segments.length() - 1 && is_dir {
          return true
        }
      }
    }
    return false
  }

  // Patterns containing '/' are matched from the current root; use '**/' to
  // opt into matching from deeper levels.
  match_segments(
    rule.segments,
    0,
    path_segments,
    0,
    false,
    allow_empty_last_star,
  )
}

///|
fn match_segments(
  pattern_segments : Array[String],
  pi : Int,
  path_segments : Array[String],
  si : Int,
  require_full : Bool,
  allow_empty_last_star : Bool,
) -> Bool {
  if pi >= pattern_segments.length() {
    return !require_full || si >= path_segments.length()
  }

  if si >= path_segments.length() {
    if allow_empty_last_star &&
      pi == pattern_segments.length() - 1 &&
      pattern_segments[pi] == "*" {
      return true
    }
    return false
  }

  let token = pattern_segments[pi]
  if token == "**" {
    if pi == pattern_segments.length() - 1 {
      // A trailing `/**` should match children, but not the directory itself.
      return si < path_segments.length()
    }
    let mut k = si
    while k <= path_segments.length() {
      if match_segments(
          pattern_segments,
          pi + 1,
          path_segments,
          k,
          require_full,
          allow_empty_last_star,
        ) {
        return true
      }
      k = k + 1
    }
    return false
  }

  if !match_segment_pattern(token, path_segments[si]) {
    return false
  }
  match_segments(
    pattern_segments,
    pi + 1,
    path_segments,
    si + 1,
    require_full,
    allow_empty_last_star,
  )
}

///|
fn match_segment_pattern(pattern : String, input : String) -> Bool {
  match_pattern_chars(pattern, 0, input, 0)
}

///|
fn match_pattern_chars(
  pattern : String,
  pi : Int,
  input : String,
  si : Int,
) -> Bool {
  if pi >= pattern.length() {
    return si >= input.length()
  }

  let pch = pattern.code_unit_at(pi)

  if pch == '\\'.to_int().to_uint16() {
    let next = pi + 1
    if next >= pattern.length() {
      if si >= input.length() {
        return false
      }
      if input.code_unit_at(si) != '\\'.to_int().to_uint16() {
        return false
      }
      return match_pattern_chars(pattern, pi + 1, input, si + 1)
    }

    if si >= input.length() {
      return false
    }
    if input.code_unit_at(si) != pattern.code_unit_at(next) {
      return false
    }
    return match_pattern_chars(pattern, next + 1, input, si + 1)
  }

  if pch == '*'.to_int().to_uint16() {
    let mut next = pi
    while next < pattern.length() &&
          pattern.code_unit_at(next) == '*'.to_int().to_uint16() {
      next = next + 1
    }
    if next >= pattern.length() {
      return true
    }

    let mut k = si
    while k <= input.length() {
      if match_pattern_chars(pattern, next, input, k) {
        return true
      }
      k = k + 1
    }
    return false
  }

  if pch == '?'.to_int().to_uint16() {
    if si >= input.length() {
      return false
    }
    return match_pattern_chars(pattern, pi + 1, input, si + 1)
  }

  if pch == '['.to_int().to_uint16() {
    if si >= input.length() {
      return false
    }

    let mut idx = pi + 1
    if idx >= pattern.length() {
      return false
    }

    let mut negate = false
    if idx < pattern.length() {
      let first = pattern.code_unit_at(idx)
      if first == '!'.to_int().to_uint16() || first == '^'.to_int().to_uint16() {
        negate = true
        idx = idx + 1
      }
    }

    let class_start = idx
    let mut close = -1
    while idx < pattern.length() {
      let ch = pattern.code_unit_at(idx)
      if ch == '\\'.to_int().to_uint16() && idx + 1 < pattern.length() {
        idx = idx + 2
        continue
      }
      if ch == ']'.to_int().to_uint16() {
        close = idx
        break
      }
      idx = idx + 1
    }

    if close == -1 {
      return false
    }
    if close == class_start {
      return false
    }

    let target = input.code_unit_at(si)
    let mut matched = false
    let mut k = class_start
    while k < close {
      let mut c1 = pattern.code_unit_at(k)
      if c1 == '\\'.to_int().to_uint16() && k + 1 < close {
        c1 = pattern.code_unit_at(k + 1)
        k = k + 2
      } else {
        k = k + 1
      }

      if k < close - 1 && pattern.code_unit_at(k) == '-'.to_int().to_uint16() {
        let c2_idx = k + 1
        let mut c2 = pattern.code_unit_at(c2_idx)
        if c2 == '\\'.to_int().to_uint16() && c2_idx + 1 < close {
          c2 = pattern.code_unit_at(c2_idx + 1)
          k = c2_idx + 2
        } else {
          k = c2_idx + 1
        }

        if c1 <= c2 && target >= c1 && target <= c2 {
          matched = true
        }
      } else if target == c1 {
        matched = true
      }
    }

    if negate {
      matched = !matched
    }
    if !matched {
      return false
    }
    return match_pattern_chars(pattern, close + 1, input, si + 1)
  }

  if si >= input.length() {
    return false
  }

  if pch != input.code_unit_at(si) {
    return false
  }

  match_pattern_chars(pattern, pi + 1, input, si + 1)
}
