require "boilpot.rb"

def quick_reset
  $gtk.reset
  $gtk.console.animation_duration = 0
end

quick_reset

def tick args
  if(args.state.tick_count == 0)
    args.state.session_tick = 0
    args.state.debug_messages = []
    $gtk.console.animation_duration = 0
  end
  if(args.state.session_tick == 0)
    args.state.geopol_script = $gtk.read_file "example/geopolitics.boil"
    args.state.scenario = Boilpot.parse args.state.geopol_script
    args.state.scenario.prerun
    args.state.scenario.seek
    args.state.scenario.log.each_with_index do |logline,i|
      puts "#{i}: #{logline}"
    end
  end
  args.state.session_tick += 1
  debug_display args
end

def debug_log message

  $args.state.debug_messages << message

end

def debug_display args

  max_messages = 35
  message_height = 20
  
  if(args.state.debug_messages.length > max_messages)
    message_offset = -max_messages
  else
    message_offset = 0
  end
  
  line_offset = 0
  
  args.state.debug_messages[message_offset,max_messages].each do |message|
    args.outputs.labels << [ 10, 720-line_offset, message ]
    line_offset += message_height
  end
end