# frozen_string_literal: true

require 'pathname'
require 'rake/clean'

CLEAN << 'po4a.cfg'
PORT = ENV['PORT'] || 3456

task default: %i[po4a_version foreman_version start]

task :start do
  sh 'foreman start'
end

task :watch do
  sh 'echo locales/ja.po | entr rake translate'
end

task :serve do
  sh "mdbook serve -p #{PORT}"
end

task translate: ['po4a.cfg', 'locales/ja.po'] do |t|
  sh "po4a #{t.source}"
end

task :po4a_version do
  sh 'po4a --version > .po4a-version'
end

file 'po4a.cfg' => __FILE__ do |t|
  content = <<~END_CFG
    [po_directory] locales
    [options] --master-charset UTF-8 \\
       --localized-charset UTF-8 \\
       --addendum-charset UTF-8 \\
       --master-language en
  END_CFG

  Pathname.glob('text/chapter*.md').reject { _1.to_s.match?(/.ja.md\Z/) }.each do |doc|
    adds = ['add_$lang:locales/$lang.add']
    adds << 'add_$lang:locales/ja/chapter3-0.add' if doc.basename.to_s.match?(/chapter3.md/)
    content += <<~END_CFG
      [type:text] #{doc} $lang:#{doc.sub_ext('.$lang.md')} \\
                  #{adds.join(' ')} opt:"--option markdown --keep 0"
    END_CFG
  end

  File.write(t.name, content)
end

task :foreman_version do
  sh 'foreman --version > .foreman-version'
end
