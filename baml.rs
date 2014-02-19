//
// An experimental Baml parser in Rust
//
// Copyright (c) 2014 by Michael Neumann (mneumann@ntecs.de)
//

use chars2::{TChars2};

mod chars2;

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

fn skip_whitespace<'a>(str: &'a str) -> &'a str {
  let mut iter = str.chars2();
  for ch in iter {
    match ch {
      ' ' | '\t' | '\r' | '\n' => { }
      _ => break
    }
  }
  iter.remaining()
}

fn parse_element(str: &str) {
  let mut str = skip_whitespace(str);
}

fn main() {
  parse_element(baml);
}
