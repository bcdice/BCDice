Dir.chdir('./test')
command = "ruby.exe -Ku testPointer.rb #{ARGV.join(' ')}"
print command
print `#{command}`
