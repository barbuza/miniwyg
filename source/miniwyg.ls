$ = require \jquery-browserify
URI = require \url
resize-image = require "./resize-image.ls"
get-image = require "./get-image.ls"

deffer = !(fun) -> set-timeout fun, 0

create-miniwyg = !({fontawesome}:options={}) ->
  unless @data \miniwyg

    fontawesome = @data(\miniwyg-style) == \fontawesome if typeof fontawesome is \undefined

    document.exec-command \defaultParagraphSeparator, no, \p

    miniwyg = $ """
      <div class="miniwyg">
        <div class="editor" contenteditable spellcheck="false"></div>
        <div class="bottom"></div>
      </div>
    """

    panel = $ """
      <div class="miniwyg-panel"></div>
    """

    image-panel = $ """
      <div class="miniwyg-panel miniwyg-panel-image">
        <span class="fa fa-align-left"></span>
        <span class="fa fa-align-center"></span>
        <span class="fa fa-align-right"></span>
        <span class="fa fa-eraser"></span>
      </div>
    """

    video-panel = $ """
      <div class="miniwyg-panel miniwyg-panel-video">
        <span class="fa fa-eraser"></span>
      </div>      
    """

    insert-panel = $ """
      <div class="miniwyg-insert-popup">
        <span class="fa fa-camera-retro"></span>
        <span class="fa fa-video-camera"></span>
      </div>
    """

    $(document.body).append panel, image-panel, video-panel, insert-panel

    if fontawesome
      panel.add-class \fontawesome
      image-panel.add-class \fontawesome
      video-panel.add-class \fontawesome

    editor = miniwyg.find \.editor:first
    editor.css \min-height, @height!
    editor.html @text!

    in-heading = (selector = "h1, h2, h3") ->
      parent = window.get-selection!?focus-node?.parent-node
      if parent
        node = $(parent)
        node.is(selector) or node.parents(selector).length
      else
        no

    $.each <[bold italic underline]> !(_, command) ->
      tagname = command.char-at 0
      btn = if fontawesome
        $ "<span class='fa fa-#command'></span>"
      else
        $ "<#tagname>#tagname</#tagname>"
      panel.append btn
      charcode = tagname.to-upper-case!char-code-at 0
      btn.mousedown ->
        if command isnt \bold or not in-heading!
          document.exec-command command, no, null
        no
      editor.keydown !(e) ->
        if command isnt \bold or not in-heading!
          if e.key-code is charcode and e.meta-key
            document.exec-command command, no, null

    $.each <[h1 h2 h3]> !(_, tagname) ->
      btn = $ "<span>#tagname</span>"
      panel.append btn
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
        show-panel left: rect.left, top: rect.top
      else
        hide-panel! if panel.has-class \show
      move-images!
      remove-linebreaks!
      remove-spans!

    $.each [panel, image-panel, video-panel, insert-panel] (_, panel) ->

      panel.on \transitionend !->
        panel.remove-class(\display) unless panel.has-class \show

    editor.bind {
      mouseup: !-> deffer check-selection
      keyup: check-selection
      keydown: check-selection
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
        document.exec-command \insertHtml no "<img class='center' src='#url'>"
        make-start-selection.apply @
        deffer move-images
        deffer remove-linebreaks

    insert-video = ->
      make-insert-selection.apply @
      video-url = prompt "Ссылка на youtube или vimeo" unless video-url
      return unless video-url
      uri = URI.parse video-url, yes
      if uri.hostname is "vimeo.com"
        if /^\/\d+$/.test uri.pathname
          vimeo-id = uri.path.slice(1)
          load-vimeo-cover vimeo-id, !(img) ~>
            url = resize-image img, 700, 300, \vimeo
            document.exec-command \insertHtml no "<img class='video' src='#url' data-source='vimeo' data-id='#vimeo-id'>"
            make-start-selection.apply @
            deffer move-images
            deffer remove-linebreaks
      else if uri.hostname is "www.youtube.com" or uri.hostname is "m.youtube.com" or uri.hostname is "youtube.com"
        youtube-id = uri.query?.v
        load-youtube-cover youtube-id, !(img) ~>
          url = resize-image img, 700, 300, \youtube
          document.exec-command \insertHtml no "<img class='video' src='#url' data-source='youtube' data-id='#youtube-id'>"
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
        $.each <[left right center]> !(_, command) ->
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
        video-panel.css $(@).offset()
        video-panel.add-class \display
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
      unbinds.push !-> $(target).unbind name, fn

    bind form, \submit update-textarea
    bind document.body, \mousedown hide-panel

    miniwyg.data \unbinds, unbinds
    @data \miniwyg, miniwyg
    @add-class \miniwyg-hidden-textarea
    @after miniwyg

    if @data(\miniwyg-focus)
      if editor.children()
        child = editor.children()[0]
        sel = window.get-selection!
        sel.remove-all-ranges!
        range = document.create-range!
        range.set-start child, 0
        range.set-end child, 0
        sel.add-range range
      editor.focus!

    check-selection!


destroy-miniwyg = !->
  miniwyg = @data \miniwyg
  if miniwyg
    $.each miniwyg.data(\unbinds), !(_, fn) -> fn!
    miniwyg.remove!
    @data \miniwyg, null
    @remove-class \miniwyg-hidden-textarea

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
