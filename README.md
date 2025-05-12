# claudify

> Uses Claude Code to automatically fix whatever shell command you last ran

`claudify` is a simple shell function that re-runs the last command you typed (or one you specify) and sends its output to the Claude Code CLI for automated fixes.

---

## 📚 Example

```bash
# 1) Run any command that produces output:
pnpm test path/to/failing.test.ts

# 2) Then simply:
claudify
```

This will re-run the last command you typed and send its output to Claude Code for automated fixes.

It's as if you:

1. Ran the command
2. Copied the command and its output onto your clipboard
3. Opened Claude Code and pasted it into the prompt
4. Hit enter

It just does it all for you.

---

## 🔍 Features

- **Re-run & capture** your last interactive command (Bash, Zsh, Fish)
- **Optional explicit command** override: `claudify npm test`
- **Wrap** output in a “Please fix this:” prompt including the original command
- **Invoke** the Claude Code CLI in streaming mode (`--output-format stream-json`)
- **Allow file edits** via `--allowedTools "Edit Write"`
- **Built-in help** with `-h` or `--help`
- **Debug logs** written to `/tmp/claudify-debug.log`

---

## ⚙️ Prerequisites

- **Claude Code CLI** installed and on your `$PATH`:
  ```bash
  npm install -g @anthropic-ai/claude
  ```
- **jq** for JSON filtering:
  ```bash
  # macOS / Linuxbrew
  brew install jq

  # Debian / Ubuntu
  sudo apt-get install -y jq

  # Windows (Chocolatey)
  choco install jq -y
  ```
- **Bash**, **Zsh**, or **Fish** for interactive history support

---

## 🚀 Installation

Simply copy the `claudify()` function below into your shell initialization file:

- **Bash**: `~/.bashrc` or `~/.bash_profile`
- **Zsh**:  `~/.zshrc`
- **Fish**: add to `~/.config/fish/config.fish`

```bash
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

```

After adding, reload your shell:
```bash
source ~/.bashrc    # or ~/.zshrc, or start a new session
```

You’re ready to run `claudify`!

### Bonus: Aliasing and customization

If `claudify` is too many characters, you can alias it to `fix`:

```bash
alias fix="claudify"
```

Usage:

```bash
# Some command that fails and you want Claude Code to fix it
pnpm test path/to/failing.test.ts

fix
```

Sometimes I find myself telling Claude Code the same things over and over again. You can customize the default prompt header by passing in your own custom header:

```bash
alias fixtest="claudify 'Explain this error:'"
```

Now if you want Claude Code to fix a failing tests without telling it all that stuff each time:

```bash
pnpm test path/to/failing.test.ts
fixtest
```

---

## 💡 Usage

```bash
# 1) Run any command that produces output:
pnpm test path/to/failing.test.ts

# 2) Then simply:
claudify
```

You can also override:
```bash
claudify npm run lint
```

View help at any time:
```bash
claudify --help
```

---

## 🐛 Debugging

If you need to inspect the debug logs:
```bash
less /tmp/claudify-debug.log
```

---

## 🤝 Contributing

1. Fork this repo
2. Branch off (`git checkout -b feature/xyz`)
3. Update your shell function or docs
4. Submit a PR with clear descriptions

---

## 📄 License

MIT © Ed Spencer
