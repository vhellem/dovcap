' Utility class copied from http://www.aspemporium.com/codelib.aspx?pid=123&cid=12 

class ArrayList
	private arr()

	private sub class_initialize()
	end sub

	'adds an item to the ArrayList having any datatype. replaces push
	public function Add(ByVal item)
		dim arrlen
		arrlen = Length
		redim preserve arr(arrlen+1)

		if isobject(item) then
			set arr(ubound(arr)) = item
		else
			arr(ubound(arr)) = item
		end if

		Add = ubound(arr)
	end function

	'gets the length (ubound) of the internal array or -1 if the array is empty.
	public property get Length
		dim arrlen

		on error resume next
		arrlen = ubound(arr)
		if err then
			Length = -1
			exit property
		end if

		Length = arrlen
	end property

	'gets the 0 based count of items in the ArrayList
	public property get Count
		Count = Length + 1
	end property

	'gets the internal array wrapped by the ArrayList
	public function ToArray()
		Toarray = arr
	end function

	'removes an item from the ArrayList by its index
	public sub RemoveAt(byval idx)
		Dim hIdx

		hIdx = CLng(idx)

		if length = -1 then err.raise 9 'subscript out of range
		if hIdx > length or hIdx < 0 then err.raise 9 'subscript out of range

		dim newLen, i, j
		dim newarr()

		if length = 0 and hIdx = 0 then
			redim arr(-1)
			'arr = newarr
			exit sub
		end if

		newLen = length - 1
		redim newarr(newLen)

		j = 0
		for i = 0 to length
			if hIdx <> i then
				if isobject(arr(i)) then
					set newarr(j) = arr(i)
				else
					newarr(j) = arr(i)
				end if
				
				j = j + 1
			end if
		next

		redim arr(ubound(newarr))

		for i = 0 to length
			if isobject(newarr(i)) then
				set arr(i) = newarr(i)
			else
				arr(i) = newarr(i)
			end if
		next
	end sub

	'determines if an item exists in this ArrayList. if the item to check 
	'is an object, Contains always returns false. items within the arraylist
	'are compared to the item argument using vbscript's StrComp function set
	'to a textual comparison (not case sensitive).
	public function Contains(byval item)
		if isobject(item) then
			Contains = false
			exit function
		end if

		dim arrEle

		for each arrEle in arr
			if StrComp(arrEle, item, 1) = 0 then
				Contains = true
				Exit Function
			end if
		next

		contains = false
	end function

	'gets an item from the ArrayList by its index within the internal array
	public property get Item(byval idx) 
		Dim hIdx

		hIdx = CLng(idx)

		if length = -1 then err.raise 9 'subscript out of range
		if hIdx > length or hIdx < 0 then err.raise 9 'subscript out of range

		if isobject(arr(hIdx)) then
			set item = arr(hIdx)
		else
			item = arr(hIdx)
		end if
	end property

	'sets an item in the arraylist by its index within the internal array
	public property let Item(byval idx, byval newvalue)
		Dim hIdx

		hIdx = CLng(idx)

		if length = -1 then err.raise 9 'subscript out of range
		if hIdx > length or hIdx < 0 then err.raise 9 'subscript out of range

		if isobject(arr(hIdx)) then
			set arr(hIdx) = newvalue
		else
			arr(hIdx) = newvalue
		end if
	end property

	'adds the contents of an array to the ArrayList.
	public sub AddRange(byval arrlist)
		if isempty(arrlist) then err.raise 5 'invalid arg
		if isnull(arrlist) then err.raise 5 'invalid arg
		if not isarray(arrlist) then err.raise 13 'type mismatch

		dim i

		for i = lbound(arrlist) to ubound(arrlist)
			Add arrlist(i)
		next
	end sub

	'empties the ArrayList
	public sub Clear()
		redim arr(-1)
	end sub

	'trims the arraylist to a certain number of items
	public sub TrimToCount(byval len)
		dim hLen

		hLen = CLng(len)

		if hLen > length then err.raise 5 'invalid arg
		if hLen < 1 then err.raise 5 'invalid arg

		redim preserve arr(hLen - 1)
	end sub

	'reverses the elements of the internal array in the arraylist
	public sub Reverse()
		dim i, ubnd
		dim newarray()

		ubnd = length
		redim newarray(ubnd)

		for i = 0 to ubnd
			if isobject(arr(i)) then
				set newarray(ubnd - i) = arr(i)
			else
				newarray(ubnd - i) = arr(i)
			end if
		next

		Clear

		AddRange newarray
	end sub

	'copies a chunk of the array to a new array from a specified start ordinal.
	'replaces Slice
	public function CopyTo(byval start)
		copyto = CopyToEx(start, length - start + 1)
	end function

	'copies a chunk of the array to a new array from a specified start ordinal
	'having a specific length. replaces Slice
	public function CopyToEx(byval start, byval count)
		dim hLen, hStart

		hLen = CLng(count)
		hStart = CLng(start)

		if hStart > length or hStart < 0 then err.raise 5 'invalid arg
		if hLen > length + 1 or hLen < 1 then err.raise 5 'invalid arg

		dim i, j
		dim newarray()
		redim newarray(hLen-1)
		j = 0
		for i = hStart to hStart + hLen - 1
			if isobject(arr(i)) then
				set newarray(j) = arr(i)
			else
				newarray(j) = arr(i)
			end if
			j = j + 1
		next

		CopyToEx = newarray
	end function

	'sorts string arrays A to Z and number arrays low to high and combination number/string arrays
	'as low to high numbers followed by A to Z strings
	public sub Sort()
		dim front, back, loc, temp, arrsize

		arrsize = ubound(arr)
		for front = 0 to arrsize - 1
			loc = front
			for back = front to arrsize
				if isnumeric(arr(loc)) and isnumeric(arr(back)) then
					if cdbl(arr(loc)) > cdbl(arr(back)) then
						loc = back
					end if
				else
					if arr(loc) > arr(back) then
						loc = back
					end if
				end if
			next
			temp = arr(loc)
			arr(loc) = arr(front)
			arr(front) = temp
		next
	end sub

	'inserts an item to the front of the arraylist and
	'pushes all existing entries back one. replaces unshift
	public sub Insert(byval item)
		if isarray(item) then err.raise 13 'type mismatch

		insertrange array(item)
	end sub

	'inserts the elements of a given array to the front of the arraylist and
	'pushes all existing entries back. replaces unshift
	public sub InsertRange(byval arrlist)
		 ' returns an array with the specified 
		 ' elements added to the beginning of
		 ' the original array

		if not isarray(arrlist) then err.raise 13 'type mismatch

		dim tmp, i, newarray()
		dim j
		tmp = arrlist
		redim newarray(length + ubound(tmp) + 1)
		j = ubound(tmp) + 1
		for i = 0 to length
			if isobject(arr(i)) then
				set newarray(j + i) = arr(i)
			else
				newarray(j + i) = arr(i)
			end if
		next
		for i = 0 to ubound(tmp)
			if isobject(arr(i)) then
				set newarray(i) = trim(tmp(i))
			else
				newarray(i) = trim(tmp(i))
			end if
		next
		
		Clear

		AddRange newarray
	end sub

	public function Pop()
		 ' returns the last value in the 
		 ' array and removes it from the 
		 ' array, shortening the array
		 ' by one element

		pop = arr(length)
		redim preserve arr(length - 1)
	end function

	public function Shift()
		 ' removes the first element of an array
		 ' and displays it. Shifts every other element
		 ' down one element and shortens the array by 
		 ' 1 element.

		dim i
		shift = arr(lbound(arr))
		for i = 1 to length
			arr(i - 1) = arr(i)
		next
		redim preserve arr(length - 1)
	end function

	'determines if this arraylist has duplicated elements in it
	public function ContainsDuplicates()
		dim i, j
		for i = 0 to length
			for j = 0 to length
				if j <> i then
					if StrComp(arr(i), arr(j), 1) = 0 then
						ContainsDuplicates = true
						exit function
					end if
				end if
			next
		next

		ContainsDuplicates = false
	end function

	'removes duplicated elements from the arraylist
	public sub RemoveDuplicates()
		if not ContainsDuplicates then exit sub

		dim i, j, item1, item2
		for i = length to 0 step -1

			item1 = arr(i)

			for j = length to 0 step -1

				item2 = arr(j)

				if j <> i then
					if StrComp(item1, item2, 1) = 0 then
						removeat i
					end if
				end if
			next
		next
	end sub

	'gets the highest number value in the array
	Public Function Highest
		Dim i, last, num, newarr

		last = null

		newarr = ToNumberArray
		for i = 0 to ubound(newarr)
			num = cdbl(newarr(i))
			if isnull(last) then
				last = num
			elseif num > CDbl(last) then 
				last = num
			end if
		next

		Highest = last
	End Function

	'gets the lowest number value in the array
	Public Function Lowest
		Dim i, last, num, newarr

		last = null

		newarr = ToNumberArray
		for i = 0 to ubound(newarr)
			num = cdbl(newarr(i))
			if isnull(last) then
				last = num
			elseif num < CDbl(last) then 
				last = num
			end if
		next

		Lowest = last
	End Function

	'add up the total of all numbers in the array
	Public Function Sum
		dim newarr, i, num, t

		t = 0

		newarr = ToNumberArray
		for i = 0 to ubound(newarr)
			num = cdbl(newarr(i))
			t = t + num
		next

		Sum = t
	End Function

	 ' average the values
	public function Mean
		Mean = sum/count
	end function

	' get the range
	public function Range
		Range = highest - lowest
	end function

	'middle number of sorted number array
	Public Function Median
		Dim newarr, ct, avg

		newarr = tonumberarray

		dim arrList

		set arrList = new ArrayList
		arrList.addRange newarr
		arrList.Sort
		newarr = arrList.ToArray
		set arrList = nothing

		ct = ubound(newarr)

		if isodd(ct) then
			avg = ct/2
			median = (newarr(floor(avg)) + newarr(ceiling(avg))) / 2
		else
			median = newarr(ct/2)
		end if
	End Function

Function Ceiling(byval n)
	Dim iTmp, bErr, f

	on error resume next
	n = cdbl(n)
	if err then bErr = true
	on error goto 0

	if bErr then Err.Raise 5000, "Ceiling Function", _
		"Input must be convertible to a sub-type of double"

	f = Floor(n)
	if f = n then
		Ceiling = n
		Exit Function
	End If

	Ceiling = cInt(f + 1)
End Function

Function Floor(byval n)
	Dim iTmp, bErr

	on error resume next
	n = cdbl(n)
	if err then bErr = true
	on error goto 0

	if bErr then Err.Raise 5000, "Floor Function", _
		"Input must be convertible to a sub-type of double"

	'Round() rounds up
	iTmp = Round(n)

	'test rounded value against the non rounded value
	'if greater, subtract 1
	if iTmp > n then iTmp = iTmp - 1

	Floor = cInt(iTmp)
End Function

	function iswhole(byval n)
		dim i
		i = cdbl(n)
		iswhole = (cdbl(round(i)) = i)
	end function

	function isodd(byval n)
		isodd = cbool(cdbl(n) mod 2)
	end function

	'returns only numeric (convertible to double) elements
	Public Function ToNumberArray()
		Dim i, num, j

		j = -1
		for i = 0 to length
			on error resume next
			num = CDBl(arr(i))
			if err.number = 0 then j = j + 1
			on error goto 0
		next

		redim newarr(j)

		j = 0
		for i = 0 to length
			on error resume next
			num = CDBl(arr(i))
			if err.number = 0 then
				newarr(j) = num
				j = j + 1
			end if
			on error goto 0
		next

		ToNumberArray = newarr
	End Function
end class
