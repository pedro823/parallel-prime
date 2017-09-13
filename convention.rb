# CONVENTION FOR RUBY

# Tab length: 2
# good
def function
  do_something
end
# bad
def function
    do_something
end

# No semicolons
# bad
puts 'a'; puts 'b'
puts 'c';

# Omit parentheses on void arguments
# good
def function
  do_something
end
# bad
def function()
  do_something
end

# Use space before operators
# good
a, b = 2, 3 + 5
class Example < StandardError
end
quotient = 1 / 2
# bad
a,b=2,3+5
class Example<StandardError;end
mul=1*2
# EXCEPTIONS
# exponents
e = M * c**2
# rational literals
fahrenheit_to_celsius = 9/5r + 32

# No spaces between [, ]; spaces between {, }
# good
[1, 2, 3].each { |n| puts n }
# bad
[ 1, 2, 3 ].each {|n| puts n}

# do and end, except for one-liners.
# good
(0..3).each do
  do_something
end
# bad
(0..3).each {
  do_something
}
# good
(0..3).each { do_something }

# No spaces in interpolated expressions, after '!' or between range literals
# good
 
