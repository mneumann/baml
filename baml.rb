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
        when "\\"
          if iter.next != '"'
            raise 'Only escaping of " allowed'
          end
          str << '"'
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
        when "\\"
          if iter.next != "'"
            raise "Only escaping of ' allowed"
          end
          str << "'"
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

class Lexeme
  attr_accessor :ty, :value
  def inspect
    if value
      "#{ty}(#{value.inspect})"
    else
      "#{ty}"
    end
  end
end

def parse_statements(lexs)
  p "parse_statements"
  loop do
    cur = lexs.first
    break unless cur
    case cur.ty
    when :nl, :semi then lexs.shift
    when :id
      parse_statement(lexs)
    else break
    end
  end
end

def parse_statement(lexs)
  p "parse_statement"
  cur = lexs.first || raise

  case cur.ty
  when :id 
    tag = cur.value
    lexs.shift
    cur = lexs.first

    if cur.nil?
      puts "<#{tag} />"
      return
    end

    loop do
      case cur.ty
      when :open
        lexs.shift
        puts "<#{tag}>"
        parse_statements(lexs)
        puts "</#{tag}>"
        raise unless lexs.shift.ty == :close 
        return
      when :nl, :semi
        puts "<#{tag} />"
        return
      else
        raise "invalid type #{ cur.ty }"
      end
    end
  else
    raise
  end
end

def parse(baml)
  lexemes = []
  lexer(baml) {|ty, value|
    l = Lexeme.new
    l.ty = ty
    l.value = value
    lexemes << l
  }

  p lexemes
  parse_statements(lexemes)
end

parse(File.read("simple.baml"))
