def list_collections
  driver = ENV.fetch('VECTOR_DRIVER', 'chromadb')
  puts "Collections: (driver: #{driver})"
  puts "  - documents"
end

def search(query)
  puts "Searching for: #{query}"
  puts "  No results found (demo mode)"
end

def delete_collection(name)
  puts "Collection '#{name}' deleted"
end

puts "Semantic Search CLI"
puts "1. List collections"
puts "2. Search documents"
puts "3. Delete collection"
puts "4. Exit"
print "Choose an option: "
choice = gets.to_s.strip

case choice
when '1'
  list_collections
when '2'
  print "Search query: "
  q = gets.to_s.strip
  search(q)
when '3'
  print "Collection name: "
  name = gets.to_s.strip
  delete_collection(name)
when '4'
  puts "Goodbye!"
end