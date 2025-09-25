# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting seed process..."

# Clear existing data in development environment
if Rails.env.development?
  puts "🧹 Cleaning up existing data in development..."
  Reservation.delete_all
  BookCopy.delete_all
  Book.delete_all
  User.delete_all
  
  # Reset primary key sequences
  ActiveRecord::Base.connection.reset_pk_sequence!('users')
  ActiveRecord::Base.connection.reset_pk_sequence!('books')
  ActiveRecord::Base.connection.reset_pk_sequence!('book_copies')
  ActiveRecord::Base.connection.reset_pk_sequence!('reservations')
end

# Create Librarians
puts "👤 Creating librarians..."
librarians = [
  {
    name: "Alice Johnson",
    email: "alice.johnson@library.com",
    password: "password123",
    role: :librarian,
    birthdate: Date.new(1985, 3, 15),
    address: {
      street: "123 Library Ave",
      city: "Booktown",
      zip: "12345",
      state: "Reading State"
    },
    phone_number: "+1-555-0101"
  },
  {
    name: "Bob Wilson",
    email: "bob.wilson@library.com", 
    password: "password123",
    role: :librarian,
    birthdate: Date.new(1978, 8, 22),
    address: {
      street: "456 Knowledge St",
      city: "Booktown",
      zip: "12346",
      state: "Reading State"
    },
    phone_number: "+1-555-0102"
  }
]

created_librarians = librarians.map do |librarian_attrs|
  User.find_or_create_by(email: librarian_attrs[:email]) do |user|
    user.assign_attributes(librarian_attrs)
  end
end

puts "✅ Created #{created_librarians.count} librarians"

# Create Members
puts "👥 Creating members..."
members = [
  {
    name: "John Smith",
    email: "john.smith@email.com",
    password: "password123",
    role: :member,
    birthdate: Date.new(1990, 5, 10),
    address: {
      street: "789 Reader Rd",
      city: "Booktown", 
      zip: "12347",
      state: "Reading State"
    },
    phone_number: "+1-555-0201"
  },
  {
    name: "Sarah Davis",
    email: "sarah.davis@email.com",
    password: "password123", 
    role: :member,
    birthdate: Date.new(1992, 11, 3),
    address: {
      street: "321 Novel Lane",
      city: "Booktown",
      zip: "12348", 
      state: "Reading State"
    },
    phone_number: "+1-555-0202"
  },
  {
    name: "Mike Brown",
    email: "mike.brown@email.com",
    password: "password123",
    role: :member,
    birthdate: Date.new(1988, 7, 18),
    address: {
      street: "654 Story St",
      city: "Booktown",
      zip: "12349",
      state: "Reading State"
    },
    phone_number: "+1-555-0203"
  },
  {
    name: "Emily Rodriguez",
    email: "emily.rodriguez@email.com",
    password: "password123",
    role: :member,
    birthdate: Date.new(1995, 2, 25),
    address: {
      street: "987 Chapter Ave",
      city: "Booktown", 
      zip: "12350",
      state: "Reading State"
    },
    phone_number: "+1-555-0204"
  },
  {
    name: "David Lee",
    email: "david.lee@email.com", 
    password: "password123",
    role: :member,
    birthdate: Date.new(1987, 9, 12),
    address: {
      street: "147 Prose Pkwy",
      city: "Booktown",
      zip: "12351",
      state: "Reading State"
    },
    phone_number: "+1-555-0205"
  }
]

created_members = members.map do |member_attrs|
  User.find_or_create_by(email: member_attrs[:email]) do |user|
    user.assign_attributes(member_attrs)
  end
end

puts "✅ Created #{created_members.count} members"

# Create Books
puts "📚 Creating books..."
books = [
  {
    title: "The Great Gatsby",
    author: "F. Scott Fitzgerald",
    publisher: "Scribner",
    edition: "1st Edition",
    year: 1925,
    genre: "Classic Literature",
    isbn: "978-0-7432-7356-5"
  },
  {
    title: "To Kill a Mockingbird", 
    author: "Harper Lee",
    publisher: "J.B. Lippincott & Co.",
    edition: "1st Edition",
    year: 1960,
    genre: "Classic Literature",
    isbn: "978-0-06-112008-4"
  },
  {
    title: "1984",
    author: "George Orwell",
    publisher: "Secker & Warburg", 
    edition: "1st Edition",
    year: 1949,
    genre: "Dystopian Fiction",
    isbn: "978-0-452-28423-4"
  },
  {
    title: "Pride and Prejudice",
    author: "Jane Austen",
    publisher: "T. Egerton",
    edition: "1st Edition", 
    year: 1813,
    genre: "Romance",
    isbn: "978-0-14-143951-8"
  },
  {
    title: "The Catcher in the Rye",
    author: "J.D. Salinger",
    publisher: "Little, Brown and Company",
    edition: "1st Edition",
    year: 1951,
    genre: "Coming-of-age Fiction",
    isbn: "978-0-316-76948-0"
  },
  {
    title: "Harry Potter and the Philosopher's Stone",
    author: "J.K. Rowling",
    publisher: "Bloomsbury",
    edition: "1st Edition",
    year: 1997,
    genre: "Fantasy",
    isbn: "978-0-7475-3269-9"
  },
  {
    title: "The Lord of the Rings: The Fellowship of the Ring",
    author: "J.R.R. Tolkien",
    publisher: "George Allen & Unwin",
    edition: "1st Edition",
    year: 1954,
    genre: "Fantasy",
    isbn: "978-0-547-92822-7"
  },
  {
    title: "Dune",
    author: "Frank Herbert",
    publisher: "Chilton Books",
    edition: "1st Edition",
    year: 1965,
    genre: "Science Fiction",
    isbn: "978-0-441-17271-9"
  }
]

created_books = books.map do |book_attrs|
  Book.find_or_create_by(title: book_attrs[:title], author: book_attrs[:author]) do |book|
    book.assign_attributes(book_attrs)
  end
end

puts "✅ Created #{created_books.count} books"

# Create Book Copies
puts "📖 Creating book copies..."
book_copies_data = []

created_books.each_with_index do |book, book_index|
  # Create 2-4 copies per book
  copies_count = rand(2..4)
  
  copies_count.times do |copy_index|
    book_copies_data << {
      book: book,
      book_serial_number: "#{book.title.gsub(/\s+/, '').upcase[0..5]}-#{book_index + 1}-#{copy_index + 1}-#{rand(1000..9999)}",
      available: [true, false].sample
    }
  end
end

created_book_copies = book_copies_data.map do |copy_attrs|
  BookCopy.find_or_create_by(book_serial_number: copy_attrs[:book_serial_number]) do |copy|
    copy.assign_attributes(copy_attrs)
  end
end

puts "✅ Created #{created_book_copies.count} book copies"

# Create Reservations
puts "📋 Creating reservations..."
available_members = created_members
unavailable_copies = created_book_copies.select { |copy| !copy.available? }

reservations_data = []

# Create active reservations for unavailable copies
unavailable_copies.each do |copy|
  member = available_members.sample
  created_at = rand(1..14).days.ago
  return_date = created_at + rand(7..21).days
  
  reservations_data << {
    user: member,
    book_copy: copy,
    created_at: created_at,
    return_date: return_date,
    returned_at: nil # Still active
  }
end

# Create some completed reservations
5.times do
  member = available_members.sample
  copy = created_book_copies.select(&:available).sample
  created_at = rand(30..90).days.ago
  return_date = created_at + rand(7..21).days
  returned_date = return_date - rand(0..3).days # Returned on time or early
  
  reservations_data << {
    user: member,
    book_copy: copy,
    created_at: created_at,
    return_date: return_date,
    returned_at: returned_date
  }
end

# Create some overdue reservations
3.times do
  member = available_members.sample
  copy = created_book_copies.select { |c| !c.available }.sample
  next unless copy # Skip if no unavailable copy
  
  created_at = rand(21..45).days.ago
  return_date = rand(1..7).days.ago # Overdue
  
  reservations_data << {
    user: member,
    book_copy: copy,
    created_at: created_at,
    return_date: return_date,
    returned_at: nil # Still not returned (overdue)
  }
end

created_reservations = reservations_data.map do |reservation_attrs|
  Reservation.new(reservation_attrs).save(validate: false) # Skip validations to allow past dates
end

puts "✅ Created #{created_reservations.count} reservations"

# Print summary
puts "\n📊 Seed Summary:"
puts "==================="
puts "👤 Users: #{User.count} (#{User.librarians.count} librarians, #{User.members.count} members)"
puts "📚 Books: #{Book.count}"
puts "📖 Book Copies: #{BookCopy.count} (#{BookCopy.available.count} available, #{BookCopy.unavailable.count} unavailable)"
puts "📋 Reservations: #{Reservation.count} (#{Reservation.where(returned_at: nil).count} active, #{Reservation.where.not(returned_at: nil).count} completed)"

overdue_count = Reservation.where("return_date < ? AND returned_at IS NULL", Date.current).count
puts "⚠️  Overdue Reservations: #{overdue_count}"

puts "\n🎉 Seeding completed successfully!"
puts "\n🔑 Login Credentials:"
puts "Librarian: alice.johnson@library.com / password123"
puts "Librarian: bob.wilson@library.com / password123"  
puts "Member: john.smith@email.com / password123"
puts "Member: sarah.davis@email.com / password123"
