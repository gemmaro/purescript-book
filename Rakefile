# frozen_string_literal: true

task default: :translate

task translate: 'po4a.cfg' do |t|
  sh "po4a #{t.source}"
end

file 'po4a.cfg' do |t|
  content = <<~END_CFG
    [po_directory] locales
  END_CFG

  Dir['text/chapter*.md'].each do |doc|
    content += <<~END_CFG

      [type:text] \\
        #{doc} \\
        $lang:locales/$lang/#{doc} \\
        opt:"--option markdown --keep 0" \\
        add_$lang:locales/$lang/translators.add
    END_CFG
  end

  File.write(t.name, content)
end

require 'rake/clean'

CLEAN << 'po4a.cfg'
