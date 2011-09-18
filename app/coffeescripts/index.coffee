url2id = (url) ->
  url.replace(/\//g,'-').replace(/\s/g,'_')

directives =
  profiles:
    'name@href':    -> @url
    'name@id':      -> url2id(@url)
    testsets:
      'name@href':  -> @url
      'name@id':    -> url2id(@url)
      products:
       'name@href': -> @url
       'name@id':   -> url2id(@url)

$('#report_navigation').render index_model, directives

$('#report_navigation tbody a.name').each () ->
  input_id = 'input-' + $(this).attr('id')
  $form = $(this).next('form')
  $i = $('<input>').addClass('inplace-edit')
    .attr('name', 'category_edit_input').attr('id', input_id)
    .val($(this).text())
  $form.find('.editables').append($i)

$('#home_edit_link').click () ->
  $('#index_page').addClass 'editing'
  $('#index_page.editing #report_navigation tbody a.name').addClass('editable_text').css 'display', 'block'
  $('a.compare').hide()

$('#home_edit_done_link').click () ->
  $('#index_page').removeClass 'editing'
  $('#report_navigation tbody a.name').removeClass 'editable_text'
  $('#report_navigation tbody a.name').css 'display', 'inline'
  $('a.compare').show()

# In-place edit
$editables = null
$('#index_page.editing #report_navigation tbody a.name').live 'click', () ->
  $clicked = $(this)
  $clicked.hide()
  $clicked.next('form').show().find('input.inplace-edit').focus()

  # set editables for real-time update to similar products
  $editables = $('.products a').not($clicked).filter () ->
    return $(this).text() == $clicked.text()
  $editables.addClass 'being_edited'
  return false

# Real-time update to similar products
$('.products input.inplace-edit').keyup () ->
  $editables.text $(this).val()

# Canceling the edit
$('#report_navigation input.inplace-edit').blur () ->
  $form = $(this).closest('form')
  $form.hide()
  $link = $form.prev('a.name').show()
  $(this).val $link.text() # revert back to orig val after cancel
  $editables.text $link.text() # revert text in similar products
  $editables.removeClass 'being_edited'
  $editables = null
  return false

$('#report_navigation input.inplace-edit').keyup (key) ->
  $(this).trigger('blur') if (key.keyCode == 27) # esc triggers cancel

# Hover hilight for products
$('#index_page.editing .products a').live 'mouseover', () ->
  if $editables == null
    product_name = $(this).text()
    $('#index_page.editing .products a').filter(() ->
      return $(this).text() == product_name
    ).addClass('to_be_edited')

$('#index_page.editing .products a').live 'mouseout', () ->
  $('#index_page.editing .products a').removeClass('to_be_edited')
