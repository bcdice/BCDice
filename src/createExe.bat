ruby -Ku -r exerb/mkexy bcdice.rb exerb
ping -n 2 localhost >NUL
call exerb  -c gui bcdice.exy
move /Y bcdice.exe ..