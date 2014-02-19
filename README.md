# Batl

A _balanced_, whitespace-insensitive _templating_ _language_ for HTML inspired by [Slim] and [Haml].

## Advantages

* Whitespace insensitive!!!
* Compact
* Editor friendly: Can simply jump to the end of a block.

## Examples

This [Batl] code below:

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
    title "Batl Examples";
    meta name="keywords" content="template language"
    meta name="author" content=${ author }
  }
  body {
    h1 "Markup examples"
    
    #content {
      p {
        | This example shows you how a basic Batl
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
        % for item in items.iter() {
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

[Batl]: https://github.com/mneumann/batl
[Slim]: http://slim-lang.com/
[Haml]: http://haml.info/
[Erb]: http://ruby-doc.org/stdlib-2.1.0/libdoc/erb/rdoc/ERB.html
