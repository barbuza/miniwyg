resize-canvas = null
resize-ctx = null

module.exports = (img, max-width, max-height, video-overlay) ->
  unless resize-ctx
    resize-canvas := document.create-element \canvas
    resize-ctx := resize-canvas.get-context \2d
  width = img.width
  height = img.height
  if width > height
    if width > max-width
      height *= max-width / width
      width = max-width
    if height > max-height
      width *= max-height / height
      height = max-height
  else
    if height > max-height
      width *= max-height / height
      height = max-height
    if width > max-width
      height *= max-width / width
      width = max-width
  resize-canvas.width = width
  resize-canvas.height = height
  resize-ctx.draw-image(img, 0, 0, width, height)
  if video-overlay
    resize-ctx.fill-style = \white
    resize-ctx.font = "48px FontAwesome"
    if video-overlay is \youtube
      resize-ctx.fill-text "\uf16a", 10, 45
    else if video-overlay is \vimeo
      resize-ctx.fill-text "\uf194", 10, 45
  resize-canvas.to-data-URL("image/jpeg", 0.85)
