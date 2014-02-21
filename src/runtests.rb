$LOAD_PATH.unshift './src'

require 'baml'

def tidy(html)
  IO.popen('tidy -q --show-warnings no --show-errors 0', "r+") { |io|
    io.write(html)
    io.close_write
    io.read
  }
end

Dir["test/*.baml"].each {|fbaml|
  fhtml = fbaml[0, fbaml.size - 5] + '.html'
  raise unless File.file?(fbaml) or File.file?(fhtml)

  Parser.new(File.read(fbaml)).parse.render(baml_str="")

  baml_tidy = tidy(baml_str)
  html_tidy = tidy(File.read(fhtml))

  if baml_tidy == html_tidy
    puts "[ok]     #{fbaml}"
  else
    puts "[failed] #{fbaml}"
  end
}
