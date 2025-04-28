#!/bin/bash
# -----------------------------------------------------------------------------
# mygrep.sh  –  A simple, case-insensitive search tool with line-numbering
#
# Synopsis:
#   mygrep.sh [-n] [-v] <pattern> [filename]
#
# Description:
#   Searches for PATTERN in FILENAME (or stdin, if FILENAME is omitted).
#   - Case-insensitive by default.
#   - Use -n to prefix each matching line with its line number.
#   - Use -v to invert match (show non-matching lines).
#
# Dependencies:
#   - awk
#   - POSIX-compatible shell (bash, dash, etc.)
#
# Examples:
#   ./mygrep.sh hello testfile.txt
#   ./mygrep.sh -n hello testfile.txt
#   ./mygrep.sh -vn hello testfile.txt
#   ./mygrep.sh -v testfile.txt
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
  echo "Usage: $0 [-n] [-v] [--help] <pattern> <filename>"
  echo "Search for PATTERN in FILENAME."
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
# Check if the correct number of non-option arguments remain
if [ "$#" -ne 2 ]; then
  # Provide more specific error messages
  if [ "$#" -eq 1 ] && [ -f "$1" ]; then
    echo "Error: Search pattern is missing." >&2
  elif [ "$#" -eq 1 ]; then
    echo "Error: Filename is missing." >&2
  else
    echo "Error: Incorrect number of arguments." >&2
  fi
  echo "Use --help to display usage information" >&2
  exit 1
fi

pattern="$1"
filename="$2"

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
# Convert search pattern to lowercase once for efficiency.
BEGIN {
    lc_pattern = tolower(pattern)
}

{
    # Convert current line to lowercase for case-insensitive comparison.
    lc_line = tolower($0)

    is_match = (index(lc_line, lc_pattern) > 0)

    should_print = 0 
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
