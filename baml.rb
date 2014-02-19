#
# Copyright (c) 2014 by Michael Neumann
#
# An experimental Baml implementation
#

baml = <<EOS
html {
  head {
    title "Hello World"
  }
  body {
    h1 "Hello World"
  }
}
EOS
 
def parse_statement(line)
  line.strip! # leading and trailing whitespaces

  return nil if line.empty?

  case line
  when /^([a-zA-Z][0-9a-zA-Z-]*)/
    tag, rem = $1, $' 
    rem.strip!
    case rem
    when /^["]([^"]*)["]/
      str, rem = $1, $'
      rem.strip!

      case rem
      when /^\/\//
        # comment
        rem = ""
        
      when /^;/
        # end statement
        rem = $' 
      else
        raise unless rem.empty?
      end

      return :tag, {:tag => tag, :body => str}, rem

    when /^[{]/
      rem = $'
      return :otag, {:tag => tag}, rem
    else
      raise "#{line}, #{rem}"
    end
  when /^[}]/
    rem = $'
    return :etag, {}, rem
  else
    raise
  end
end

$tag_stack = []

def indent
  print(" " * $tag_stack.size*4)
end

baml.each_line {|line|
  rem = line
  loop do
    if res = parse_statement(rem)
      kind, attrs, rem = *res
      case kind
      when :tag
        tag = attrs[:tag]
        indent()
        puts "<#{tag}>#{attrs[:body]}</#{tag}>"
      when :otag
        tag = attrs[:tag] || raise
        indent()
        puts "<#{tag}>"
        $tag_stack.push(tag)
      when :etag
        tag = $tag_stack.pop || raise("tag_stack empty")
        indent()
        puts "</#{tag}>"
      else
        raise "invalid kind"
      end
    else
      break
    end
  end
}
