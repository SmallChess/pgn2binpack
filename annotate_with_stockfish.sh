#!/bin/bash
# Annotate a PGN file with Stockfish evaluations using cutechess-cli approach
# This script uses Stockfish directly via UCI to analyze positions

STOCKFISH="/opt/homebrew/bin/stockfish"
INPUT_PGN="$1"
OUTPUT_PGN="${2:-${INPUT_PGN%.pgn}_annotated.pgn}"
DEPTH="${3:-20}"

if [ ! -f "$INPUT_PGN" ]; then
    echo "Error: Input PGN file not found: $INPUT_PGN"
    exit 1
fi

if [ ! -f "$STOCKFISH" ]; then
    echo "Error: Stockfish not found at $STOCKFISH"
    exit 1
fi

echo "Annotating $INPUT_PGN with Stockfish (depth=$DEPTH)"
echo "Output will be written to $OUTPUT_PGN"

# Use python-chess if available, otherwise provide instructions
if command -v python3 &> /dev/null; then
    cd "$(dirname "$0")"
    if [ -d "venv" ]; then
        source venv/bin/activate
        python3 annotate_pgn.py "$INPUT_PGN" "$OUTPUT_PGN" "$DEPTH" 0.1
    else
        echo "Note: Python virtual environment not found. Using direct Stockfish approach..."
        echo "For better results, use the Python script: python3 annotate_pgn.py $INPUT_PGN $OUTPUT_PGN"
    fi
else
    echo "Python3 not found. Please install python-chess or use a different annotation tool."
    exit 1
fi

