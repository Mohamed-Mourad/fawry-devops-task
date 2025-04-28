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


## Reflective Section

### 1. Breakdown of Argument and Option Handling

1. **`--help` detection**  
   - Before any other parsing, the script loops over `"$@"` to check for the `--help` flag.  
   - If found, it immediately calls the `usage()` function and exits, ensuring help text is shown even if other options are malformed.

2. **Short-option parsing with `getopts`**  
   - Uses `getopts` with the optstring `:nv` so that:
     - `-n` sets `show_lines=1` (include line numbers).
     - `-v` sets `invert_match=1` (invert the match).  
   - An invalid option triggers the `\?` case, which prints an error and exits.

3. **Shifting processed options**  
   - After `getopts` completes, the script runs  
     ```bash
     shift $((OPTIND - 1))
     ```  
   - This removes all parsed flags from `$@`, leaving only the positional arguments (`<pattern>` and `<filename>`).

4. **Validating positional arguments**  
   - Expects exactly two arguments after shifting.  
   - If only one remains and it’s a file (`-f "$1"`), it reports “Search pattern is missing.”  
   - If only one remains and it isn’t a file, it reports “Filename is missing.”  
   - Any other count triggers a generic “Incorrect number of arguments” error.

5. **File existence and readability checks**  
   - Tests `[ -f "$filename" ]`; exits code `2` if the file is missing.  
   - Tests `[ -r "$filename" ]`; exits code `3` if the file is not readable.  

---

### 2. How the Structure Would Change for Regex, `-i`, `-c`, and `-l` Support

1. **Extend the `getopts` optstring**  
   - Change from `:nv` to something like `:nvicl` to parse:
     - `-i` → `ignore_case`
     - `-c` → `count_only`
     - `-l` → `list_files`

2. **Support long options via GNU `getopt`**  
   - Use `getopt` (or Bash’s enhanced `getopts`) to handle flags like `--ignore-case`, `--count`, and `--files-with-matches`.  
   - After parsing, run `eval set -- "$parsed_opts"` so the main loop can treat long and short options uniformly.

3. **Switch core matching to regex**  
   - In the `awk` block, replace the substring check  
     ```awk
     is_match = (index(lc_line, lc_pattern) > 0)
     ```  
     with a regex test:  
     ```awk
     is_match = (lc_line ~ lc_pattern)
     ```  
   - This enables full regular-expression support.

4. **Implement `-i` (ignore case)**  
   - Add an `ignore_case` flag.  
   - If set, either skip all `tolower()` conversions and rely on `IGNORECASE=1` in GNU awk, or always lower-case both pattern and line.

5. **Implement `-c` (count matches)**  
   - With `count_only` enabled, increment a counter for each match.  
   - In `END {}`, print only the total count instead of individual lines.

6. **Implement `-l` (list filenames only)**  
   - When `list_files` is true, print the filename and `exit 0` on the first match to avoid duplicate listings—mirroring `grep -l`.

---

**Usage Examples After Extension**  
```bash
# Case-insensitive regex search with count
./mygrep.sh -i -c 'error [0-9]+' logfile.txt

# List filenames containing “TODO”
./mygrep.sh --files-with-matches TODO *.md
```

### 3. Hardest Part:

For me, the most challenging part was ensuring robust and user-friendly error handling for argument parsing.
While getopts simplifies option parsing, correctly identifying what is wrong when the number of positional arguments is incorrect (e.g., distinguishing between a missing pattern versus a missing filename, like in the ./mygrep.sh -v testfile.txt case) requires careful conditional logic after getopts has run. Getting the shift amount correct and then validating $# along with checking if an argument looks like a file (-f "$1") adds complexity compared to simply processing the lines.
Also, ensuring the --help option works correctly alongside getopts requires a separate check beforehand.

## Author & License

**Author:** Mohamed Abdel Nasser Mourad - moh-mourad@outlook.com

**Created:** April 28, 2025

