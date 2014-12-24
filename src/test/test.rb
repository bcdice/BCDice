Dir.chdir('../')
command = "ruby -Ku test.rb #{ARGV.join(' ')}"
print command
print `#{command}`

