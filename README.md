# Baml

A _balanced_, whitespace-insensitive _markup_ _language_ for HTML-templating inspired by [Slim] and [Haml].

## Advantages

* Whitespace _insensitive_!!!
* Compact markup.
* Safe: Context-sensitive escaping and interpolation.
* Editor friendly: Can simply jump to the end of a block.

### Whitespace insensitive

How can Ruby programmers use whitespace sensitive markup??? :)

### Editor friendly

Without special syntax support, to jump to the end of a tag or expression, position
your cursor on the <code>{</code>-character and press <code>%</code> in <code>vim</code>.
Code folding should work seamlessly as well (haven't tried).

## Examples

This [Baml] code below:

```
section.container {
  h1 ${ post.title }
  h2 ${ post.subtitle }
  .content ${ post.content }
}
```

is equivalent to this in [Haml]:

```haml
%section.container
  %h1= post.title
  %h2= post.subtitle
  .content
    = post.content
```

or this is [Slim]:

```slim
section.container
  h1 = post.title
  h2 = post.subtitle
  .content = post.content
```

or this is [Erb]:

```erb
<section class="container">
  <h1><%= post.title %></h1>
  <h2><%= post.subtitle %></h2>
  <div class="content">
    <%= post.content %>
  </div>
</section>
```

## More Complex Example

```
doctype html
html {
  head {
    title "Baml Examples";
    meta name="keywords" content="template language"
    meta name="author" content=${ author }
  }
  body {
    h1 "Markup examples"
    
    #content {
      p {
        | This example shows you how a basic Baml
        | templating file looks like.
      }
    }
    
    // `!` is a non-nesting code line
    ! yield(self)

    // while `%` introduces a block which has to be
    // terminated by `}` w/o leading `%`. This makes
    // it beautifully line up with in-place HTML.
    // The last character of a `%` line must be a
    // `{`
    
    % if items.len() > 0 {
      table {
        % for &item in items.iter() {
          tr {
              td.name =  ${ item.name }
              td.price = ${ item.price }
          }
        }
      }
    }
    % else {
      p "No items found. Please add some inventory. Thank you!"
    }
    
    div id="footer" {
      ${ render("footer") }
      | Copyright ${ year } #{ author }
    }
  }
}
```

### Further specs

### Interpolation

Not interpolated attributes use a single quote:

```
div id='${ not interpolated }' 
```

And interpolated attribute values:

```
div id="item${ item.id }"
```

Of course this can be used in the same way for text:

```
div '${not interpolated}'
div "${ page.title }"
```

produces:

```html
<div>${not interpolated}</div>
<div>The title</div>
```

Interpolation also appears within the `|`-strings. If you need to emit a not
interpolated string, simply use a single quote.

### Template parameter types 

Statically typed languages need the types of the parameters to be specified. I
am thinking about something like this for example for Rust:

```
// file: article.baml
: article_id: uint
: article_title: &str
: article_content: &HtmlMarkup

div#id="article${ article_id }" {
  h2 ${ article_title }
  div.content ${ article_content }
}
```

Note that all strings are sanitized by default. If you want to insert raw html
code (e.g. `article_content`) you have to use a separate type like
<code>HtmlMarkup</code>. Of course this can only be expanded in a section where
HTML is accepted, not in an attribute!

The template above would generate the following Rust code:

```rust
mod article_template {
  struct Args {
    article_id: uint,
    article_title: &str,
    article_content: &HtmlMarkup,
  }
  fn render(renderer: &mut BamlRenderer, args: &Args) { 
    let article_id = args.article_id;
    let article_title = args.article_title;
    let article_content = args.article_content;
    // ...
  }
}
```

You can render this template from within another template as shown below:
 
```rust
// page.baml
html {
  body {
    ! article_template::render(renderer,
    !                          article_template::Args {
    !                              article_id: 1,
    !                              article_title: &"My first post",
    !                              article_content: &HtmlMarkup(~"<div>123</div>")
    !                          });
  }
}
```

Or by using the special <code>render!</code> macro:

```
// page.baml
html {
  body {
    ! render!(article_template { article_id: 1,
    !                            article_title: &"My first post",
    !                            article_content: &HtmlMarkup(~"<div>123</div>")
    !                          });
  }
}
```

FIXME: I am not sure if this works due to hygienic macros.

Of course it's more realistic that you have an <code>Article</code> struct:

```rust
struct Article {
  id: uint,
  title: &str,
  content: &HtmlMarkup
}
```

The article template then becomes simpler:

```
// file: article.baml
: article: &Article

div#id="article${ article.id }" {
  h2 ${ article.title }
  div.content ${ article.content }
}
```

And the page template would then look like:

```
// page.baml
: articles: &[&Article]

html {
  body {
    % for article in articles.iter() {
      ! render!(article_template { article: article });
    }
  }
}
```

Much, much nicer!

## Spec

All whitespaces are ignored, i.e. "beginning of a line" means that it may be preceded by any number of whitespaces.
Newlines are no whitespaces. In some parts they are significant.

* Template parameter definition: <code>:</code>, whole line.
* Comment: <code>/</code>, extends till end of line.
* Html tag: <code>[a-zA-Z][a-zA-Z0-9]*</code>. Either at the beginning of a line, after a <code>;</code> or a
  <code>{</code>.
* Html tag attribute: <code>[a-zA-Z][a-zA-Z0-9_-]*</code>, followed by an optional <code>=</code> and string or
  expression.
* Html id: The special syntax <code>#myid</code> is supported, where `myid` is either an identifier, or a string.
  Equivalent to <code>id=myid</code>. Can also stand on it's own without a html tag, in which case a <code>div</code>
  tag is used.
* Html css class: The special syntax <code>.css_class</code> is supported. The same applies here as for a Html id.
* Tag content: Either by nesting by using <code>{</code> after a tag definition, or in-place for text content
  by using a string (<code>p "content of paragraph"</code>) or an expression (<code>div ${content}</code>).
* Tag delimiter: If you want to have multiple tags on one line, use <code>;</code> to separte them:
  <code>p "hallo"; p "welt"</code>.
* Nesting code: Use the <code>%</code> at the beginning of a line. Expands to the end of the line. The last character
  of the line should be a <code>{</code> as this keeps the balance with the closing <code>}</code> intact. But for 
  some languages this could be relaxed. In Ruby for example <code>% for i in 1..10</code> would not need a trailing
  <code>{</code>. Here, if there is a trailing <code>{|parameters|</code>, the closing <code>}</code> would generate a
  <code>}</code>, otherwise it would generate <code>end</code>. 
* Non-nesting code: Use <code>!</code> at the beginning of a line. Expands till the end of the line. If you have
  problems with nesting code in some languages, you can always emulate it with the <code>!</code>.
* Inline Html: Every line that starts with <code>&lt;</code> gets copied verbatim, useful for including HTML.
* Strings: Either <code>"..."</code> or <code>'...'</code>. The first variant can include expressions 
  (<code>"id${ article.id }"</code>), the second cannot. A third variant uses the <code>|</code>. It has to 
  start at the beginning of the line and extends till the end of the line, expressions are expanded.
* HTML comments: Use <code>\\</code>, expands till the end of the line.

## Open Questions

### Multi-line strings

Remove <code>|</code> in favour of a more general multi line string literal. <code>|</code> is bad, because it doesn't 
let you group text as a unit and operate with filters on the group of text. Instead introduce 
<code>~{ multiline }</code>, which also allows a terminator to be specified:

```
div ~{
  This is a paragraph of text
}

div ~###{
  This is a paragraph of text containing a }
  which does not end the string!
}###

div ~!{
  Interpolation is ${ performed }
}
```

Parsing of those strings is pretty easy. By default, interpolation of <code>${...}</code> expressions within these
strings is not performed, but this can be changed with the <code>!</code> modifier. Note that it is not used as terminator after the closing <code>}</code>.

### Filters

This can be used to correctly escape Javascript code:

```
@javascript "if (this.value > 2)"
```

This will correctly escape the <code>&gt;</code> and generate <code>if (this.value &amp;gt; 2)</code>.

Depending on the context this will also generate the surround <code>&lt;script&gt;</code> tags.

For multiline javascript:

```
@javascript ~{
  function some() {
    return "Hallo";
  }
}
```

There can be only one filter coming before an expression. Note that the filter might modify the interpolation method used within the following string:

```
:myvalue: &str
div onclick=@javascript "alert(${ myvalue })"
div id="${ myvalue }"
```

The first will interpolate <code>myvalue</code> as a Javascript string while the second will 
interpolate it as a HTML attribute (without the surrounding <code>"..."</code>).

### HTML attributes

HTML allows something like:
```html
<div id="id" disabled />
```

I support this in Baml:

```
div id="id" disabled
```

But I might want to change it towards always using the <code>attr = value</code> notation,
plus a special <code>_</code> value which means "ignore":

```
div id="id" disabled=_
```

This doesn't look as nice, but is more regular. The question is how frequent those attributes are.
This is required to allow expressions for attribute names:

```
div ${myattr}="abc"
```

which is currently not supported, as a string or expression is always treated as the (inline) body of a tag (and as
such ends the tag).

Including multiple attributes into a tag is not (yet) supported. But I could think of something like:

```
div *${myattributes}
```

In Ruby, this would make it possible to inject either a single attribute or multiple attributes:

```ruby
myattributes = {:id => "abc", :class => "css"}
```

### Macros

Including other baml files into the current:

```
@include('test.baml')
```

Note that here the string MUST NOT contain interpolation expressions, as interpolation is done at run-time,
while @include is evaluated at compile time.

If we extend the <code>@filter</code> syntax for arguments like in <code>@pygments(ruby)</code>, we
can also introduce macros in the language:

```
@macro(FOOTER, name, year) {
  div#footer {
    "Copyright (c) " @expand(year) " by " @expand(name) 
}

html {
  body {
    @expand(FOOTER, "Michael Neumann", "2014")
  }
}

```

We would need to make filters aware of tags, i.e. the HTML nodes <code>{ ... }</code> would be passed to
the macro filter. And also we'd have to allow filters to use arguments optionally.
Also macros would need to be allowed to come at the beginning of a statement.

This would make for nice code blocks are reusable template code (independent of the language; Ruby or Rust).

## Grammar

This is the basic grammar of a Baml document (incomplete):


```ebnf

stmtend ::= NL | ";"

expr ::= string | "${" code "}"

idname   ::= ("a" .. "z" | "A" .. "Z") ("a" .. "z" | "A" .. "Z" | "-")*
tagname  ::= id
attrname ::= id

tag ::= tagname [attribute]* ([expr] stmtend | "{")
etag ::= "}"

attribute ::= attrname ["=" expr]
```

[Baml]: https://github.com/mneumann/batl
[Slim]: http://slim-lang.com/
[Haml]: http://haml.info/
[Erb]: http://ruby-doc.org/stdlib-2.1.0/libdoc/erb/rdoc/ERB.html
