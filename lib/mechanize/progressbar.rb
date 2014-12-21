require 'progressbar'
raise LoadError, "require mechanize before mechanize/progressbar" unless defined?(Mechanize)

require 'mechanize/progressbar/api'
require 'mechanize/progressbar/mechanize_progressbar'
require 'mechanize/progressbar/mechanize'
require 'mechanize/progressbar/version'

