///|
test "basic wildcard" {
  let ig = @ignore.ignore().add("*.js")
  inspect(ig.ignores("a.js"), content="true")
  inspect(ig.ignores("a.ts"), content="false")
}

///|
test "negation rule" {
  let ig = @ignore.ignore().add("*.js").add("!keep.js")
  inspect(ig.ignores("a.js"), content="true")
  inspect(ig.ignores("keep.js"), content="false")
  inspect(ig.match_path("keep.js").unignored, content="true")
}

///|
test "directory only rule" {
  let ig = @ignore.ignore().add("foo/")
  inspect(ig.ignores("foo"), content="false")
  inspect(ig.ignores("foo/"), content="true")
  inspect(ig.ignores("foo/bar.txt"), content="true")
}

///|
test "globstar rule" {
  let ig = @ignore.ignore().add("a/**/b")
  inspect(ig.ignores("a/b"), content="true")
  inspect(ig.ignores("a/x/b"), content="true")
  inspect(ig.ignores("a/x/y/b"), content="true")
  inspect(ig.ignores("a/x/y/c"), content="false")
}

///|
test "filter result" {
  let ig = @ignore.ignore().add("*.log")
  inspect(
    ig.filter(["a.log", "a.txt", "b.log", "b.txt"]),
    content="[\"a.txt\", \"b.txt\"]",
  )
}

///|
test "windows separator normalization" {
  let ig = @ignore.ignore().add("foo/bar.js")
  inspect(ig.ignores("foo\\bar.js"), content="true")
}

///|
test "path validation defaults to strict" {
  let ig = @ignore.ignore().add("*.js")
  inspect(ig.ignores("./a.js"), content="false")
  inspect(ig.ignores("../a.js"), content="false")
  inspect(ig.ignores("/a.js"), content="false")
}

///|
test "allow relative paths option" {
  let ig = @ignore.ignore(options=@ignore.options(allow_relative_paths=true)).add(
    "*.js",
  )
  inspect(ig.ignores("./a.js"), content="true")
}

///|
test "add file with x fs" {
  let path = "_build/tmp-ignore-test.gitignore"
  @fs.write_string_to_file(path, "*.tmp\n!keep.tmp\n")
  let ig = @ignore.ignore().add_file(path)
  inspect(ig.ignores("foo.tmp"), content="true")
  inspect(ig.ignores("keep.tmp"), content="false")
  @fs.remove_file(path)
}

///|
test "anchored directory rule should only match root" {
  let ig = @ignore.ignore().add("/.a/")
  inspect(ig.ignores(".a"), content="false")
  inspect(ig.ignores(".a/"), content="true")
  inspect(ig.ignores("x/.a/"), content="false")
}

///|
test "leading slash wildcard only matches root" {
  let ig = @ignore.ignore().add("/*.c")
  inspect(ig.ignores("cat-file.c"), content="true")
  inspect(ig.ignores("mozilla-sha1/sha1.c"), content="false")
}

///|
test "leading globstar followed by slash" {
  let ig = @ignore.ignore().add("**/foo")
  inspect(ig.ignores("foo"), content="true")
  inspect(ig.ignores("a/foo"), content="true")
  inspect(ig.ignores("foo/a"), content="true")
  inspect(ig.ignores("a/b/c/foo"), content="true")
}

///|
test "slash-containing pattern is root relative" {
  let ig = @ignore.ignore().add("a/a.js")
  inspect(ig.ignores("a/a.js"), content="true")
  inspect(ig.ignores("b/a/a.js"), content="false")
}

///|
test "slash-containing globstar remains root relative" {
  let ig = @ignore.ignore().add("a/**/b")
  inspect(ig.ignores("a/b"), content="true")
  inspect(ig.ignores("a/x/b"), content="true")
  inspect(ig.ignores("b/a/b"), content="false")
}

///|
test "trailing globstar should not match the directory itself" {
  let ig = @ignore.ignore().add("abc/**")
  inspect(ig.ignores("abc"), content="false")
  inspect(ig.ignores("abc/a"), content="true")
  inspect(ig.ignores("abc/a/b"), content="true")
}

///|
test "escaped wildcard should be literal" {
  let ig = @ignore.ignore().add("\\*.js")
  inspect(ig.ignores("*.js"), content="true")
  inspect(ig.ignores("abc.js"), content="false")
}

///|
test "escaped exclamation should be literal" {
  let ig = @ignore.ignore().add("\\!important!.txt")
  inspect(ig.ignores("!important!.txt"), content="true")
  inspect(ig.ignores("important!.txt"), content="false")
}

///|
test "character class and ranges" {
  let ig1 = @ignore.ignore().add("*.[oa]")
  inspect(ig1.ignores("a.o"), content="true")
  inspect(ig1.ignores("a.a"), content="true")
  inspect(ig1.ignores("a.b"), content="false")

  let ig2 = @ignore.ignore().add("*.pn[0-9]")
  inspect(ig2.ignores("a.pn1"), content="true")
  inspect(ig2.ignores("a.png"), content="false")

  let ig3 = @ignore.ignore().add("*.[a-9]")
  inspect(ig3.ignores("a.a"), content="false")
  inspect(ig3.ignores("a.9"), content="false")
}

///|
test "check_ignore trailing slash with trailing wildcard" {
  let ig = @ignore.ignore().add("foo/bar/*")
  inspect(ig.ignores("foo/bar/"), content="false")
  inspect(ig.check_ignore("foo/bar/").ignored, content="true")
}

///|
test "escaped leading hash and comments" {
  let ig = @ignore.ignore().add("#abc").add("\\#def")
  inspect(ig.ignores("#abc"), content="false")
  inspect(ig.ignores("#def"), content="true")
}

///|
test "escaped spaces" {
  let ig = @ignore.ignore().add("a\\ b\\ c").add("abc\\ ").add("def ")
  inspect(ig.ignores("a b c"), content="true")
  inspect(ig.ignores("abc "), content="true")
  inspect(ig.ignores("abc"), content="false")
  inspect(ig.ignores("def"), content="true")
  inspect(ig.ignores("def "), content="false")
}

///|
test "gitignore sample with nested negation" {
  let ig = @ignore.ignore().add_patterns(["/*", "!/foo", "/foo/*", "!/foo/bar"])

  inspect(ig.ignores("no.js"), content="true")
  inspect(ig.ignores("foo/no.js"), content="true")
  inspect(ig.ignores("foo/bar/yes.js"), content="false")
  inspect(ig.ignores("foo/bar/baz/yes.js"), content="false")
  inspect(ig.ignores("boo/no.js"), content="true")
}

///|
test "cannot reinclude when parent dir excluded" {
  let ig = @ignore.ignore().add_patterns(["/abc/", "!/abc/a.js"])
  inspect(ig.ignores("abc/a.js"), content="true")
  inspect(ig.ignores("abc/d/e.js"), content="true")
}

///|
test "parent wildcard exclusion blocks nested reinclude" {
  let ig = @ignore.ignore().add_patterns([".abc/*", "!.abc/d/*"])
  inspect(ig.ignores(".abc/a.js"), content="true")
  inspect(ig.ignores(".abc/d/e.js"), content="true")
}

///|
test "single segment pattern matches at any depth" {
  let ig = @ignore.ignore().add_patterns(["a.js", "f/"])
  inspect(ig.ignores("a.js"), content="true")
  inspect(ig.ignores("b/a/a.js"), content="true")
  inspect(ig.ignores("a/a.js"), content="true")
  inspect(ig.ignores("b/a.jsa"), content="false")
  inspect(ig.ignores("f/"), content="true")
  inspect(ig.ignores("g/f/"), content="true")
}

///|
test "wildcards do not cross slash" {
  let ig = @ignore.ignore().add("Documentation/*.html")
  inspect(ig.ignores("Documentation/git.html"), content="true")
  inspect(ig.ignores("Documentation/ppc/ppc.html"), content="false")
  inspect(ig.ignores("tools/perf/Documentation/perf.html"), content="false")
}

///|
test "question mark variants" {
  let ig1 = @ignore.ignore().add("a?c")
  inspect(ig1.ignores("abc"), content="true")
  inspect(ig1.ignores("acc"), content="true")
  inspect(ig1.ignores("ac"), content="false")
  inspect(ig1.ignores("abbc"), content="false")

  let ig2 = @ignore.ignore().add("a?b??")
  inspect(ig2.ignores("acbdd"), content="true")
  inspect(ig2.ignores("acbddd"), content="false")
}

///|
test "character classes with multiple brackets" {
  let ig = @ignore.ignore().add("*.[ab][cd][ef]")
  inspect(ig.ignores("a.ace"), content="true")
  inspect(ig.ignores("a.bdf"), content="true")
  inspect(ig.ignores("a.bce"), content="true")
  inspect(ig.ignores("a.abc"), content="false")
  inspect(ig.ignores("a.aceg"), content="false")
}

///|
test "slash-star-slash with unignored directory" {
  let ig = @ignore.ignore().add_patterns(["/*/", "!/foo/"])
  inspect(ig.ignores("foo/bar.js"), content="false")
  inspect(ig.ignores("bar/a.js"), content="true")
}

///|
test "negative pattern without trailing wildcard" {
  let ig = @ignore.ignore().add_patterns([
    "/node_modules/*", "!/node_modules", "!/node_modules/package",
  ])
  inspect(ig.ignores("node_modules/a/a.js"), content="true")
  inspect(ig.ignores("node_modules/package/a.js"), content="false")
}

///|
test "globstar unignore ordering" {
  let ig1 = @ignore.ignore().add_patterns(["!foo/bar.js", "foo/*"])
  inspect(ig1.ignores("foo/bar.js"), content="true")
  inspect(ig1.ignores("foo/bar2.js"), content="true")
  inspect(ig1.ignores("foo/bar/bar.js"), content="true")

  let ig2 = @ignore.ignore().add_patterns(["foo/**", "!foo/bar.js"])
  inspect(ig2.ignores("foo/bar.js"), content="false")
  inspect(ig2.ignores("foo/bar2.js"), content="true")
  inspect(ig2.ignores("foo/bar/bar.js"), content="true")
}

///|
test "double globstar directory and file" {
  let ig = @ignore.ignore().add("**/foo/bar")
  inspect(ig.ignores("foo/bar"), content="true")
  inspect(ig.ignores("abc/foo/bar"), content="true")
  inspect(ig.ignores("abc/foo/bar/"), content="true")
}

///|
test "consecutive stars patterns" {
  let ig = @ignore.ignore().add_patterns([
    "**foo", "*bar", "ba*z", "folder/other-folder/**/**js",
  ])
  inspect(ig.ignores("foo"), content="true")
  inspect(ig.ignores("abcfoo"), content="true")
  inspect(ig.ignores("abar"), content="true")
  inspect(ig.ignores("baz"), content="true")
  inspect(ig.ignores("ba/z"), content="false")
  inspect(ig.ignores("folder/other-folder/dir/main.js"), content="true")
}

///|
test "character class edge cases" {
  let ig1 = @ignore.ignore().add("*.[0-z]")
  inspect(ig1.ignores("a.0"), content="true")
  inspect(ig1.ignores("a.9"), content="true")
  inspect(ig1.ignores("a.a"), content="true")
  inspect(ig1.ignores("a.z"), content="true")
  inspect(ig1.ignores("a.zz"), content="false")

  let ig2 = @ignore.ignore().add("*.[a-]")
  inspect(ig2.ignores("a.a"), content="true")
  inspect(ig2.ignores("a.-"), content="true")
  inspect(ig2.ignores("a.b"), content="false")

  let ig3 = @ignore.ignore().add("*.[]")
  inspect(ig3.ignores("a.[]"), content="false")
}

///|
test "escaped bracket literals" {
  let ig = @ignore.ignore().add_patterns(["src/\\[foo\\]", "src/\\[bar]"])
  inspect(ig.ignores("src/[foo]"), content="true")
  inspect(ig.ignores("src/[bar]"), content="true")
}

///|
test "invalid trailing backslash rule should be ignored" {
  let ig = @ignore.ignore().add_patterns(["test\\", "foo/*", "!foo/test\\"])
  inspect(ig.ignores("test"), content="false")
  inspect(ig.ignores("test\\"), content="false")
  inspect(ig.ignores("foo/test\\"), content="true")
}
