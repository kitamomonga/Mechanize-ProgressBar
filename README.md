## mechanize-progressbar

Mechanize-Progressbar provides ProgressBar when you use Mechanize#get/Page#click.
HTTP response only. HTTP requests are not supported.

## How it works

    require 'mechanize'
    require 'mechanize/progressbar'
    agent = Mechanize.new
    agent.progressbar{ agent.get(large_file) }

output: 

    http://host/large_file.zip
    15%  |ooooooo                        | 135.2KB  21.9KB/s ETA:  00:00:10

## Requirements

- Ruby 1.9 or later
- recent Rubygems
- Mechanize gem (> 2.5)
- ProgressBar gem

## USAGE

Get file in Mechanize#progressbar block.

    require 'mechanize'
    require 'mechanize/progressbar'
    agent = Mechanize.new
    agent.progressbar{ agent.get(large_file) }

Link#click also works.

    agent = Mechanize.new
    agent.get(some_page)
    agent.progressbar do
      agent.page.link_with(:text => 'download here').click
    end

## Configure ProgressBar

If you want to modify the ProgressBar object, set options to argument.

    pbar = ProgressBar.new(@title, @total, @out)
    pbar.format = @format
    pbar.format_arguments = @format_arguments

is

    agent = Mechanize.new
    agent.progressbar(
      :title => @title,
      :total => @total,
      :out => @out,
      :format => @format,
      :format_arguments => @format_arguments
    ){ agent.get(large_file) }

Mechanize-Progressbar prints the URL to $stderr before progressbar.

    agent.progressbar{ agent.get(large_file) }

output:

    http://uri.host/large_file.zip
    15% |ooooo                           | 135.2KB  21.9KB/s ETA:  00:00:10

If you do not want the "two-line mode", set (:single => true).

    agent.progressbar(:single => true){ agent.get(large_file) }

output:

    uri.host:   15% |ooo                 | 135.2KB  21.9KB/s ETA:  00:00:10

When Mechanize Logger output is same to ProgressBar (i.e, agent.log=Logger.new($stderr)),
Mechanize::ProgressBar stops showing socket read log.

    agent.log = Logger.new($stderr)
    agent.progressbar{ agent.get(large_file) }

output:

    http://uri.host/large_file.zip
    100% |ooooooooooooooooooooooooooooooo| 1024.0KB  21.9KB/s Time:  00:00:20
    D, [...] DEBUG -- : Read 102400 bytes


## LARGE FILE DOWNLOAD NOTE
Mechanize keeps all the got files as String object.
When you get the five 100MB files, Mechanize uses at least 500MB memory.

If you wish to run Mechanize with minimum memory usage, try
    agent.max_history = 1


## Licence

MIT

alike Mechanize.

## Author

kitamomonga  
kitamomonga@gmail.com  
http://d.hatena.ne.jp/kitamomonga/ (Japanese)