//
// An experimental Baml parser in Rust
//
// Copyright (c) 2014 by Michael Neumann (mneumann@ntecs.de)
//

static baml: &'static str = r###"
html {
  head {
    title "Hello World"
  }
  body {
    h1 "Hello World"
  }
}
"###;

// use an iterator instead?

fn skip_whitespace<'a>(str: &'a str) -> &'a str {
  let mut cnt = 0;
  for ch in str.chars() {
    match ch {
      ' ' | '\t' | '\r' | '\n' => { cnt += 1; }
      _ => break
    }
  }
  str.slice_from(cnt)
}

fn parse_element(str: &str) {
  let mut str = skip_whitespace(str);
}

fn main() {
  parse_element(baml);
}
