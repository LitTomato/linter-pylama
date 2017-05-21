{ exec, parse } = require 'atom-linter'
path = require 'path'

packagePath = path.dirname(__dirname)
regex =
  '(?<file_>.+):' +
  '(?<line>\\d+):' +
  '(?<col>\\d+):' +
  '\\s+' +
  '(((?<type>[ECDFINRW])(?<file>\\d+)(:\\s+|\\s+))|(.*?))' +
  '(?<message>.+)'

module.exports = {
  paths: {
    isort: path.join packagePath, 'bin', 'isort.py'
    pylama: path.join packagePath, 'bin', 'pylama.py'
  }


  initEnv: (filePath, projectPath) ->
    pythonPath = []

    pythonPath.push filePath if filePath
    pythonPath.push projectPath if projectPath and projectPath not in pythonPath

    env = Object.create process.env
    if env.PWD
      pwd = path.normalize env.PWD
      pythonPath.push pwd if pwd and pwd not in pythonPath

    env.PYLAMA = pythonPath.join path.delimiter
    env


  lintFile: (lintInfo, textEditor) ->
    exec(lintInfo.command, lintInfo.args, lintInfo.options).then (output) ->
      atom.notifications.addWarning output['stderr'] if output['stderr']
      console.log output['stdout'] if do atom.inDevMode
      parse(output['stdout'], regex).map (message) ->
        linter_msg = {}

        if message.type
          linter_msg.severity = if message.type in ['E', 'F'] then 'error' else 'warning'
        else
          linter_msg.severity = 'info'

        code = message.filePath or ''
        code = "#{message.type}#{code}" if message.type
        linter_msg.excerpt = if code then "#{code} #{message.text}" else "#{message.text}"

        line = message.range[0][0]
        col = message.range[0][1]
        editorLine = textEditor.buffer.lines[line]
        if not editorLine or not editorLine.length
          colEnd = 0
        else
          colEnd = editorLine.indexOf ' ', col + 1
          if colEnd == -1
            colEnd = editorLine.length
          else
            colEnd = 3 if colEnd - col < 3
            colEnd = if colEnd < editorLine.length then colEnd else editorLine.length

        linter_msg.location = {
          file: lintInfo.fileName
          position: [
            [line, col]
            [line, colEnd]
          ]
        }
        linter_msg
}