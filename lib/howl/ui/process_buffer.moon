-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import app from howl
import ActionBuffer from howl.ui
import File from howl.io
append = table.insert

command_activity = (process) ->
  {
    name: "process with pid #{process.pid}"
    is_running: -> not process.exited
    force_terminate: -> process\send_signal 'KILL'
  }

resolve_location = (base_directory, line) ->
  file, line = line\umatch r'([\\pL/.-_]+):(\\d+)'
  if file
    file = File(file, base_directory)
    return { :file , line: tonumber line } if file.exists

  nil

goto_location = (location) ->
  _, editor = app\open_file location.file
  if editor
    editor.cursor.line = location.line
    editor.line_at_center = location.line

class ProcessBuffer extends ActionBuffer
  new: (@process) =>
    super!
    @read_only = true
    @activity = command_activity @process
    @directory = @process.working_directory
    @title = "[#{@directory.short_path}]$ #{@process.command_line} (running)"

    @append '[', 'operator'
    @append tostring(@process.working_directory.short_path), 'special'
    @append ']$', 'operator'
    @append " #{@process.command_line}\n", 'string'

  insert: (object, pos, style_name) =>
    @read_only = false
    super object, pos, style_name
    @read_only = true
    @modified = false

  append: (object, style_name) =>
    @read_only = false
    editor = app\editor_for_buffer @
    at_end_of_file = editor and editor.cursor.at_end_of_file
    super object, style_name
    @read_only = true
    @modified = false
    editor.cursor\eof! if at_end_of_file

  pump: =>
    on_stdout = (read) -> @append(read) if read and not @destroyed
    on_stderr = (read) -> @append(read, 'error') if read and not @destroyed

    @process\pump on_stdout, on_stderr
    @title = "[#{@directory.short_path}]$ #{@process.command_line} (done)"

    unless @destroyed
      @append "\n=> Process terminated (#{@process.exit_status_string})", 'comment'

    editor = app\editor_for_buffer @
    editor.indicator.activity.visible = false if editor

    log_msg = "=> Command '#{@process.command_line}' terminated (#{@process.exit_status_string})"
    log[@process.exited_normally and 'info' or 'warn'] log_msg

  destroy: =>
    @process\send_signal('KILL') unless @process.exited
    super!

  keymap: {
    editor: {
      return: (editor) ->
        location = resolve_location editor.buffer.directory, editor.current_line
        if location
          goto_location(location)
        else
          log.error 'No file reference detected in the current line'
    }
  }

return ProcessBuffer
