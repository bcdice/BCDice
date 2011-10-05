#--*-coding:utf-8-*--

$isDebug = false

def debug(obj1, *obj2)
  return unless( $isDebug )
  
  unless( obj1.is_a?(String) )
    obj1 = obj1.inspect
  end

  if( obj2.empty? )
    debugPrint("#{obj1}\n".tosjis)
    return
  end
  
  obj2 = getTextFromLogTarget(obj2)
  
  debugPrint("#{obj1} : #{obj2}\n".tosjis)
end

def debugPrint(text)
  print(text)
end

def getTextFromLogTarget(target)
  return target.inspect if( target.nil? )
  
  list = target.collect do |i|
    if( i.is_a?(String) )
      '"' + i + '"'
      #print(i + "\n")
    else
      i.inspect
    end
  end
  
  return list.join(", ")
end





