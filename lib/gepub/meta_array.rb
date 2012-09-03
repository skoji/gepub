class Array
  def sort_as_meta
    i = 0
    sort_by {
        |v|
        seq = v.display_seq
        [ seq && seq.to_s.to_i || 2 ** (0.size * 8 - 2) - 1, i += 1]
    }
  end
end