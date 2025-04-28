#!/bin/bash
# -----------------------------------------------------------------------------
# mygrepstdin.sh – A simple, case-insensitive search tool with line-numbering
#                  and prompts for filename if not provided.
#
# Synopsis:
#   mygrepstdin.sh [-n] [-v] [--help] <pattern> [filename]
#
# Description:
#   Searches for PATTERN in FILENAME.
#   - If FILENAME is omitted, the script prompts the user to enter it.
#   - Case-insensitive by default.
#   - Use -n to prefix each matching line with its line number.
#   - Use -v to invert match (show non-matching lines).
#   - Use --help for usage information.
#
# Dependencies:
#   - awk
#   - POSIX-compatible shell (bash recommended for read -p)
#
# Examples:
#   ./mygrepstdin.sh hello testfile.txt
#   ./mygrepstdin.sh -n hello testfile.txt
#   ./mygrepstdin.sh -vn hello testfile.txt
#   ./mygrepstdin.sh -v testfile.txt
#
# Author:   Mohamed Abdel Nasser Mourad - moh-mourad@outlook.com
# Created:  2025-04-28
# -----------------------------------------------------------------------------

# Default values for options
show_lines=0     # Flag for -n option
invert_match=0   # Flag for -v option
pattern=""
filename=""

# --- Usage Function ---
# Prints help message and exits
usage() {
  echo "Usage: $0 [-n] [-v] [--help] <pattern> [filename]"
  echo "Search for PATTERN in FILENAME."
  echo "If FILENAME is omitted, you will be prompted to enter it."
  echo ""
  echo "Options:"
  echo "  -n         Prefix each line of output with the 1-based line number."
  echo "  -v         Invert the sense of matching, to select non-matching lines."
  echo "  --help     Display this help message and exit."
  exit 1
}

# --- Option Parsing ---
# Handle --help separately first
for arg in "$@"; do
  if [[ "$arg" == "--help" ]]; then
    usage
  fi
done

# Use getopts for short options (-n, -v)
# Leading ':' enables silent error handling for invalid options
while getopts ":nv" opt; do
  case ${opt} in
    n )
      show_lines=1
      ;;
    v )
      invert_match=1
      ;;
    \? ) # Handle invalid options
      echo "Error: Invalid option: -$OPTARG" >&2
      echo "Use --help to display usage information." >&2
      exit 1
      ;;
  esac
done
# Shift positional parameters to remove processed options
shift $((OPTIND -1))

# --- Argument Validation ---
# Expecting 1 (pattern) or 2 (pattern, filename) arguments now
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Error: Incorrect number of arguments." >&2
  echo "Use --help to display usage information." >&2
  exit 1
fi

# Assign pattern
pattern="$1"

# Check if filename was provided as the second argument
if [ "$#" -eq 2 ]; then
  filename="$2"
else
  read -r -p "Enter filename: " filename
  if [ -z "$filename" ]; then
    echo "Error: No filename entered." >&2
    exit 1
  fi
fi

# --- File Validation ---
# Check if the specified file exists and is readable
if [ ! -f "$filename" ]; then
  echo "Error: File '$filename' not found." >&2
  exit 2
fi

if [ ! -r "$filename" ]; then
  echo "Error: File '$filename' is not readable." >&2
  exit 3
fi


# --- Core Logic using awk ---
# Pass shell variables to awk using the -v option.
awk -v pattern="$pattern" -v show_lines="$show_lines" -v invert_match="$invert_match" '
BEGIN {
    lc_pattern = tolower(pattern)
}

{
    lc_line = tolower($0)

    is_match = (index(lc_line, lc_pattern) > 0)

    should_print = 0 # Default is not to print.
    if (invert_match == 0) {
        if (is_match) {
            should_print = 1
        }
    } else {
        if (!is_match) {
            should_print = 1
        }
    }

    if (should_print) {
        if (show_lines == 1) {
            print NR ":" $0
        } else {
            print $0
        }
    }
}
' "$filename" 

exit 0

