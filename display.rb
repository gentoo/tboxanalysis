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

require 'inifile'
require 'aws'
require 'sinatra'
require 'active_support'
require 'active_support/core_ext/object/to_query'

config = IniFile.new("./tboxanalysis.ini")
sdb = AWS::SimpleDB.new(:access_key_id => config['aws']['access_key'],
                        :secret_access_key => config['aws']['secret_key'])

domain_name = config['aws']['domain']
domain = sdb.domains[domain_name]
sdb.domains.create(domain_name) unless domain.exists?

get '/' do
  items = domain.items.
    where("matches > ?", 0).
    order(:date, :desc).
    limit(150).
    select(:all).map do |data|
    { :name         => data.name,
      :host         => (data.attributes["host"][0] rescue ""),
      :public_url   => (data.attributes["public_url"][0] rescue ""),
      :date         => (data.attributes["date"][0] rescue ""),
      :pkg          => (data.attributes["pkg"][0] rescue ""),
      :matches      => (data.attributes["matches"][0] rescue ""),
      :pkg_failed   => (data.attributes["pkg_failed"][0] == "true" rescue false),
      :test_failed  => (data.attributes["test_failed"][0] == "true" rescue false),
      :bug_template => {
        :assigned_to  => (data.attributes["bug_assignee"][0] rescue "bug-wranglers@gentoo.org"),
        :cc           => (data.attributes["bug_cc"][0] rescue ""),
        :bug_file_loc => (data.attributes["public_url"][0] rescue ""),
        :product      => "Gentoo Linux",
        :component    => "Ebuilds",
        :comment      => (File.read("emerge-infos/" + data.attributes["host"][0]) rescue ""),
        :short_desc   => ("#{data.attributes["pkg"][0]}: " rescue ""),
      }
    }
  end

  erb :index, :locals => { :items => items }
end
