#
# Copyright (c) 2014 by Michael Neumann
#
# An experimental Baml implementation
#

class Token
  attr_accessor :ty, :value
  def initialize(ty, value=nil)
    @ty, @value = ty, value
  end

  def inspect
    if value
      "#{ty}(#{value.inspect})"
    else
      "#{ty}"
    end
  end
end

class Tag
  attr_accessor :name
  attr_accessor :elements

  def add_attr(name, value)
    (@attrs[name] ||= []) << value
  end

  def initialize(name=nil)
    @name = name
    @attrs = {}
    @elements = nil 
  end

  def render(io, level=0)
    io << (" " * level*2)
    io << "<#{@name}"
    @attrs.each {|id, arr|
      io << %{ #{id}="#{arr.map(&:to_s).join(' ')}"}
    }
    if @elements
      io << ">\n"
      @elements.each {|elm| elm.render(io, level+1)}
      io << (" " * level*2)
      io << "</#{@name}>"
    else
      io << " />"
    end
    io << "\n"
  end
end

class Tokenizer
  def initialize(doc)
    @doc = doc
  end

  def each
    iter = @doc.each_char
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

        yield Token.new(:id, id)
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

        yield Token.new(:dstr, str)

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

        yield Token.new(:str, str)

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

        yield Token.new(:eval, str)

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
        yield Token.new(:html, html)

      when ':', "\\", '%', '!'
        ty = case ch
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

        yield Token.new(ty, html)

      when ' ', "\t", "\r"     # ignore whitespace
      when "\n" then yield Token.new(:nl) # new line
      when '{'  then yield Token.new(:open)
      when '}'  then yield Token.new(:close)
      when ';'  then yield Token.new(:semi)
      when '.'  then yield Token.new(:dot)
      when '#'  then yield Token.new(:hash)
      when '='  then yield Token.new(:assign)

      else
        raise "invalid character: #{ch}"
      end

      ch = iter.next
    end
  end
end

class AttrValue
  def initialize(value)
    @value = value
  end

  # XXX
  def to_s
    case @value
    when String
      @value
    when Expr
      @value.to_s
    else
      raise
    end
  end
end

class Expr
  def initialize(lex)
    @lex = lex
  end
  def to_s
    @lex.value
  end

  def render(io, level)
    io << (" " * level*2)
    io << self.to_s
  end
end

class Document
  attr_accessor :elements
  def initialize(elements)
    @elements = elements
  end
  def render(io)
    @elements.each {|elm| elm.render(io)}
  end
end

class Parser
  def initialize(doc)
    @tokens = []
    Tokenizer.new(doc).each {|token| @tokens << token}
  end

  def parse_statements
    elements = []
    loop do
      cur = @tokens.first
      break unless cur
      case cur.ty
      when :nl, :semi then @tokens.shift
      when :id, :dot, :hash
        elements << parse_tag()
      else break
      end
    end
    elements
  end

  #
  # parses .myclass
  #
  def parse_css_class
    cur = @tokens.first || raise
    case cur.ty
    when :dot
      @tokens.shift
      cur = @tokens.first || raise(".class expected")
      case cur.ty
      when :id
        @tokens.shift
        return cur.value
      else
        raise "id expected"
      end
    else
      raise
    end
  end

  #
  # parses #myid
  #
  def parse_elem_id
    cur = @tokens.first || raise
    case cur.ty
    when :hash
      @tokens.shift
      cur = @tokens.first || raise("#id expected")
      case cur.ty
      when :id
        @tokens.shift
        return cur.value
      else
        raise "id expected"
      end
    else
      raise
    end
  end

  # Tries to parse a key=value
  def try_parse_attr
    cur = @tokens.first || (return nil)

    case cur.ty
    when :dot
      ["class", AttrValue.new(parse_css_class())]
    when :hash
      ["id", AttrValue.new(parse_elem_id())]
    when :id 
      name = cur.value
      @tokens.shift
      cur = @tokens.first || raise("= expected")
      case cur.ty
      when :assign
        @tokens.shift
        expr = parse_expr()
        return [name, AttrValue.new(parse_expr())]
      else
        raise "= expected"
      end
    else
      return nil
    end
  end

  def parse_expr
    cur = @tokens.first || raise("expr expected")
    case cur.ty
    when :dstr, :str, :eval # they all are expressions
      @tokens.shift
      return Expr.new(cur)
    else 
      raise("expr expected")
    end
  end

  # parse a complete tag definition
  def parse_tag
    tag = Tag.new
    cur = @tokens.first || raise

    case cur.ty
    when :dot
      tag.name = "div"
      tag.add_attr("class", parse_css_class())
    when :hash
      tag.name = "div"
      tag.add_attr("id", parse_elem_id())
    when :id 
      tag.name = cur.value
      @tokens.shift
    else
      raise
    end

    # parse all attributes
    loop do
      if attr = try_parse_attr()
        tag.add_attr(*attr)
      else
        break
      end
    end

    cur = @tokens.first || (return tag)

    case cur.ty
    when :open
      @tokens.shift
      tag.elements = parse_statements()
      cur = @tokens.shift || raise
      raise unless cur.ty == :close
    when :dstr, :str, :eval
      tag.elements = [parse_expr()]
    when :nl, :semi
      # ok
    else
      raise "invalid type #{ cur.ty }"
    end

    return tag
  end

  def parse
    doc = Document.new(parse_statements())
  end
end

if __FILE__ == $0
  require 'pp'
  parse_tree = Parser.new(File.read("simple.baml")).parse
  pp parse_tree
  parse_tree.render(STDOUT)
end
