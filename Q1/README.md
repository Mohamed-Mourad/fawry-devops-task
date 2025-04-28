# fawry-devops-task
Implementation of custom grep script

## Installation

Before using the scripts, make sure they are executable. From the directory containing the scripts, run:

```bash
chmod +x mygrep.sh mygrepstdin.sh
```

## Overview

This repository provides two simple, case-insensitive line-search tools implemented in Bash:

- **mygrep.sh**: A straightforward utility to search for a pattern in a file, with optional line numbering (`-n`) and inverted matching (`-v`).
- **mygrepstdin.sh**: Extends `mygrep.sh` by prompting the user for a filename when one is not passed on the command line.

Both scripts rely on `awk` for fast text processing and adhere to POSIX shell conventions.

## Common Options

All options can be combined in any order and apply equally to both scripts:

| Option   | Description                                                       |
|----------|-------------------------------------------------------------------|
| `-n`     | Prefix each matching (or non-matching) line with its line number. |
| `-v`     | Invert match: show lines that **do not** contain the pattern.     |
| `--help` | Display detailed usage information and exit.                      |

## mygrep.sh

**Synopsis:**
```bash
./mygrep.sh [OPTIONS] <pattern> <filename>
```

**Description:**
Searches the given `<filename>` for occurrences of `<pattern>` (case-insensitive). By default, prints only matching lines. Use `-v` to invert the match and show non-matching lines. Use `-n` to include line numbers.

**Dependencies:**
- `bash` (or another POSIX-compatible shell)
- `awk`

**Examples:**
```bash
# Basic search
./mygrep.sh hello testfile.txt

# Search with line numbers
./mygrep.sh -n error /var/log/syslog

# Inverted match (show lines without the pattern)
./mygrep.sh -v TODO TODOs.txt
```

## mygrepstdin.sh

**Synopsis:**
```bash
./mygrepstdin.sh [OPTIONS] <pattern> [filename]
```

**Description:**
Works like `mygrep.sh`, but if you omit the `filename`, the script will prompt you to enter it interactively:

```bash
$ ./mygrepstdin.sh hello
Enter filename: notes.txt
```

This is useful when you know the pattern but want to choose from multiple files on the fly.

**Dependencies:**
- `bash` (recommended, for the `read -p` prompt)
- `awk`

**Examples:**
```bash
# Prompt for filename
./mygrepstdin.sh success

# Provide filename inline
./mygrepstdin.sh -n success report.log
```

## Handling Errors

Both scripts perform the following checks and exit codes:

| Condition                                 | Exit Code |
|-------------------------------------------|-----------|
| Missing or incorrect arguments            | `1`       |
| File not found                            | `2`       |
| File not readable                         | `3`       |

Descriptive error messages are printed to `stderr`.

## Author & License

**Author:** Mohamed Abdel Nasser Mourad &lt;moh-mourad@outlook.com&gt;

**Created:** April 28, 2025

**License:** MIT (see [LICENSE](LICENSE) for details)

