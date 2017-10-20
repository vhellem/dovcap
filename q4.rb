def recursive(string)
  if string.length <= 1
    return string
  end
  first_char = string[0]
  last_chars = string[1..string.length]
  # MISSING
end

def merge_sorted(l1, l2)
  rtn = []
  if l1[0] < l2[0]
    rtn += l1
  end
  rtn += l2
  return rtn
end

def map(array, method)
  result_array = []
  array.each do |element|
    value = element.send(method)
    # MISSING
  end
  return result_array
end

matrix = Array.new
matrix.push([1,2,3])
matrix.push([4,5,6])
matrix.push([7,8,9])
x = matrix[0][2] + matrix[2][1]
puts x
