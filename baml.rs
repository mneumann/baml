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

/*fn is_whitespace(ch: u8) -> bool {
  if ch == (' ' as u8) || ch == ('\t' as u8) || ch == ('\r' as u8) || ch == ('\n' as u8) { return true; }
  return false;
}*/

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

// skips whitespace wihtout newlines
fn skip_whitespace<'a>(rd: &'a mut SliceReader) {
  let _ = rd.pop_front_while(|c| 
    c == (' ' as u8) || c == ('\t' as u8) || c == ('\r' as u8)
  );
}

// skips whitespace including newlines
fn skip_whitespace_and_newline<'a>(rd: &'a mut SliceReader) {
  let _ = rd.pop_front_while(|c| 
    c == (' ' as u8) || c == ('\t' as u8) || c == ('\r' as u8) || c == ('\n' as u8)
  );
}


// assumes that whitespaces have been skipped.
fn parse_ident<'a>(rd: &'a mut SliceReader) -> Option<&'a str> {
    match rd.head() {
        Some(ch) => {
            //assert!(!is_whitespace(ch));
            if is_alpha(ch) {
                let id = rd.pop_front_while(|c| is_alnum(c));
                let id = from_utf8(id).unwrap();
                Some(id)
            } else {
                None
            }
        }
        None => None
    }
}

enum Expr<'a> {
  String(&'a str),
  Eval(&'a str)
}

// assumes that whitespaces have been skipped.
fn parse_expr<'a>(rd: &'a mut SliceReader) -> Option<Expr<'a>> {
    match rd.head() {
        Some(ch) => {
            //assert!(!is_whitespace(ch));
            match ch as char {
                // XXX: Allow '' quoting
                '"' => {
                    let _ = rd.pop_front(1);
                    let string = rd.pop_front_while(|c| c != ('"' as u8));
                    let string = from_utf8(string).unwrap();
                    assert!(rd.head() == Some('"' as u8));
                    let _ = rd.pop_front(1);
                    Some(String(string))
                }
                '$' => {
                   fail!()
                }
                _   => None
            }
        }
        None => None
    }
}

fn parse_element<'a>(rd: &'a mut SliceReader) -> Result<Document<'a>, ()> {
  skip_whitespace_and_newline(rd);

  if rd.is_empty() {
    return Err(());
  }

  let ch = rd.head().unwrap();

  if is_alpha(ch) {
    let tag = parse_ident(rd).unwrap();

    // parse attributes
    let mut attributes: ~[&'a str] = ~[];

    loop {
/*
      skip_whitespace(rd); // attributes must be on the same line
      let ident = parse_ident(rd);
      match ident {
        Some(param) => {
          attributes.push(param);
          skip_whitespace(rd);
          if rd.head() == Some('=' as u8) {
            // an expression follows
            // FIXME: after a `=` we could allow a newline.
            // then we should also ignore comments
            skip_whitespace(rd);
            let expr = parse_expr(rd);
          }
        }
        None => { break }
      }
*/
    }

    println!("{}", attributes);

    return Ok(SingleTag(tag));

  }
  else {
    fail!()
  }
}

#[test]
fn test_single_tag() {
  let str = bytes!(" html");
  let mut rd = SliceReader::new(str);

  assert_eq!(parse_element(&mut rd), Ok(SingleTag("html")));
}
