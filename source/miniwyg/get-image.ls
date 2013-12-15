$ = require \jquery2

module.exports = !(cb)->
  html = $ "<input type='file'>"
  html.change ->
    if @files and @files[0]
      reader = new FileReader
      reader.onload = (e) ->
        img = document.create-element(\img)
        img.src = e.target.result
        img.onload = -> cb(img)
      reader.read-as-data-URL @files[0]
  html.click!
