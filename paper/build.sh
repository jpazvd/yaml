#!/usr/bin/env bash
# build.sh — Fully reproducible build for the yaml Stata Journal paper
#
# Usage:
#   bash build.sh              # build everything (figures + paper)
#   bash build.sh figures      # build only figures
#   bash build.sh paper        # build only paper (assumes figures exist)
#   bash build.sh clean        # remove all generated artifacts
#
# Stata examples (manual step — run from repo root BEFORE building paper):
#   stata-mp -b do paper/examples/paper_examples.do
#   — or open Stata interactively and: do paper/examples/paper_examples.do
#   This reproduces every stlog block in the paper.
#   Data fixtures live in paper/examples/data/.
#
# Requirements:
#   - lualatex (TeX Live 2024 or later)
#   - bibtex
#   - Stata 16+ (for examples only, not for LaTeX build)
#
# Author: João Pedro Azevedo
# Date:   February 2026

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIGURES_DIR="$SCRIPT_DIR/figures"
PAPER_DIR="$SCRIPT_DIR"

# Standalone TikZ figure sources (all .tex files in figures/ that are standalone documents)
FIGURE_SOURCES=(
    yaml_layers_bw        # Used in paper: Figure 1 (architecture diagram)
    yaml_architecture     # Supplementary: detailed internal architecture
    yaml_bridge           # Supplementary: YAML as cross-platform bridge
    yaml_data_model       # Supplementary: data model / storage structure
    yaml_layers           # Supplementary: layered architecture (color version)
    yaml_subcommands      # Supplementary: subcommand hierarchy
    yaml_unicef_workflow  # Supplementary: UNICEF workflow diagram
    yaml_vertical         # Supplementary: vertical flow diagram
    yaml_workflow         # Supplementary: cross-platform workflow
    yaml_workflow_v2      # Supplementary: simplified horizontal workflow
)

# Paper main driver
PAPER_MAIN="main-v3"

# --------------------------------------------------------------------------
# Functions
# --------------------------------------------------------------------------

log() { echo "==> $*"; }
err() { echo "ERROR: $*" >&2; exit 1; }

check_deps() {
    command -v lualatex >/dev/null 2>&1 || err "lualatex not found. Install TeX Live."
    command -v bibtex   >/dev/null 2>&1 || err "bibtex not found. Install TeX Live."
}

build_figure() {
    local name="$1"
    local src="$FIGURES_DIR/${name}.tex"
    local pdf="$FIGURES_DIR/${name}.pdf"

    if [[ ! -f "$src" ]]; then
        echo "  SKIP $name.tex (not found)"
        return 0
    fi

    echo "  BUILD $name.tex"
    (
        cd "$FIGURES_DIR"
        lualatex -interaction=nonstopmode -halt-on-error "${name}.tex" > /dev/null 2>&1
    ) || {
        echo "  FAIL $name.tex — see $FIGURES_DIR/${name}.log"
        return 1
    }

    if [[ -f "$pdf" ]]; then
        echo "  OK    $name.pdf ($(wc -c < "$pdf") bytes)"
    else
        echo "  FAIL  $name.pdf not generated"
        return 1
    fi
}

build_figures() {
    log "Building figures in $FIGURES_DIR"
    local failures=0

    for name in "${FIGURE_SOURCES[@]}"; do
        build_figure "$name" || ((failures++))
    done

    if [[ $failures -gt 0 ]]; then
        log "WARNING: $failures figure(s) failed to compile"
    else
        log "All figures compiled successfully"
    fi
}

build_paper() {
    log "Building paper: $PAPER_MAIN.tex"

    # Verify the required figure exists
    if [[ ! -f "$FIGURES_DIR/yaml_layers_bw.pdf" ]]; then
        err "Required figure figures/yaml_layers_bw.pdf not found. Run 'build.sh figures' first."
    fi

    cd "$PAPER_DIR"

    log "Pass 1/4: lualatex (initial)"
    lualatex -interaction=nonstopmode "$PAPER_MAIN.tex" > /dev/null 2>&1 || true

    log "Pass 2/4: bibtex"
    bibtex "$PAPER_MAIN" 2>&1 | grep -E "^(Database|Warning|Error)" || true

    log "Pass 3/4: lualatex (resolve references)"
    lualatex -interaction=nonstopmode "$PAPER_MAIN.tex" > /dev/null 2>&1 || true

    log "Pass 4/4: lualatex (finalize)"
    lualatex -interaction=nonstopmode "$PAPER_MAIN.tex" > /dev/null 2>&1 || true

    if [[ -f "$PAPER_MAIN.pdf" ]]; then
        local pages
        pages=$(strings "$PAPER_MAIN.pdf" 2>/dev/null | grep -c "/Type /Page" || echo "?")
        log "SUCCESS: $PAPER_MAIN.pdf ($pages pages, $(wc -c < "$PAPER_MAIN.pdf") bytes)"
    else
        err "$PAPER_MAIN.pdf not generated. Check $PAPER_MAIN.log"
    fi

    # Report remaining warnings
    local warns
    warns=$(grep -c "Warning" "$PAPER_MAIN.log" 2>/dev/null || echo 0)
    local errs
    errs=$(grep -c "^!" "$PAPER_MAIN.log" 2>/dev/null || echo 0)
    log "Log summary: $warns warning(s), $errs error(s)"
}

check_examples() {
    log "Checking Stata example reproducibility"

    local dofile="$SCRIPT_DIR/examples/paper_examples.do"
    local datadir="$SCRIPT_DIR/examples/data"
    local missing=0

    if [[ ! -f "$dofile" ]]; then
        echo "  MISSING examples/paper_examples.do"
        ((missing++))
    else
        echo "  OK      examples/paper_examples.do"
    fi

    for f in config.yaml unicef_indicators.yaml pipeline_config.yaml \
             dev_config.yaml prod_config.yaml mics_eth_config.yaml \
             user_config.yml; do
        if [[ ! -f "$datadir/$f" ]]; then
            echo "  MISSING examples/data/$f"
            ((missing++))
        else
            echo "  OK      examples/data/$f"
        fi
    done

    local logfile="$SCRIPT_DIR/examples/logs/paper_examples.log"
    if [[ -f "$logfile" ]]; then
        echo "  OK      examples/logs/paper_examples.log (last run exists)"
    else
        echo "  NOTE    examples/logs/paper_examples.log not found"
        echo "          Run: stata-mp -b do paper/examples/paper_examples.do"
    fi

    if [[ $missing -gt 0 ]]; then
        log "WARNING: $missing example file(s) missing"
    else
        log "All example files present"
    fi
}

clean() {
    log "Cleaning generated artifacts"

    # Clean figure build artifacts (keep .tex sources)
    cd "$FIGURES_DIR"
    rm -f *.aux *.log *.fdb_latexmk *.fls *.synctex.gz *.pdf *.pp1 *.tag *.out
    echo "  Cleaned figures/"

    # Clean paper build artifacts (keep .tex, .bib, .bst, .sty, .cls sources)
    cd "$PAPER_DIR"
    rm -f "$PAPER_MAIN".{aux,bbl,blg,log,out,pdf,pp1,tag,fdb_latexmk,fls,synctex.gz}
    echo "  Cleaned paper/"

    # Clean example logs (keep .do and data)
    rm -f "$SCRIPT_DIR"/examples/logs/*.log
    rm -f "$SCRIPT_DIR"/examples/logs/*.yaml
    echo "  Cleaned examples/logs/"

    log "Done"
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

check_deps

case "${1:-all}" in
    figures)
        build_figures
        ;;
    paper)
        build_paper
        ;;
    examples)
        check_examples
        ;;
    clean)
        clean
        ;;
    all)
        check_examples
        build_figures
        build_paper
        ;;
    *)
        echo "Usage: bash build.sh [all|figures|paper|examples|clean]"
        exit 1
        ;;
esac
