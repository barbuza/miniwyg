$ = jQuery

deffer = !(fun) -> set-timeout fun, 0


create-miniwyg = !({fontawesome}:options={}) ->
  unless @data \miniwyg

    fontawesome = @attr(\miniwyg-style) == \fontawesome if typeof fontawesome is \undefined

    document.exec-command \defaultParagraphSeparator, no, \p

    miniwyg = $ """
      <div class="miniwyg">
        <div class="panel"></div>
        <div class="editor" contenteditable spellcheck="false"></div>
      </div>
    """

    panel = miniwyg.find \.panel:first
    if fontawesome
      panel.add-class \fontawesome

    editor = miniwyg.find \.editor:first
    editor.css \min-height, @height!
    editor.html @text!

    $.each <[bold italic underline]>, !(_, command) ->
      tagname = command.char-at 0
      btn = if fontawesome
        $ "<span class='icon-#command'></span>"
      else
        $ "<#tagname>#tagname</#tagname>"
      panel.append btn
      charcode = tagname.to-upper-case!char-code-at 0
      btn.mousedown !-> document.exec-command command, no, null
      editor.keydown !(e) ->
        if e.key-code is charcode and e.meta-key
          document.exec-command command, no, null

    show-panel = !->
      panel.add-class \display
      deffer !-> panel.add-class \show

    hide-panel = !-> panel.remove-class \show

    editor.mousedown !(e) -> e.stop-propagation!

    check-selection = !(e) ->
      if $.trim(window.get-selection!to-string!).length
        show-panel!
      else
        hide-panel!

    panel.on \transitionend, !(e) ->
      panel.remove-class(\display) unless panel.has-class \show

    editor.bind {
      mouseup: !-> deffer check-selection
      keyup: check-selection
      keydown: check-selection
    }

    miniwyg.css \max-width, @outer-width!

    update-textarea = => @text editor.html!

    form = @parents \form:first
    form.submit update-textarea

    unbinds = []

    bind = !(target, name, fn) ->
      $(target).bind name, fn
      unbinds.push !-> $(target).unbind name, fn

    bind form, \submit, update-textarea
    bind document.body, \mousedown, hide-panel

    miniwyg.data \unbinds, unbinds
    @data \miniwyg, miniwyg
    @add-class \miniwyg_hidden_textarea
    @after miniwyg


destroy-miniwyg = !->
  miniwyg = @data \miniwyg
  if miniwyg
    $.each miniwyg.data(\unbinds), !(_, fn) -> fn!
    miniwyg.remove!
    @data \miniwyg, null
    @remove-class \miniwyg_hidden_textarea


$.fn.miniwyg = (command) ->
  call = switch command
  | \destroy => destroy-miniwyg
  | \fontawesome => !-> create-miniwyg {+fontawesome}
  | otherwise => create-miniwyg
  @each !(_, el) -> call.apply $(el)
  @


$.fn.miniwyg-val = ->
  miniwyg = @data \miniwyg
  miniwyg.find(\.editor:first).html! if miniwyg


$ !-> $("textarea[role=miniwyg]").miniwyg!
