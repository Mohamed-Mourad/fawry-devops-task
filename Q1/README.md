# fawry-devops-task
Implementation of custom grep script

## Installation

Before using the script, make sure it is executable. From the directory containing the script, run:

```bash
chmod +x mygrep.sh
```

## Overview

This repository provides a simple, case-insensitive line-search tool implemented in Bash:

- **mygrep.sh**: A straightforward utility to search for a pattern in a file, with optional line numbering (`-n`) and inverted matching (`-v`).

The script relies on `awk` for fast text processing and adhere to POSIX shell conventions.

## Options

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

## Handling Errors

The script performs the following checks and exit codes:

| Condition                                 | Exit Code |
|-------------------------------------------|-----------|
| Missing or incorrect arguments            | `1`       |
| File not found                            | `2`       |
| File not readable                         | `3`       |

Descriptive error messages are printed to `stderr`.


## Hardest Part:
For me, the most challenging part was ensuring robust and user-friendly error handling for argument parsing.
While getopts simplifies option parsing, correctly identifying what is wrong when the number of positional arguments is incorrect (e.g., distinguishing between a missing pattern versus a missing filename, like in the ./mygrep.sh -v testfile.txt case) requires careful conditional logic after getopts has run. Getting the shift amount correct and then validating $# along with checking if an argument looks like a file (-f "$1") adds complexity compared to simply processing the lines.
Also, ensuring the --help option works correctly alongside getopts requires a separate check beforehand.

## Author & License

**Author:** Mohamed Abdel Nasser Mourad &lt;moh-mourad@outlook.com&gt;

**Created:** April 28, 2025

