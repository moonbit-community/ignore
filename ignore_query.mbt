///|
fn eval_rules(
  rules : Array[IgnoreRule],
  path_segments : Array[String],
  is_dir : Bool,
  allow_empty_last_star : Bool,
) -> MatchResult {
  let mut ignored = false
  let mut unignored = false
  let mut matched_rule : IgnoreRule? = None

  for i in 0..<rules.length() {
    let rule = rules[i]
    if match_rule(rule, path_segments, is_dir, allow_empty_last_star) {
      if rule.negative {
        ignored = false
        unignored = true
        matched_rule = Some(rule)
      } else {
        ignored = true
        unignored = false
        matched_rule = Some(rule)
      }
    }
  }

  { ignored, unignored, rule: matched_rule }
}

///|
pub fn Ignore::match_path(self : Ignore, pathname : String) -> MatchResult {
  let path = normalize_path(pathname)
  if self.strict_path_check && !is_path_valid(path) {
    return { ignored: false, unignored: false, rule: None }
  }

  let is_dir = ends_with_slash(path)
  let path_segments = path_to_segments(path)
  if path_segments.is_empty() {
    return { ignored: false, unignored: false, rule: None }
  }

  if path_segments.length() > 1 {
    let parent_path = join_segments(
        path_segments,
        0,
        path_segments.length() - 1,
      ) +
      "/"
    let parent_result = self.match_path(parent_path)
    if parent_result.ignored {
      return parent_result
    }
  }

  eval_rules(self.rules, path_segments, is_dir, false)
}

///|
pub fn Ignore::check_ignore(self : Ignore, pathname : String) -> MatchResult {
  let path = normalize_path(pathname)
  if self.strict_path_check && !is_path_valid(path) {
    return { ignored: false, unignored: false, rule: None }
  }

  if !ends_with_slash(path) {
    return self.match_path(path)
  }

  let path_segments = path_to_segments(path)
  if path_segments.is_empty() {
    return { ignored: false, unignored: false, rule: None }
  }

  if path_segments.length() > 1 {
    let parent_path = join_segments(
        path_segments,
        0,
        path_segments.length() - 1,
      ) +
      "/"
    let parent_result = self.match_path(parent_path)
    if parent_result.ignored {
      return parent_result
    }
  }

  eval_rules(self.rules, path_segments, true, true)
}
