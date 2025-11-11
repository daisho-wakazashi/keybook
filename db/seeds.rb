puts "Clearing existing data..."
User.destroy_all

# Create sample users
puts "Creating users..."

property_manager = User.create!(
  first_name: "John",
  last_name: "Jones",
  role: :property_manager
)
puts "✓ Created property manager: #{property_manager.full_name}"

tenant = User.create!(
  first_name: "Diana",
  last_name: "Prince",
  role: :tenant
)
puts "✓ Created tenant: #{tenant.full_name}"
