Dir.chdir('./test')
command = "ruby.exe -Ku testCard.rb #{ARGV.join(' ')}"
print command
print `#{command}`
