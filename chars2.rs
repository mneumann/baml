use std::str::CharRange;
use std::str::raw;
use std::num::Saturating;

/// External iterator for a string's characters.
/// Use with the `std::iter` module.
#[deriving(Clone)]
pub struct Chars2<'a> {
    /// The slice remaining to be iterated
    priv string: &'a str,
}


impl<'a> Chars2<'a> {
  fn remaining(&self) -> &'a str { self.string }
}

trait TChars2<'a> {
  fn chars2(&self) -> Chars2<'a>;
}


impl<'a> TChars2<'a> for &'a str {
  fn chars2(&self) -> Chars2<'a> {
        Chars2{string: *self}
  }
}

impl<'a> Iterator<char> for Chars2<'a> {
    #[inline]
    fn next(&mut self) -> Option<char> {
        // Decode the next codepoint, then update
        // the slice to be just the remaining part
        if self.string.len() != 0 {
            let CharRange {ch, next} = self.string.char_range_at(0);
            unsafe {
                self.string = raw::slice_unchecked(self.string, next, self.string.len());
            }
            Some(ch)
        } else {
            None
        }
    }

    #[inline]
    fn size_hint(&self) -> (uint, Option<uint>) {
        (self.string.len().saturating_add(3)/4, Some(self.string.len()))
    }
}

fn test_chars2() {
  let s = &"test";
  let mut iter = s.chars2();
  assert_eq!(iter.next(), Some('t'));
  assert_eq!(iter.remaining(), &"est");
}
