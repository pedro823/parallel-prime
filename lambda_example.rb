lambda_set = {
  :a => -> name {
    p " I'm method 'a'. name = #{name}"
  },
  :b => -> name {
    p " I'm method 'b'. name = #{name}"
  },
  :c => -> name {
    p " I'm method 'c'. name = #{name}"
  }
}

my_lambda_set = {}
[:a, :b, :c, :d].each do |i|
  my_lambda_set[i] = lambda_set[i] || -> input { p "no operation with #{input}"}
end

my_lambda_set.each do |key, i|
  i.("Test")
end
