repl do
  puts "setting up the scene"
  scene = Scenario.new
  scene.bulk_set 3, %w[
      frank has gun
      charles has treasure
      frank wants treasure
      charles has knife
  ]

  puts "testing facts"
  scene.facts.each do |k,f|
      m = f.match Pattern.new([:x, :z, :y]), {:x => "frank", :y => "treasure" }
      puts m unless !m
  end

  puts "creating conditions"
  con = scene.when(:x, "has", :y) & [:z, "wants", :y]

  puts "testing conditions"
  res = con.match(scene.facts)
  p res

  puts "inverting"
  comp = ~(scene.when(:x, "has", :y) & [:x, "wants", :y])
  res = comp.match(scene.facts)
  puts "inverse check result:"
  p res

  puts "mixing"
  mixed = scene.when(:x, "wants", :y) & (~(scene.when(:x, "has", :y)))
  res = mixed.match(scene.facts)
  puts "mixed test result:"
  p res
end