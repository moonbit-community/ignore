///|
test "star with selective unignore" {
  let ig = @ignore.Ignore().add_patterns(["*", "!hasOwnProperty", "!a"])
  inspect(ig.ignores("hasOwnProperty"), content="false")
  inspect(ig.ignores("a/hasOwnProperty"), content="false")
  inspect(ig.ignores("toString"), content="true")
  inspect(ig.ignores("a/toString"), content="true")
}

///|
test "a and a slash variants" {
  let ig = @ignore.Ignore().add_patterns(["a", "a2", "b/", "b2/"])
  inspect(ig.ignores("a"), content="true")
  inspect(ig.ignores("a2/"), content="true")
  inspect(ig.ignores("b"), content="false")
  inspect(ig.ignores("b2/"), content="true")
}

///|
test "ending question mark pattern" {
  let ig = @ignore.Ignore().add("*.web?")
  inspect(ig.ignores("a.webp"), content="true")
  inspect(ig.ignores("a.webm"), content="true")
  inspect(ig.ignores("a.webam"), content="false")
  inspect(ig.ignores("a.png"), content="false")
}

///|
test "mixed character class 0a_" {
  let ig = @ignore.Ignore().add("*.[0a_]")
  inspect(ig.ignores("a.0"), content="true")
  inspect(ig.ignores("a.1"), content="false")
  inspect(ig.ignores("a.a"), content="true")
  inspect(ig.ignores("a.b"), content="false")
  inspect(ig.ignores("a._"), content="true")
  inspect(ig.ignores("a.="), content="false")
}

///|
test "git metadata exceptions" {
  let ig = @ignore.Ignore().add_patterns([
    ".git/*", "!.git/config", ".ftpconfig",
  ])
  inspect(ig.ignores(".ftpconfig"), content="true")
  inspect(ig.ignores(".git/config"), content="false")
  inspect(ig.ignores(".git/description"), content="true")
}

///|
test "directory only pattern matches nested dirs" {
  let ig = @ignore.Ignore().add("abc/")
  inspect(ig.ignores("abc"), content="false")
  inspect(ig.ignores("abc/"), content="true")
  inspect(ig.ignores("bcd/abc/"), content="true")
}

///|
test "question mark does not match slash" {
  let ig = @ignore.Ignore().add("foo?bar")
  inspect(ig.ignores("foo/bar"), content="false")
  inspect(ig.ignores("fooxbar"), content="true")
  inspect(ig.ignores("fooxxbar"), content="false")
}

///|
test "star with unignore slash and specific path" {
  let ig = @ignore.Ignore().add_patterns(["*", "!*/", "!foo/bar"])
  inspect(ig.ignores("a"), content="true")
  inspect(ig.ignores("b/c"), content="true")
  inspect(ig.ignores("foo/bar"), content="false")
  inspect(ig.ignores("foo/e"), content="true")
}

///|
test "root star pattern slash" {
  let ig = @ignore.Ignore().add("/*")
  inspect(ig.ignores("a"), content="true")
  inspect(ig.ignores("a/"), content="true")
  inspect(ig.ignores("a/b/"), content="true")
}

///|
test "check_ignore directory ending slash coverage" {
  let ig = @ignore.Ignore().add_patterns(["c/*", "foo/bar/*"])
  inspect(ig.ignores("c/"), content="false")
  inspect(ig.check_ignore("c/").ignored, content="true")
  inspect(ig.ignores("foo/bar/"), content="false")
  inspect(ig.check_ignore("foo/bar/").ignored, content="true")
  inspect(ig.ignores("c"), content="false")
  inspect(ig.ignores("foo/bar"), content="false")
}

///|
test "comment marker not treated inline" {
  let ig = @ignore.Ignore().add("node_modules# comments")
  inspect(ig.ignores("node_modules/a.js"), content="false")
  inspect(ig.ignores("node_modules# comments"), content="true")
}

///|
test "escaped wildcard segment in negative rule" {
  let ig = @ignore.Ignore().add_patterns(["*.html", "!a/b/\\*/index.html"])
  inspect(ig.ignores("a/b/*/index.html"), content="false")
  inspect(ig.ignores("a/b/index.html"), content="true")
}

///|
test "unescaped wildcard segment in negative rule" {
  let ig = @ignore.Ignore().add_patterns(["*.html", "!a/b/*/index.html"])
  inspect(ig.ignores("a/b/*/index.html"), content="false")
  inspect(ig.ignores("a/b/index.html"), content="true")
}

///|
test "extra range and set combinations" {
  let ig1 = @ignore.Ignore().add("*.[a-z01]")
  inspect(ig1.ignores("a.a"), content="true")
  inspect(ig1.ignores("a.z"), content="true")
  inspect(ig1.ignores("a.0"), content="true")
  inspect(ig1.ignores("a.1"), content="true")
  inspect(ig1.ignores("a.2"), content="false")

  let ig2 = @ignore.Ignore().add("*.[0-0]")
  inspect(ig2.ignores("a.0"), content="true")
  inspect(ig2.ignores("a.1"), content="false")
  inspect(ig2.ignores("a.-"), content="false")

  let ig3 = @ignore.Ignore().add("*.[a-")
  inspect(ig3.ignores("a."), content="false")
  inspect(ig3.ignores("a.["), content="false")
  inspect(ig3.ignores("a.a"), content="false")
  inspect(ig3.ignores("a.-"), content="false")
}

///|
test "add file with bom" {
  let path = "_build/tmp-ignore-bom.gitignore"
  @fs.write_string_to_file(path, "\u{FEFF}node_modules\n")
  let ig = @ignore.Ignore().add_file(path)
  inspect(ig.ignores("node_modules"), content="true")
  @fs.remove_file(path)
}

///|
test "star with abc prefix unignore" {
  let ig = @ignore.Ignore().add_patterns(["*", "!abc*"])
  inspect(ig.ignores("a"), content="true")
  inspect(ig.ignores("abc"), content="false")
  inspect(ig.ignores("abcd"), content="false")
}

///|
test "doc frotz rooted directory" {
  let ig = @ignore.Ignore().add("doc/frotz/")
  inspect(ig.ignores("doc/frotz/"), content="true")
  inspect(ig.ignores("a/doc/frotz/"), content="false")
}

///|
test "file pattern ending with star" {
  let ig = @ignore.Ignore().add("abc.js*")
  inspect(ig.ignores("abc.js/"), content="true")
  inspect(ig.ignores("abc.js/abc"), content="true")
  inspect(ig.ignores("abc.jsa/"), content="true")
  inspect(ig.ignores("abc.jsa/abc"), content="true")
}

///|
test "wildcard filename b" {
  let ig = @ignore.Ignore().add("*.b")
  inspect(ig.ignores("b/a.b"), content="true")
  inspect(ig.ignores("b/.b"), content="true")
  inspect(ig.ignores("b/.ba"), content="false")
  inspect(ig.ignores("b/c/a.b"), content="true")
}

///|
test "dot file and dot dir" {
  let ig1 = @ignore.Ignore().add(".d")
  inspect(ig1.ignores(".d"), content="true")
  inspect(ig1.ignores(".dd"), content="false")
  inspect(ig1.ignores("d.d"), content="false")
  inspect(ig1.ignores("d/.d"), content="true")

  let ig2 = @ignore.Ignore().add(".e")
  inspect(ig2.ignores(".e/"), content="true")
  inspect(ig2.ignores(".ee/"), content="false")
  inspect(ig2.ignores(".e/e"), content="true")
  inspect(ig2.ignores("e/.e"), content="true")
}

///|
test "node modules nested" {
  let ig1 = @ignore.Ignore().add("node_modules/")
  inspect(ig1.ignores("node_modules/gulp/node_modules/abc.md"), content="true")
  inspect(
    ig1.ignores("node_modules/gulp/node_modules/abc.json"),
    content="true",
  )

  let ig2 = @ignore.Ignore().add("node_modules")
  inspect(ig2.ignores("a/b/node_modules/abc.md"), content="true")
}

///|
test "dots filename patterns" {
  let ig = @ignore.Ignore().add_patterns(["/...", "/....."])
  inspect(ig.ignores("..."), content="true")
  inspect(ig.ignores("...."), content="false")
  inspect(ig.ignores("....."), content="true")
  inspect(ig.ignores("......"), content="false")
}

///|
test "blank line rule does nothing" {
  let ig = @ignore.Ignore().add("")
  inspect(ig.ignores("a"), content="false")
  inspect(ig.ignores("a/b/c"), content="false")
}

///|
test "rule may hide directory first" {
  let ig = @ignore.Ignore().add_patterns(["abc", "!bcd/abc/a.js"])
  inspect(ig.ignores("abc/a.js"), content="true")
  inspect(ig.ignores("bcd/abc/a.js"), content="true")
}

///|
test "escaped spaces intermediate forms" {
  let ig = @ignore.Ignore().add_patterns(["abc\\ d", "abc e", "a\\ b\\ c"])
  inspect(ig.ignores("abc d"), content="true")
  inspect(ig.ignores("abc e"), content="true")
  inspect(ig.ignores("abc/abc d"), content="true")
  inspect(ig.ignores("abc/abc e"), content="true")
  inspect(ig.ignores("abc/a b c"), content="true")
}

///|
test "bracket corner forms" {
  let ig = @ignore.Ignore().add_patterns(["src/[q", "src/\\[u", "src/[x\\]"])
  inspect(ig.ignores("src/[q"), content="false")
  inspect(ig.ignores("src/[u"), content="true")
  inspect(ig.ignores("src/[x"), content="false")
  inspect(ig.ignores("src/[x]"), content="false")
  inspect(ig.ignores("src/x"), content="false")
}

///|
test "wildcard with escaped star in middle path" {
  let ig = @ignore.Ignore().add_patterns(["*.html", "!b/\\*/index.html"])
  inspect(ig.ignores("a/b/*/index.html"), content="true")
  inspect(ig.ignores("a/b/index.html"), content="true")
}

///|
test "range notation extras from fixtures" {
  let ig = @ignore.Ignore().add_patterns([
    "src/\\[bar]", "src/[e\\\\]", "s/[f\\\\\\\\]", "s/[a-z0-9]",
  ])
  inspect(ig.ignores("src/[bar]"), content="true")
  inspect(ig.ignores("src/e"), content="true")
  inspect(ig.ignores("s/f"), content="true")
  inspect(ig.ignores("s/a"), content="true")
  inspect(ig.ignores("s/0"), content="true")
}

///|
test "add lines from fixture aignore" {
  let fixture = "abc\n!abc/b\n#e\n\\#f\n"
  let ig = @ignore.Ignore().add_lines(fixture)
  inspect(ig.ignores("abc/a.js"), content="true")
  inspect(ig.ignores("abc/b/b.js"), content="true")
  inspect(ig.ignores("#e"), content="false")
  inspect(ig.ignores("#f"), content="true")
}

///|
test "issue2 like patterns" {
  let ig = @ignore.Ignore().add_lines("/.project\nthumbs.db\n.*.sw?\n")
  inspect(ig.ignores(".project"), content="true")
  inspect(ig.ignores("abc/.project"), content="false")
  inspect(ig.ignores(".a.sw"), content="false")
  inspect(ig.ignores(".a.sw?"), content="true")
  inspect(ig.ignores("thumbs.db"), content="true")
}

///|
test "readme example include subdir" {
  let ig = @ignore.Ignore().add_patterns([".abc/*", "!.abc/d/"])
  inspect(ig.ignores(".abc/a.js"), content="true")
  inspect(ig.ignores(".abc/d/e.js"), content="false")
}

///|
test "dir ended with star does not match dir itself" {
  let ig = @ignore.Ignore().add("abc/*")
  inspect(ig.ignores("abc"), content="false")
}

///|
test "slash at beginning with wildcard details" {
  let ig = @ignore.Ignore().add("/*.c")
  inspect(ig.ignores(".c"), content="true")
  inspect(ig.ignores("c.c"), content="true")
  inspect(ig.ignores("c/c.c"), content="false")
  inspect(ig.ignores("c/d"), content="false")
}

///|
test "escape metacharacters in patterns" {
  let ig = @ignore.Ignore().add_patterns([
    "*.js", "!\\*.js", "!a#b.js", "!?.js", "#abc", "\\#abc",
  ])
  inspect(ig.ignores("*.js"), content="false")
  inspect(ig.ignores("abc.js"), content="true")
  inspect(ig.ignores("a#b.js"), content="false")
  inspect(ig.ignores("abc"), content="false")
  inspect(ig.ignores("#abc"), content="true")
  inspect(ig.ignores("?.js"), content="false")
}

///|
test "ignore dot files pattern" {
  let ig = @ignore.Ignore().add(".*")
  inspect(ig.ignores(".a"), content="true")
  inspect(ig.ignores(".gitignore"), content="true")
  inspect(ig.ignores("a/.gitignore"), content="true")
}

///|
test "negation restores included path" {
  let ig = @ignore.Ignore().add_patterns(["abc", "!abc"])
  inspect(ig.ignores("abc/"), content="false")
  inspect(ig.ignores("abc/a.js"), content="false")
}

///|
test "globstar double group ordering" {
  let ig1 = @ignore.Ignore().add_patterns(["!foo/bar.js", "foo/**/**"])
  inspect(ig1.ignores("foo/bar.js"), content="true")
  inspect(ig1.ignores("foo/bar2.js"), content="true")
  inspect(ig1.ignores("foo/bar/bar.js"), content="true")

  let ig2 = @ignore.Ignore().add_patterns(["foo/**/**", "!foo/bar.js"])
  inspect(ig2.ignores("foo/bar.js"), content="false")
  inspect(ig2.ignores("foo/bar2.js"), content="true")
  inspect(ig2.ignores("foo/bar/bar.js"), content="true")
}

///|
test "range combinations pn variants" {
  let ig1 = @ignore.Ignore().add("*.pn[a-z]")
  inspect(ig1.ignores("a.pn1"), content="false")
  inspect(ig1.ignores("a.png"), content="true")

  let ig2 = @ignore.Ignore().add("*.pn[0-9]")
  inspect(ig2.ignores("a.pn1"), content="true")
  inspect(ig2.ignores("a.pna"), content="false")

  let ig3 = @ignore.Ignore().add("*.pn[0-9a-z]")
  inspect(ig3.ignores("a.pn1"), content="true")
  inspect(ig3.ignores("a.pna"), content="true")
  inspect(ig3.ignores("a.pn-"), content="false")
}

///|
test "node modules duplicate rules" {
  let ig = @ignore.Ignore().add_patterns(["node_modules/", "node_modules/"])
  inspect(ig.ignores("node_modules/gulp/node_modules/abc.md"), content="true")
  inspect(ig.ignores("node_modules/gulp/node_modules/abc.json"), content="true")
}

///|
test "file names with dots and no rules" {
  let ig = @ignore.Ignore()
  inspect(ig.ignores("..."), content="false")
  inspect(ig.ignores("...."), content="false")
  inspect(ig.ignores("....."), content="false")
}

///|
test "consecutive stars additional variants" {
  let ig = @ignore.Ignore().add_patterns(["**foo", "*bar", "ba*z"])
  inspect(ig.ignores("a/foo"), content="true")
  inspect(ig.ignores("afoo"), content="true")
  inspect(ig.ignores("abfoo"), content="true")
  inspect(ig.ignores("baaaaaaz"), content="true")
}

///|
test "trailing globstar includes only inside" {
  let ig = @ignore.Ignore().add("abc/**")
  inspect(ig.ignores("abc/a/"), content="true")
  inspect(ig.ignores("abc/b"), content="true")
  inspect(ig.ignores("abc/d/e/f/g"), content="true")
  inspect(ig.ignores("bcd/abc/a"), content="false")
  inspect(ig.ignores("abc"), content="false")
}

///|
test "unicode characters in paths" {
  let ig = @ignore.Ignore().add("test")
  inspect(ig.ignores("some/path/to/test/ignored.js"), content="true")
  inspect(
    ig.ignores("some/special/path/to/目录/test/ignored.js"),
    content="true",
  )
}
