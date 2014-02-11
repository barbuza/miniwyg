$ = require \jquery2
URI = require \url
resize-image = require "./miniwyg/resize-image.ls"
get-image = require "./miniwyg/get-image.ls"
{each, flip, map} = require "prelude-ls"

foreach = flip each
delay = flip set-timeout
deffer = !(fun) -> set-timeout fun, 0

in-heading = (selector = "h1, h2, h3") ->
  parent = window.get-selection!?focus-node?.parent-node
  if parent
    node = $(parent)
    node.is(selector) or node.parents(selector).length
  else
    no

create-miniwyg = !({fontawesome}:options={}) ->
  unless @data \miniwyg

    fontawesome = @data(\miniwyg-style) == \fontawesome if typeof fontawesome is \undefined

    document.exec-command \defaultParagraphSeparator, no, \p

    miniwyg = $ require("./miniwyg/templates/miniwyg.hbs")!
    panel = $ require("./miniwyg/templates/panel.hbs")!
    image-panel = $ require("./miniwyg/templates/image-panel.hbs")!
    video-panel = $ require("./miniwyg/templates/video-panel.hbs")!
    insert-panel = $ require("./miniwyg/templates/insert-panel.hbs")!
    @data \miniwyg-panels [panel, image-panel, video-panel, insert-panel]

    $(document.body).append panel, image-panel, video-panel, insert-panel

    if fontawesome
      panel.add-class \fontawesome
      image-panel.add-class \fontawesome
      video-panel.add-class \fontawesome

    editor = miniwyg.find \.editor:first
    editor.css \min-height, @height!
    editor.html @text!

    foreach <[bold italic underline]> !(command) ->
      charcode = command.char-at(0).to-upper-case!
      btn = panel.find(".fa-#command")

      btn.mousedown ->
        if command isnt \bold or not in-heading!
          document.exec-command command, no, null
        no

      editor.keydown !(e) ->
        if command isnt \bold or not in-heading!
          if e.key-code is charcode and e.meta-key
            document.exec-command command, no, null

    foreach <[h1 h2 h3]> !(tagname) ->
      btn = panel.find("[data-tag=#tagname]")
      btn.mousedown ->
        document.exec-command \formatBlock, no, if in-heading(tagname) then \p else tagname
        no

    show-panel = !({left, top}) ->
      $(".miniwyg-panel").not(panel).remove-class \show
      panel.css {left, top}
      panel.add-class \display
      deffer !-> panel.add-class \show

    hide-panel = !-> panel.remove-class \show

    editor.mousedown !(e) -> e.stop-propagation!

    move-images = !->
      editor.find("img").each -> @contentEditable = no
      editor.find("p img").each -> $(@).parent().before @

    remove-linebreaks = !-> editor.find("> br").remove!

    remove-spans = !->
      editor.find("span").each ->
        $(@).replace-with $(@).text()

    check-selection = !->
      sel = window.get-selection!
      base-node = sel.focus-node
      if base-node
        unless $(base-node).parents("p, h1, h2, h3").length
          document.exec-command \formatBlock no \p
      if $.trim(sel.to-string!).length and sel.type != \Control
        rect = sel.get-range-at(0).get-client-rects![0]
        show-panel left: rect.left, top: (rect.top + window.scrollY)
      else
        hide-panel! if panel.has-class \show
      move-images!
      remove-linebreaks!
      remove-spans!

    paste-data = (ev) ->
      event = ev.original-event
      if event and event.clipboard-data and event.clipboard-data.getData
        text = event.clipboard-data.get-data "text/plain"
        if text.length
          lines = for let line in text.split(/(\r?\n)/g) when $.trim(line).length
            "<p>" + $.trim(line).replace(/(<([^>]+)>)/ig, '') + "</p>"
          for line in lines
            document.exec-command \InsertParagraph no null
            document.exec-command \insertHtml no line
      false

    foreach [panel, image-panel, video-panel, insert-panel] (panel) ->
      panel.on \transitionend !->
        panel.remove-class(\display) unless panel.has-class \show

    editor.bind {
      mouseup: !-> deffer check-selection
      keyup: check-selection
      keydown: check-selection
      paste: paste-data
    }

    make-insert-selection = ->
      sel = window.get-selection!
      range = document.create-range!
      range.set-start-before @
      range.set-end-before @
      sel.remove-all-ranges!
      sel.add-range range

    make-start-selection = ->
      sel = window.get-selection!
      range = document.create-range!
      range.set-start @, 0
      range.set-end @, 0
      sel.remove-all-ranges!
      sel.add-range range

    insert-image = ->
      make-insert-selection.apply @
      get-image !(img) ~>
        url = resize-image(img, 700, 300)
        document.exec-command \insertHtml no require("./miniwyg/templates/image.hbs")({url})
        make-start-selection.apply @
        deffer move-images
        deffer remove-linebreaks

    video-template = require("./miniwyg/templates/video.hbs")

    insert-video = ->
      make-insert-selection.apply @
      video-url = prompt "Ссылка на vimeo" unless video-url
      return unless video-url
      uri = URI.parse video-url, yes
      if uri.hostname is "vimeo.com"
        if /^\/\d+$/.test uri.pathname
          vimeo-id = uri.path.slice(1)
          load-vimeo-cover vimeo-id, !(img) ~>
            url = resize-image img, 700, 300, \vimeo
            document.exec-command \insertHtml no video-template({url, source: \vimeo, id: vimeo-id})
            make-start-selection.apply @
            deffer move-images
            deffer remove-linebreaks
      else if uri.hostname is "www.youtube.com" or uri.hostname is "m.youtube.com" or uri.hostname is "youtube.com"
        youtube-id = uri.query?.v
        load-youtube-cover youtube-id, !(img) ~>
          url = resize-image img, 700, 300, \youtube
          document.exec-command \insertHtml no video-template({url, source: \youtube, id: youtube-id})
          make-start-selection.apply @
          deffer move-images
          deffer remove-linebreaks

    image-loader = @data \miniwyg-image-loader

    load-vimeo-cover = !(id, cb) ->
      meta-url = "http://vimeo.com/api/v2/video/#id.json"
      $.getJSON meta-url, !([{embed_privacy, thumbnail_large}]) ->
        if embed_privacy isnt \anywhere
          alert "embeding restricted for this video"
        else
          url = "#image-loader?uri=#thumbnail_large"
          img = document.create-element \img
          img.set-attribute \crossorigin \anonymous
          img.onload = -> cb(img)
          img.src = url

    load-youtube-cover = !(id, cb) ->
      url = "#image-loader?uri=http://img.youtube.com/vi/#id/maxresdefault.jpg"
      img = document.create-element \img
      img.set-attribute \crossorigin \anonymous
      img.onload = -> cb(img)
      img.src = url

    do ->
      insert-target = null

      editor.on \mousedown "p, h1, h2, h3" !(e) ->
        if e.pageX < $(@).offset!left
          e.prevent-default!
          insert-panel.css left: $(@).offset().left - 22, top: $(@).offset().top
          insert-panel.add-class \display
          deffer -> insert-panel.add-class \show
          insert-panel.unbind(\mouseleave).mouseleave ->
            insert-panel.remove-class \show
          insert-target := @

      insert-panel.find(".fa-camera-retro").click ->
        insert-panel.remove-class \show
        insert-image.apply insert-target

      insert-panel.find(".fa-video-camera").click ->
        insert-panel.remove-class \show
        insert-video.apply insert-target

    do ->
      over-image-panel = no
      over-image = no

      image-panel.mouseenter !-> over-image-panel := yes
      image-panel.mouseleave !->
        over-image-panel := no
        deffer !->
          image-panel.remove-class \show unless over-image

      editor.on \mouseenter "img:not(.video)" !->
        over-image := yes
        img = $(@)
        image-panel.css img.offset()
        image-panel.add-class \display
        image-panel.find(".fa-eraser").unbind(\click).bind \click !-> img.remove!
        foreach <[left right center]> !(command) ->
          image-panel.find(".fa-align-#command").unbind(\click).bind \click !-> img.attr \class command
        deffer !-> image-panel.add-class \show

      editor.on \mouseleave "img:not(.video)" !->
        over-image := no
        deffer !->
          image-panel.remove-class \show unless over-image-panel

    do ->
      over-video = no
      over-video-panel = no

      video-panel.mouseenter !-> over-video-panel := yes
      video-panel.mouseleave !->
        over-video-panel := no
        deffer !->
          video-panel.remove-class \show unless over-video

      editor.on \mouseenter "img.video" !->
        over-video := yes
        video = $(@)
        video-panel.css video.offset()
        video-panel.add-class \display
        video-panel.find(".fa-eraser").unbind(\click).bind \click !-> video.remove!
        deffer !-> video-panel.add-class \show

      editor.on \mouseleave "img.video" !->
        over-video := no
        deffer !->
          video-panel.remove-class \show unless over-video-panel

    miniwyg.css \max-width, @outer-width!

    update-textarea = !~>
      @text editor.html!

    form = @parents \form:first

    unbinds = []

    bind = !(target, name, fn) ->
      $(target).bind name, fn
      unbinds.push !-> $(target).unbind(name, fn)

    bind form, \submit update-textarea
    bind document.body, \mousedown hide-panel

    miniwyg.data \unbinds unbinds
    @data \miniwyg miniwyg
    @add-class \miniwyg-hidden-textarea
    @after miniwyg

    if @data(\miniwyg-focus)
      unless editor.children().length
        editor.append document.create-element(\p)
      child = editor.children()[0]
      make-start-selection.apply child
      editor.focus!

    check-selection!

destroy-miniwyg = !->
  panels = @data \miniwyg-panels
  @data \miniwyg-panels null
  if panels
    each (.remove!), panels
  miniwyg = @data \miniwyg
  if miniwyg
    each (.apply!), miniwyg.data(\unbinds)
    @html miniwyg.find(".editor").html()
    miniwyg.remove!
    @data \miniwyg null
    @remove-class \miniwyg-hidden-textarea

$.fn.miniwyg = (command) ->
  call = switch command
  | \destroy => destroy-miniwyg
  | \fontawesome => !-> create-miniwyg {+fontawesome}
  | otherwise => create-miniwyg
  foreach @, (el) -> call.apply $(el)
  @

$.fn.miniwyg-val = ->
  miniwyg = @data \miniwyg
  miniwyg.find(\.editor:first).html! if miniwyg

$ !-> $("textarea[role=miniwyg]").miniwyg!

window.$ = $