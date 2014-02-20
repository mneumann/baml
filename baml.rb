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

class Parser

  def initialize(doc)
    @lexs = []
    Lexer.new(doc).each {|lexeme| @lexs << lexeme}
  end

  def parse_statements
    loop do
      cur = @lexs.first
      break unless cur
      case cur.ty
      when :nl, :semi then @lexs.shift
      when :id
        parse_statement()
      else break
      end
    end
  end

  def parse_statement()
    cur = @lexs.first || raise

    case cur.ty
    when :id 
      tag = cur.value
      @lexs.shift
      cur = @lexs.first

      if cur.nil?
        puts "<#{tag} />"
        return
      end

      loop do
        case cur.ty
        when :open
          @lexs.shift
          puts "<#{tag}>"
          parse_statements()
          puts "</#{tag}>"
          raise unless @lexs.shift.ty == :close 
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

  def parse
    parse_statements()
  end
end

Parser.new(File.read("simple.baml")).parse
