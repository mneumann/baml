# Baml's Macro system 

```
@define(AUTHOR) "Michael Neumann"
@define(FOOTER) {
  div.footer {
    "Copyright by " @expand(AUTHOR)
  }
}

html {
  body {
    @ifdef(FOOTER) {
      @expand(FOOTER)
    }
    @ifndef(FOOTER) {
      @error("FOOTER missing")
    }
  }
}
```

* Macros are expanded lazily, on-demand.
* Macros are local to the subtree in which they are defined in.
* You can use @ifdef(macro) or @ifndef(macro) to test existence of a macro.
* @error(reason) will trigger a compile error.
* @expand defaults to @error if macro is not defined. 
* @include(file) includes the template at the given position.
* @layout(file) is similar to @include, but it render the 
  rest of the current section at the place where it encounters
  an @inner.
* There is also the @deflayout directive which can be used to
  define a layout in the same file (or in an included file).

@deflayout(MYLAYOUT) {
  html {
    body {
      @inner
    }
  }
}

@layout(MYLAYOUT) {
  p "hallo"
}

@deflayout(MYLAYOUT, AUTHOR) {
  html {
    body {
      @inner
      @expand(AUTHOR)
    }
  }
}

@layout(MYLAYOUT, "hallo") 
is equivalent to
{
  @define(AUTHOR, "hallo")
  @layout(MYLAYOUT)
}
