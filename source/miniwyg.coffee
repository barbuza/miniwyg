
deffer = (fun) -> setTimeout fun, 0


create_miniwyg = (options={}) ->
  unless @data "miniwyg"

    document.execCommand "defaultParagraphSeparator", no, "p"

    miniwyg = jQuery """
      <div class="miniwyg">
        <div class="panel"></div>
        <div class="editor" contenteditable spellcheck="false"></div>
      </div>
    """

    panel = miniwyg.find ".panel:first"
    if options.fontawesome
      panel.addClass "fontawesome"

    editor = miniwyg.find ".editor:first"
    editor.css "min-height", @height()
    editor.html @text()

    for command in ["bold", "italic", "underline"]
      do (command) ->
        tagname = command.charAt 0
        btn = if options.fontawesome
          jQuery "<span class='icon-#{command}'></span>"
        else
          jQuery "<#{tagname}>#{tagname}</#{tagname}>"
        panel.append btn
        charcode = tagname.toUpperCase().charCodeAt 0
        btn.mousedown -> document.execCommand command, no, null
        editor.keydown (e) ->
          if e.keyCode is charcode and e.metaKey
            document.execCommand command, no, null

    show_panel = ->
      panel.addClass "display"
      deffer -> panel.addClass "show"

    hide_panel = -> panel.removeClass "show"

    jQuery(document.body).mousedown hide_panel

    editor.mousedown (e) -> e.stopPropagation()

    check_selection = (e) ->
      if jQuery.trim(window.getSelection().toString()).length
        show_panel()
      else
        hide_panel()

    panel.on "transitionend", (e) ->
      panel.removeClass("display") unless panel.hasClass "show"

    editor.mouseup -> deffer check_selection
    editor.keyup check_selection
    editor.keydown check_selection

    miniwyg.css "max-width", @outerWidth()

    update_textarea = => @text editor.html()

    form = @parents "form:first"
    form.submit update_textarea

    bound = []
    bind = (target, name, fn) ->
      

    miniwyg.data "unbind", [
      {target: form, args: ["submit", update_textarea]}
      {target: jQuery(document.body), args: ["mousedown", hide_panel]}
    ]

    @data "miniwyg", miniwyg
    @addClass "miniwyg_hidden_textarea"
    @after miniwyg


destroy_miniwyg = ->
  miniwyg = @data "miniwyg"
  if miniwyg
    for {target, args} in miniwyg.data "unbind"
      target.unbind.apply target, args
    miniwyg.remove()
    @data "miniwyg", null
    @removeClass "miniwyg_hidden_textarea"


jQuery.fn.miniwyg = (command) ->
  {fn, args} = switch command
    when "destroy"
      {fn: destroy_miniwyg}
    when "fontawesome"
      {fn: create_miniwyg, args: [fontawesome: yes]}
    else
      {fn: create_miniwyg}
  fn.apply(jQuery(el), args or []) for el in @
  @


jQuery ($) ->
  $("textarea[role=miniwyg]").miniwyg()
  $("textarea[role=miniwyg_fontawesome]").miniwyg("fontawesome")
