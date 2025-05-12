claudify() {
  # usage/help function
  usage() {
    cat <<EOF
Usage: claudify [prompt]

Re-run your previous shell command and send its output to Claude Code,
using an optional custom prompt header instead of the default.

Example:

$ pnpm build
# Oh noes, build is failing

$ claudify
# Claude will now be run, being told that the function to run was 'pnpm build', what the 
# output was, and that it should fix the issue.

Options:
  -h, --help    Show this help message and exit.

Examples:
  claudify                        # re-run last command and fix
  claudify "Explain this error:"  # pass in your own custom prompt header
EOF
  }

  # parse options
  while [[ "$1" =~ ^- ]]; do
    case "$1" in
      -h|--help)
        usage; return 0
        ;;
      *)
        echo >&2 "Unknown option: $1"; usage; return 1
        ;;
    esac
    shift
  done

  local header cmd body prompt

  # Header: custom or default
  if (( $# > 0 )); then
    header="$*"
    echo >&2 "[claudify] using custom prompt header: $header"
  else
    header="Please fix this:"
    echo >&2 "[claudify] using default prompt header"
  fi

  # Get and log last command
  cmd=$(fc -ln -1)
  echo >&2 "[claudify] grabbed last cmd: $cmd"

  # Re-run and capture output
  echo >&2 "[claudify] re-running → $cmd"
  body=$(eval "$cmd" 2>&1)
  echo >&2 "[claudify] captured output (${#body} bytes)"

  # Build prompt
  prompt="$header"$'\n\n'
  prompt+='$ '"$cmd"$'\n'
  prompt+="$body"

  # Invoke Claude Code
  echo >&2 "[claudify] invoking Claude Code now..."
  echo >&2
  echo >&2 "[Response from Claude]:"

  claude -p "$prompt" \
         --output-format stream-json \
         --allowedTools "Edit Write" \
         --debug 2> /tmp/claudify-debug.log \
    | jq -r --unbuffered 'select(.content) | .content[]? | .text? // empty'
}
