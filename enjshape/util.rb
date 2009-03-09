def strip_duplicates(points)
  if points.size() > 2
    i = 0
    while i < points.size() - 1
      if points[i] == points[i+1]
        #ignoring z because it should be flattened
        points.delete_at(i)
        i -= 1
      end
      i += 1
    end
  end
  return points
  
end