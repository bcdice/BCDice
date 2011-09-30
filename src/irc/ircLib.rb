#!ruby -Ks
#--*-coding:utf-8-*--

$IRC_ENCODING='iso-2022-jp'

require 'rubygems'
require 'net/irc.rb'
require 'net/irc/client.rb'
require 'net/irc/message.rb'
require 'net/irc/message/serverconfigBcDice.rb'
require 'net/irc/message/modeparser.rb'
require 'socket.so'
require 'encode.rb'

class Net::IRC::Client
  
  # Connect to server and start loop.
  def start
    # reset config
    @server_config = Message::ServerConfig.new
    @socket = TCPSocket.open(@host, @port)
    on_connected
    post PASS, @opts.pass if @opts.pass
    post NICK, @opts.nick
    post USER, @opts.user, "0", "*", @opts.real
    
    l = nil
    while true
      begin
        while l = @socket.gets
          @log.debug "RECEIVE: #{l.chomp}"
          m = Message.parse(l)
          next if on_message(m) === true
          name = "on_#{(COMMANDS[m.command.upcase] || m.command).downcase}"
          send(name, m) if respond_to?(name)
        end
      rescue Message::InvalidMessage
        @log.error "MessageParse: " + l.inspect
      rescue Exception => e
        warn e
        warn e.backtrace.join("\r\t")
        raise
      end
    end
    
  rescue IOError
  ensure
    finish
  end
  
end



