Dir.chdir('../test')
command = "ruby.exe -Ku test.rb #{ARGV.join(' ')}"
print command
print `#{command}`

