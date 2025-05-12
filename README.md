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
  usage() {
    cat <<EOF
Usage: claudify [command]

If you provide a COMMAND, it will be re-run and its output sent to Claude Code.
Otherwise, claudify will re-run your previous shell command.

Options:
  -h, --help    Show this help message and exit.

Examples:
  claudify           # re-run last command and fix
  claudify npm test  # re-run 'npm test' and fix
EOF
  }

  # parse flags
  while [[ "$1" == -* ]]; do
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

  local cmd body prompt

  # explicit override
  if (( $# )); then
    cmd="$*"
    echo >&2 "[claudify] using explicit cmd: $cmd"
  else
    # detect shell and fetch last command
    if [[ -n "$ZSH_VERSION" ]]; then
      cmd=$(fc -ln -1)
    elif which fish >/dev/null 2>&1 && echo "$SHELL" | grep -qi fish; then
      cmd=$(history | head -n2 | tail -n1)
    else
      cmd=$(fc -ln -2)
    fi
    echo >&2 "[claudify] grabbed last cmd: $cmd"
  fi

  # run and capture output
  echo >&2 "[claudify] re-running → $cmd"
  body=$(eval "$cmd" 2>&1)
  echo >&2 "[claudify] captured output (${#body} bytes)"

  # build prompt
  prompt=$'Please fix this:\n\n'
  prompt+='\$ '"$cmd"$'\n'
  prompt+="$body"

  echo >&2 "[claudify] invoking Claude Code now..."
  echo >&2

  claude -p "$prompt" \
         --print \
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

### Bonus: `fix` alias

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
