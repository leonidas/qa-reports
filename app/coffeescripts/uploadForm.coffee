$(document).ready ->
  testSetSuggestions = []
  productSuggestions = []

  updateProductSuggestions = (data) ->
    productSuggestions = data
    $("#report_test_product").autocomplete(source: productSuggestions)
    activateSuggestionLinks("div.field")

  updateTestSetSuggestions = (data) ->
    testSetSuggestions = data
    $("#report_test_type").autocomplete(source: testSetSuggestions)
    activateSuggestionLinks("div.field")

  product_url = window.location.pathname.replace("upload","product")
  testtype_url = window.location.pathname.replace("upload","testset")
  $.get(product_url, updateProductSuggestions)
  $.get(testtype_url, updateTestSetSuggestions)

  $(".date").datepicker(
    showOn: "both",
    buttonImage: "/images/calendar_icon.png",
    buttonImageOnly: true,
    firstDay: 1,
    selectOtherMonths: true,
    dateFormat: "yy-mm-dd"
  )

  myDate = new Date()
  prettyDate = myDate.getUTCFullYear() + '-' + (myDate.getUTCMonth()+1) + '-' + myDate.getUTCDate()
  $(".date").val(prettyDate)

  uploader = new qq.FileUploaderBasic
    button: $('#upload_button')[0]
    element: $('#drag_drop_area')[0]
    action: '/upload_report/'
    debug: false
    onSubmit: (id, fileName) ->
      $('#upload_button').removeClass('draghover')
      $('.field.last').removeClass('draghover')
      $('form input[type=submit]').attr('disabled', 'true')
      $fal = $("#file_attachment_list")
      $fal.append($('<li id="file_upload'+id+'"><a class="remove_list_item">Remove</a>'+fileName+'<img src="/images/progress.gif" /> <span id="file_upload' + id + 'ProgressBar"></span></li>'))
      $this_element = $fal.children().last()
      $this_element.click ->
        uploader._handler.cancel(id);
        $this_element.remove();

    onProgress: (id, fileName, loaded, total) ->
      $('#file_upload' + id + 'ProgressBar').text((loaded/total*100).toFixed(0) + "%")
    onComplete: (id, fileName, response) ->
      $('#file_upload' + id).remove()
      $("#uploaded_list").append('<li><input type="checkbox" name="drag_n_drop_attachments[]" value="' + response.attachment_id + '" checked="true">' + fileName + '</li>')
      if uploader._handler.getQueue().length == 1
        $('form input[type=submit]').removeAttr('disabled')

  dragenter = (event) ->
    $('#upload_button').addClass('draghover')
    $('.field.last').addClass('draghover')
    false

  dragleave = (event) ->
    $('#upload_button').removeClass('draghover')
    $('.field.last').removeClass('draghover')
    false

  dragDrop = (event) ->
    if event.preventDefault
      event.preventDefault()
    console.log event.originalEvent.dataTransfer.files
    uploader._uploadFileList(event.originalEvent.dataTransfer.files)
    false

  $('.field.last').bind('dragenter', dragenter)
                  .bind('dragover', dragenter)
                  .bind('dragleave', dragleave)
                  .bind('drop', dragDrop)
