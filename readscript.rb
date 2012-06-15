#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright © 2012 Diego Elio Pettenò <flameeyes@flameeyes.eu>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND INTERNET SOFTWARE CONSORTIUM DISCLAIMS
# ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL INTERNET SOFTWARE
# CONSORTIUM BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
# DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
# PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
# ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
# SOFTWARE.

require 'builder'
require 'archive/tar/minitar'

match = Regexp.new("( .*\\*.* ERROR: .*failed|detected file collision|Tinderbox QA Warning!|QA Notice: (Pre-stripped|file does not exist|command not found|USE flag|Files built without respecting LDFLAGS|The following files)|linux_config_exists|will always overflow|called with bigger|maintainer mode detected|econf called in src_compile)")

Archive::Tar::Minitar::Reader.open($stdin) do |input|
  input.each do |log|
    next unless log.file?

    output = File.new(File.basename(log.name, ".log") + ".html", "w")
    output_xml = Builder::XmlMarkup.new(:indent => 2)
    output_xml.instruct!

    output.puts(output_xml.root {
                  output_xml.html {
                    output_xml.head {
                      output_xml.link(:href => "htmlgrep.css",
                                      :rel => "stylesheet",
                                      :type => "text/css")
                    }

                    output_xml.body {
                      output_xml.ol {
                        log.read.split("\n").each do |line|
                          cssclass = "match" if line =~ match

                          output_xml.li line, :class => cssclass
                        end
                      }
                    }
                  }
                })
  end
end
