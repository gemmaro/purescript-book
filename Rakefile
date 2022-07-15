# frozen_string_literal: true

require 'pathname'
require 'rake/clean'

CLEAN << 'po4a.cfg'
PORT = ENV['PORT'] || 3000

task default: :watch

task :watch do
  sh <<~END_SHELL
    echo locales/ja.po | entr rake translate | logger -s -t translate &
    mdbook serve -p #{PORT} | logger -s -t serve &
    wait
  END_SHELL
end

task translate: ['po4a.cfg', 'locales/ja.po'] do |t|
  sh "po4a #{t.source}"
end

file 'po4a.cfg' do |t|
  content = <<~END_CFG
    [po_directory] locales
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
