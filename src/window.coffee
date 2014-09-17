saveChanges = ->
  config = {}
  $('input,select').each ->
    key = $(this).attr('data-key')
    config[key] = this.value
  chrome.storage.sync.set config, ->
    console.log('config saved.');
  restartServer(config)
  false

load = ->
  config = {}
  $('input,select').each ->
    key = $(this).attr('data-key')
    config[key] = this.value
  chrome.storage.sync.get config, (data)->
    $('input,select').each ->
      key = $(this).attr('data-key')
      this.value = data[key] or ''
    restartServer(data)

restartServer = (config)->
  if config.server and +config.server_port and config.password and +config.local_port
    if window.local?
      window.local.close()
    window.local = new Local(config)
    $('#divError').hide()
  else
    $('#divError').show()

$('#buttonSave').on('click', saveChanges)
load()