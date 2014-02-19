//
// An experimental Baml parser in Rust
//
// Copyright (c) 2014 by Michael Neumann (mneumann@ntecs.de)
//

use std::str::from_utf8;
use std::str::{MaybeOwned,Slice,Owned};
use std::result::{Result, Ok, Err};

static baml: &'static [u8] = bytes!(r###"
html {
  head {
    title "Hello World"
  }
  body {
    h1 "Hello World"
  }
}
"###);

//fn skip_whitespace<'a>(str: &'a str) -> &'a str {
//  str.trim_left_chars(& &[' ', '\t', '\r', '\n'])
//}

/*fn skip_comment<'a>(str: &'a str) -> &'a str {
  if str.starts_with("//") {
    // str.trim_left_chars(&|c: char| 
    // consume whole line
    str.find('\n') 
  }
}
*/

/*
fn parse_element(str: &str) {
    // let mut str = skip_whitespace(str);
    let mut iter = str.chars2();

    loop {
        match iter.next() {
            Some(c) => {
                match c {
                    ' ' | '\n' => {}
                    'a' .. 'z' => {
                    } 
                }
            }
            None => break
        }
    }
}
*/

#[deriving(Show,Eq)]
enum Document<'a> {
  //SingleTag(MaybeOwned<'a>)
  SingleTag(&'a str)
}

fn is_alpha(ch: u8) -> bool {
  if ch >= ('a' as u8) && ch <= ('z' as u8) { return true }
  if ch >= ('A' as u8) && ch <= ('Z' as u8) { return true }
  return false;
}

fn is_alnum(ch: u8) -> bool {
  if ch >= ('0' as u8) && ch <= ('9' as u8) { return true }
  if is_alpha(ch) { return true }
  return false;
}

struct SliceReader<'a> {
  data: &'a[u8]
}

impl<'a> SliceReader<'a> {

  fn new(data: &'a[u8]) -> SliceReader<'a> {
      SliceReader { data: data }
  }

  fn len(&self) -> uint { self.data.len() }
  fn is_empty(&self) -> bool { self.len() == 0 }
  fn data(&self) -> &'a[u8] { self.data }

  fn head(&mut self) -> Option<u8> {
    self.data.head().map(|c| *c)
  }

  /// Remove `n` (but no more than len()) items from the back and return them.
  fn pop_back(&mut self, n: uint) -> &'a[u8] {
    if n > self.len() { debug!("pop_back(): n > len"); }
    let n = std::cmp::min(n, self.len());
    let (front, back) = self.split_at(self.len() - n);
    self.data = front;
    return back;
  }

  /// Remove `n` (but no more than len()) items from the front and return them. 
  fn pop_front(&mut self, n: uint) -> &'a[u8] {
    if n > self.len() { debug!("pop_front(): n > len"); }
    let n = std::cmp::min(n, self.len());

    let (front, back) = self.split_at(n);
    self.data = back;
    return front;
  }

  fn pop_front_while(&mut self, cond: |u8| -> bool) -> &'a[u8] {
    let mut cnt = 0;
    for &b in self.data.iter() {
      if cond(b) {
        cnt += 1;
      } else {
        break;
      }
    }
    self.pop_front(cnt)
  }

  fn split_at(&self, pos: uint) -> (&'a[u8], &'a[u8]) {
    assert!(pos <= self.data.len());
    (self.data.slice(0, pos), self.data.slice(pos, self.data.len()))
  }
}

/*
fn parse_element<'a>(buf: &'a [u8]) -> Result<Document<'a>, ()> {
  let ch = buf[0];

  if is_alpha(ch) {
    let beg = 0;
    let mut end = beg+1;
    while end < buf.len() {
      if is_alnum(buf[end]) { end += 1; }
      else { break }
    }
    Ok(SingleTag(from_utf8(buf.slice(beg, end)).unwrap()))
  }
  else {
    fail!()
  }
}
*/

fn parse_element<'a>(rd: &'a mut SliceReader) -> Result<Document<'a>, ()> {
  let ch = rd.head();
  if ch.is_none() { return Err(()); }

  if is_alpha(ch.unwrap()) {
    let tag = rd.pop_front_while(|c| is_alnum(c));
    Ok(SingleTag(from_utf8(tag).unwrap()))
  }
  else {
    fail!()
  }
}

#[test]
fn test_single_tag() {
  let str = bytes!("html");
  let mut rd = SliceReader::new(str);

  assert_eq!(parse_element(&mut rd), Ok(SingleTag("html")));
}
