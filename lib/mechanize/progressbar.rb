require 'progressbar'
raise LoadError, "require mechanize before mechanize/progressbar" unless defined?(Mechanize)

require 'mechanize/progressbar/api'
require 'mechanize/progressbar/mechanize_progressbar'
if Mechanize::VERSION == '1.0.0'
  require 'mechanize/progressbar/mechanize_1_0'
else
  require 'mechanize/progressbar/mechanize_2_0'
end
