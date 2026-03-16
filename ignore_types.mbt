///|
pub struct IgnoreRule {
  raw : String
  pattern : String
  negative : Bool
  directory_only : Bool
  anchored : Bool
  has_slash : Bool
  segments : Array[String]
} derive(Show, Eq)

///|
pub struct MatchResult {
  ignored : Bool
  unignored : Bool
  rule : IgnoreRule?
} derive(Show, Eq)

///|
pub struct IgnoreOptions {
  allow_relative_paths : Bool
} derive(Show, Eq)

///|
pub struct Ignore {
  rules : Array[IgnoreRule]
  strict_path_check : Bool
}
