{print} = require 'util'
{spawn} = require 'child_process'

build = (use_watch) ->
  os = require 'os'
  if os.platform() == 'win32'
    coffeeCmd = 'coffee.cmd'
  else
    coffeeCmd = 'coffee'
  if use_watch
    coffee = spawn coffeeCmd, ['-c', '-b', '-w', '-o', 'lib', 'src']
  else
    coffee = spawn coffeeCmd, ['-c', '-b', '-o', 'lib', 'src']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write do data.toString
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    if code != 0
      process.exit code


task 'build', 'Build to lib/ from src/', ->
  do build


task 'watch', 'Watch changes in lib/ and compile to src/', ->
  build true