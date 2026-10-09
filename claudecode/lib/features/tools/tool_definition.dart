class ToolDefinition {
  static List<Map<String, dynamic>> get allTools => [
    {
      'type': 'function',
      'function': {
        'name': 'list_dir',
        'description': 'Lists files and folders in a directory relative to project root.',
        'parameters': {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'The relative directory path (leave empty or "." for project root).',
            },
          },
          'required': ['path'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'read_file',
        'description': 'Reads the text content of a file within the project.',
        'parameters': {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Relative path to the file to read.',
            },
            'offset_line': {
              'type': 'integer',
              'description': 'Optional 1-based start line.',
            },
            'limit_lines': {
              'type': 'integer',
              'description': 'Optional maximum number of lines to read.',
            },
          },
          'required': ['path'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'grep',
        'description': 'Searches for a text pattern or regex across files in the project.',
        'parameters': {
          'type': 'object',
          'properties': {
            'pattern': {
              'type': 'string',
              'description': 'The string or regular expression to search for.',
            },
            'path': {
              'type': 'string',
              'description': 'Optional subdirectory or file path to restrict search (defaults to project root).',
            },
          },
          'required': ['pattern'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'write_file',
        'description': 'Writes content to a file, creating it if it does not exist.',
        'parameters': {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Relative path to the file to write.',
            },
            'content': {
              'type': 'string',
              'description': 'Full content to write to the file.',
            },
          },
          'required': ['path', 'content'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'edit_file',
        'description': 'Edits a file by replacing an exact unique substring target_string with replacement_string.',
        'parameters': {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Relative path to the file to edit.',
            },
            'target_string': {
              'type': 'string',
              'description': 'The exact character sequence to replace.',
            },
            'replacement_string': {
              'type': 'string',
              'description': 'The new character sequence to insert.',
            },
          },
          'required': ['path', 'target_string', 'replacement_string'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'run_command',
        'description': 'Runs a shell command jailed inside the project working directory with live streamed output.',
        'parameters': {
          'type': 'object',
          'properties': {
            'command': {
              'type': 'string',
              'description': 'The shell command to execute (e.g. "dart test", "flutter test", "git status").',
            },
          },
          'required': ['command'],
        },
      },
    },
  ];
}
