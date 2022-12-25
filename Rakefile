# frozen_string_literal: true

require 'pathname'
require 'rake/clean'

CLEAN << 'po4a.cfg'

task default: %i[po4a_version start]

PROC_RUNNER = ENV['PROC_RUNNER'] || 'foreman'

task :start do
  sh "#{PROC_RUNNER} start"
end

task :watch do
  sh 'echo translation/ja.po | entr rake translate'
end

task :serve do
  sh 'mdbook serve'
end

task translate: ['po4a.cfg', 'translation/ja.po'] do |t|
  sh "po4a #{t.source}"
end

task :po4a_version do
  sh 'po4a --version > .po4a-version'
end

file 'po4a.cfg' => __FILE__ do |t|
  content = <<~END_CFG
    [po_directory] translation
    [options] --master-charset UTF-8 \\
       --localized-charset UTF-8 \\
       --addendum-charset UTF-8 \\
       --master-language en
    [type:text] README.md $lang:text/index.$lang.md \\
       add_$lang:translation/$lang.add opt:"--option markdown --keep 0"
  END_CFG

  Pathname.glob('text/chapter*.md').reject { _1.to_s.match?(/.ja.md\Z/) }.each do |doc|
    adds = []
    adds << 'add_$lang:translation/ja/chapter3-0.add' if doc.basename.to_s.match?(/chapter3.md/)
    content += <<~END_CFG
      [type:text] #{doc} $lang:#{doc.sub_ext('.$lang.md')} \\
                  #{adds.join(' ')} opt:"--option markdown --keep 0"
    END_CFG
  end

  File.write(t.name, content)
end
