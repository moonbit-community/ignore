///|
pub fn IgnoreOptions::IgnoreOptions(
  allow_relative_paths? : Bool = false,
) -> IgnoreOptions {
  { allow_relative_paths, }
}

///|
pub impl Default for IgnoreOptions with fn default() {
  IgnoreOptions()
}

///|
pub fn Ignore::Ignore(options? : IgnoreOptions = Default::default()) -> Ignore {
  { rules: [], strict_path_check: !options.allow_relative_paths }
}

///|
pub fn is_path_valid(pathname : String) -> Bool {
  if pathname.is_empty() {
    return false
  }
  if pathname == "." || pathname == ".." {
    return false
  }
  if pathname.has_prefix("/") ||
    pathname.has_prefix("./") ||
    pathname.has_prefix("../") {
    return false
  }
  if is_windows_abs(pathname) {
    return false
  }
  true
}

///|
pub fn Ignore::add(self : Ignore, pattern : String) -> Ignore {
  if parse_rule(pattern) is Some(rule) {
    self.rules.push(rule)
  }
  self
}

///|
pub fn Ignore::add_patterns(self : Ignore, patterns : Array[String]) -> Ignore {
  for pattern in patterns {
    let _ = self.add(pattern)
  }
  self
}

///|
pub fn Ignore::add_lines(self : Ignore, patterns : String) -> Ignore {
  self.add_patterns(split_lines(patterns))
}

///|
pub fn Ignore::add_file(
  self : Ignore,
  path : String,
) -> Ignore raise @fs.IOError {
  let content = @fs.read_file_to_string(path)
  self.add_lines(content)
}

///|
pub fn Ignore::ignores(self : Ignore, pathname : String) -> Bool {
  self.match_path(pathname).ignored
}

///|
pub fn Ignore::filter(
  self : Ignore,
  pathnames : Array[String],
) -> Array[String] {
  pathnames.iter().filter(path => !self.ignores(path)).collect()
}
