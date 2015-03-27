-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import command, mode, interact from howl
bundle_load 'nrepl_port_input'
nrepl = bundle_load 'nrepl'
parser = bundle_load 'clojure_parser'

register_mode = ->
  mode_reg =
    name: 'clojure'
    extensions: {'clj', 'cljs', 'edn'}
    create: -> bundle_load('clojure_mode')!
    parent: 'lisp'

  mode.register mode_reg

register_commands = ->

  command.register
    name: 'nrepl-connect',
    description: 'Connects to an nrepl instance'
    interactive: true
    handler: ->
      port = interact.read_nrepl_port!
      nrepl.connect port
      log.info "Connected to nrepl at :#{port}"

  command.register
    name: 'nrepl-eval',
    description: 'Evaluates a given Clojure form'
    interactive: true
    handler: ->
      res = nrepl.eval interact.read_text!
      if res.value
        log.info "nrepl => #{res.value}"
      else
        log.error "nrepl => <error>"

register_mode!
register_commands!

unload = ->
  mode.unregister 'clojure'
  command.unregister 'nrepl-connect'
  command.unregister 'nrepl-eval'

return {
  info:
    author: 'Copyright 2013 Nils Nordman <nino at nordman.org>',
    description: 'Clojure mode',
    license: 'MIT',
  :unload
  :nrepl
  :parser
}
