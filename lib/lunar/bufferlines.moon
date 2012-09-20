BufferLines = (sci) ->
  setmetatable {
      :sci

      delete: (start_line, end_line) =>
        start_pos = @pos_for start_line
        end_pos = @pos_for end_line + 1
        @sci\delete_range start_pos - 1, end_pos - start_pos

      range: (start_line, end_line) =>
        lines = {}
        for line = start_line, end_line
          append lines, self[line]
        lines

      pos_for: (line) =>
        @sci\position_from_line(line - 1) + 1

      nr_at_pos: (pos) =>
        @sci\line_from_position(pos - 1) + 1
    },
      __len: => @sci\get_line_count!

      __index: (key) =>
        if type(key) == 'number'
          return nil if key < 1 or key > #self
          text = @sci\get_line key - 1
          text\gsub '[\n\r]*$', ''

      __newindex: (key, value) =>
        if type(key) != 'number' or (key < 1) or (key > #self)
          error 'Invalid index: "' .. key .. '"'

        line = tonumber(key) - 1
        start = @sci\position_from_line line
        if value
          end_pos = @sci\get_line_end_position line
          @sci\delete_range start, end_pos - start
          @sci\insert_text start, value
        else
          end_pos = @sci\position_from_line line + 1
          @sci\delete_range start, end_pos - start

      __ipairs: =>
        iterator = (lines, index) ->
          index += 1
          text = lines[index]
          return nil if not text
          return index, text

        return iterator, self, 0

      __pairs: => ipairs self

return setmetatable {}, __call: (_, sci) -> BufferLines sci