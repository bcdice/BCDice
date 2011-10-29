require 'fileutils'

`ruby -Ku -r exerb/mkexy bcdice.rb exerb`
sleep 2
`call exerb  -c gui bcdice.exy`
sleep 2
FileUtils.move('bcdice.exe', '..')

