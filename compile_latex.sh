#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <file.tex | basename>"
    echo
    echo "Examples:"
    echo "  $0 paper"
    echo "  $0 paper.tex"
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
fi

input="$1"

# Strip trailing .tex if present
base="${input%.tex}"
texfile="${base}.tex"

if [[ ! -f "$texfile" ]]; then
    echo "ERROR: File not found: $texfile" >&2
    exit 1
fi

# Basic command checks
for cmd in pdflatex; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: $cmd" >&2
        exit 1
    fi
done

run_pdflatex() {
    echo
    echo "===== Running pdflatex on $texfile ====="
    pdflatex -interaction=nonstopmode -halt-on-error "$texfile"
}

echo "===== Compiling $texfile ====="

# First LaTeX pass generates .aux/.bcf/etc.
run_pdflatex

need_biber=false
need_bibtex=false

# biblatex + biber usually creates a .bcf file
if [[ -f "${base}.bcf" ]]; then
    need_biber=true
fi

# Traditional BibTeX uses \bibdata in the .aux file
if [[ -f "${base}.aux" ]] && grep -q '\\bibdata' "${base}.aux"; then
    need_bibtex=true
fi

if [[ "$need_biber" == true ]]; then
    if ! command -v biber >/dev/null 2>&1; then
        echo "ERROR: biber appears to be needed, but biber was not found." >&2
        exit 1
    fi

    echo
    echo "===== Running biber on $base ====="
    biber "$base"

elif [[ "$need_bibtex" == true ]]; then
    if ! command -v bibtex >/dev/null 2>&1; then
        echo "ERROR: bibtex appears to be needed, but bibtex was not found." >&2
        exit 1
    fi

    echo
    echo "===== Running bibtex on $base ====="
    bibtex "$base"

else
    echo
    echo "===== No biber/bibtex step detected ====="
fi

# Final passes resolve citations/references
run_pdflatex
run_pdflatex

echo
echo "===== Done ====="
echo "Output: ${base}.pdf"
