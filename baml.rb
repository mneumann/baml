#
# Copyright (c) 2014 by Michael Neumann
#
# An experimental Baml implementation
#

def lexer(doc)
  iter = doc.each_char
  ch = iter.next
  loop do

    case ch

    # An identifier
    when 'a' .. 'z', 'A' .. 'Z'
      id = ""
      loop do
        case ch
        when 'a' .. 'z', 'A' .. 'Z', '0' .. '9', '-', '_'
          id << ch
          ch = iter.next
        else
          break
        end
      end

      yield :id, id
      next # we already have read the next element!

    # A string
    when '"'
      str = ""
      loop do
        ch = iter.next
        case ch
        when '"'
          break
        when "\n"
          raise "Multi-line string not allowed"
        else
          str << ch
        end
      end

      yield :dstr, str

    # A single quoted non-interpolated string
    when "'"
      str = ""
      loop do
        ch = iter.next
        case ch
        when "'"
          break
        when "\n"
          raise "Multi-line string not allowed"
        else
          str << ch
        end
      end

      yield :str, str

    # An expansion
    when '$'
      ch = iter.next
      raise 'missing `{` after `$`' if ch != '{'
      
      str = ""
      loop do
        ch = iter.next
        case ch
        when '}'
          break
        else
          str << ch
        end
      end

      yield :eval, str

    # A comment
    when '/'
      loop do
        break if iter.next == "\n"
      end

    when '<'
      html = ""
      html << c

      loop do
        ch = iter.next
        break if ch == "\n"
        html << ch 
      end
      yield :html, html

    when '|', ':', "\\", '%', '!'
      ty = case ch
           when '|' then :txt
           when ':' then :param
           when "\\" then :comment
           when "%" then :code_nest
           when "!" then :code
           else raise
           end

      txt = ""

      loop do
        ch = iter.next
        break if ch == "\n"
        txt << ch 
      end

      yield ty, html

    when ' ', "\t", "\r"     # ignore whitespace
    when "\n" then yield :nl # new line
    when '{'  then yield :open
    when '}'  then yield :close
    when ';'  then yield :semi
    when '.'  then yield :dot
    when '#'  then yield :hash
    when '='  then yield :assign

    else
      raise "invalid character: #{ch}"
    end

    ch = iter.next
  end
end

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

def parse(baml)
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
end

#parse(baml)
lexer(File.read("example.baml")) {|ty, id|
  puts "#{ty}\t #{id}"
}
