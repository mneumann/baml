# Baml

A _balanced_, whitespace-insensitive _markup_ _language_ for HTML-templating inspired by [Slim] and [Haml].

## Advantages

* Whitespace insensitive!!!
* Compact
* Editor friendly: Can simply jump to the end of a block.
* Safe

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

## Grammar

This is the basic grammar of a Baml document:


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

## Open questions

[Baml]: https://github.com/mneumann/batl
[Slim]: http://slim-lang.com/
[Haml]: http://haml.info/
[Erb]: http://ruby-doc.org/stdlib-2.1.0/libdoc/erb/rdoc/ERB.html
