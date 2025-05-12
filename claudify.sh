# Place this in your ~/.bashrc or ~/.zshrc

claudify() {
  # usage/help function
  usage() {
    cat <<EOF
Usage: claudify [command]

If you provide a COMMAND, it will be re-run and its output sent to Claude Code.
Otherwise, claudify will re-run your previous shell command.

Example:

$ pnpm build
# Oh noes, build is failing

$ claudify
# Claude will now be run, being told that the function to run was 'pnpm build', what the 
# output was, and that it should fix the issue.

Options:
  -h, --help    Show this help message and exit.

Examples:
  claudify           # re-run last command and fix
  claudify npm test  # re-run 'npm test' and fix
EOF
  }

  # parse options
  while [[ "$1" =~ ^- ]]; do
    case "$1" in
      -h|--help)
        usage
        return 0
        ;;
      *)
        echo >&2 "Unknown option: $1"
        usage
        return 1
        ;;
    esac
    shift
  done

  local cmd body prompt

  # If an explicit command is given, use it
  if (( $# )); then
    cmd="$*"
    echo >&2 "[claudify] using explicit cmd: $cmd"
  else
    cmd=$(fc -ln -1)
    echo >&2 "[claudify] grabbed last cmd: $cmd"
  fi

  # Run it
  echo >&2 "[claudify] re-running → $cmd"
  body=$(eval "$cmd" 2>&1)
  echo >&2 "[claudify] captured output (${#body} bytes)"

  # Build and send the prompt
  prompt=$'Please fix this:\n\n'
  prompt+='\$ '"$cmd"$'\n'
  prompt+="$body"
  echo >&2 "[claudify] invoking Claude Code now..."
  echo >&2
  echo >&2 "[Response from Claude]:"

  claude -p "$prompt" \
         --print \
         --output-format stream-json \
         --allowedTools "Edit Write" \
         --debug 2> /tmp/claudify-debug.log \
    | jq -r --unbuffered 'select(.content) | .content[]? | .text? // empty'
}
