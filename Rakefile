# frozen_string_literal: true

require 'pathname'

task default: :translate

task translate: ['po4a.cfg', 'locales/ja.po'] do |t|
  sh "po4a #{t.source}"
end

file 'po4a.cfg' do |t|
  content = <<~END_CFG
    [po_directory] locales
  END_CFG

  Pathname.glob('text/chapter*.md').reject { _1.to_s.match?(/.ja.md\Z/) }.each do |doc|
    content += <<~END_CFG

      [type:text] \\
        #{doc} \\
        $lang:#{doc.sub_ext(".$lang.md")} \\
        add_$lang:locales/$lang.add \\
        opt:"--option markdown --keep 0"
    END_CFG
  end

  File.write(t.name, content)
end

require 'rake/clean'

CLEAN << 'po4a.cfg'
