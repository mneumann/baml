#
# Copyright (c) 2014 by Michael Neumann
#
# An experimental Baml implementation
#

class Lexeme
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

  def render(level=0)
    print(" " * level*2)
    print("<#{@name}")
    @attrs.each {|id, arr|
      print %{ #{id}="#{arr.map(&:to_s).join(' ')}"}
    }
    if @elements
      puts ">"
      @elements.each {|elm| elm.render(level+1)}
      print(" " * level*2)
      puts "</#{@name}>"
    else
      puts " />"
    end
  end
end

class Lexer
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

        yield Lexeme.new(:id, id)
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

        yield Lexeme.new(:dstr, str)

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

        yield Lexeme.new(:str, str)

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

        yield Lexeme.new(:eval, str)

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
        yield Lexeme.new(:html, html)

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

        yield Lexeme.new(ty, html)

      when ' ', "\t", "\r"     # ignore whitespace
      when "\n" then yield Lexeme.new(:nl) # new line
      when '{'  then yield Lexeme.new(:open)
      when '}'  then yield Lexeme.new(:close)
      when ';'  then yield Lexeme.new(:semi)
      when '.'  then yield Lexeme.new(:dot)
      when '#'  then yield Lexeme.new(:hash)
      when '='  then yield Lexeme.new(:assign)

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

  def render(level)
    print(" " * level*2)
    puts(self.to_s)
  end
end

class Document
  attr_accessor :elements
  def initialize(elements)
    @elements = elements
  end
  def render
    @elements.each {|elm| elm.render}
  end
end

class Parser
  def initialize(doc)
    @lexs = []
    Lexer.new(doc).each {|lexeme| @lexs << lexeme}
  end

  def parse_statements
    elements = []
    loop do
      cur = @lexs.first
      break unless cur
      case cur.ty
      when :nl, :semi then @lexs.shift
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
    cur = @lexs.first || raise
    case cur.ty
    when :dot
      @lexs.shift
      cur = @lexs.first || raise(".class expected")
      case cur.ty
      when :id
        @lexs.shift
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
    cur = @lexs.first || raise
    case cur.ty
    when :hash
      @lexs.shift
      cur = @lexs.first || raise("#id expected")
      case cur.ty
      when :id
        @lexs.shift
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
    cur = @lexs.first || (return nil)

    case cur.ty
    when :dot
      ["class", AttrValue.new(parse_css_class())]
    when :hash
      ["id", AttrValue.new(parse_elem_id())]
    when :id 
      name = cur.value
      @lexs.shift
      cur = @lexs.first || raise("= expected")
      case cur.ty
      when :assign
        @lexs.shift
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
    cur = @lexs.first || raise("expr expected")
    case cur.ty
    when :dstr, :str, :eval # they all are expressions
      @lexs.shift
      return Expr.new(cur)
    else 
      raise("expr expected")
    end
  end

  # parse a complete tag definition
  def parse_tag
    tag = Tag.new
    cur = @lexs.first || raise

    case cur.ty
    when :dot
      tag.name = "div"
      tag.add_attr("class", parse_css_class())
    when :hash
      tag.name = "div"
      tag.add_attr("id", parse_elem_id())
    when :id 
      tag.name = cur.value
      @lexs.shift
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

    cur = @lexs.first || (return tag)

    case cur.ty
    when :open
      @lexs.shift
      tag.elements = parse_statements()
      cur = @lexs.shift || raise
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

require 'pp'
parse_tree = Parser.new(File.read("simple.baml")).parse
pp parse_tree
parse_tree.render
