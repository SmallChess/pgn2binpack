# PGN Annotation Guide for pgn2binpack

## Overview

This document summarizes the work done to enable annotation of PGN files with Stockfish evaluations in the format required by `pgn2binpack`.

## Repository Summary

**pgn2binpack** is a Rust tool that converts PGN (Portable Game Notation) chess files into binpack format for efficient position storage. The binpack format is used by Stockfish for neural network training data.

### Key Features
- Converts `.pgn` and `.pgn.gz` files to concatenated binpack format
- Parallel processing with configurable threading
- Two processing modes: memory (faster) and disk (lower RAM)
- Analytics: view binpack contents and count unique positions
- No engine evaluation required - works with or without evaluations

### Output Format

The tool outputs a **compressed binpack file** containing `TrainingDataEntry` records with:
- **Position** (FEN)
- **Move** (UCI notation)
- **Score** (evaluation in internal Stockfish format)
- **Ply** (move number)
- **Result** (1 = win, -1 = loss, 0 = draw from side-to-move perspective)

## Evaluation Format Requirements

### Required Format

The tool expects evaluations in **curly braces** with the following format:
- `{+1.01/26}` - Positive evaluation: +1.01 pawns at depth 26
- `{-0.34/15}` - Negative evaluation: -0.34 pawns at depth 15
- `{+M21/32}` - Mate in 21 at depth 32
- `{-M21/32}` - Mated in 21 at depth 32

### Incompatible Formats

**Lichess format** (NOT supported):
- `[%eval 0.18]` - Square brackets with `%eval` tag
- `[%clk 0:03:00]` - Clock information (not used)

If evaluations are in Lichess format, they will be ignored and all positions will have `score = 0`.

### Software That Generates Compatible Format

The curly brace format is commonly produced by:
- **Stockfish** (via UCI analysis tools)
- **ChessBase** (commercial)
- **Arena Chess GUI**
- **Scid vs PC**
- **Cute Chess** (when analyzing games)
- Custom scripts that run Stockfish via UCI

## Building Cute Chess CLI

We built `cutechess-cli` from source, though it's primarily designed for running engine tournaments rather than annotating existing PGN files.

### Prerequisites
- Qt5 (version 5.15 or greater)
- CMake
- C++ compiler with C++11 support

### Build Steps

```bash
# Install dependencies
brew install qt@5 cmake

# Clone repository
git clone git@github.com:cutechess/cutechess.git
cd cutechess

# Build
mkdir build && cd build
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/qt@5/lib"
export CPPFLAGS="-I/opt/homebrew/opt/qt@5/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/qt@5/lib/pkgconfig"
cmake ..
make -j$(sysctl -n hw.ncpu)
```

The `cutechess-cli` executable will be at: `cutechess/build/cutechess-cli`

**Note:** `cutechess-cli` is designed for running engine tournaments, not for annotating existing PGN files. For annotation, use the Python script described below.

## PGN Annotation Solution

Since `cutechess-cli` doesn't directly support annotating existing PGN files, annotation requires a custom solution using Stockfish.

### Annotation Options

**Option 1: Use existing chess software**
- **ChessBase** (commercial) - Can export PGN with evaluations in curly brace format
- **Arena Chess GUI** - Analyze games and export with evaluations
- **Scid vs PC** - Free chess database with analysis capabilities

**Option 2: Custom script**
Create a Python script using the `python-chess` library to:
1. Read a PGN file
2. For each position, use Stockfish to analyze and get evaluation
3. Add evaluation comments in the format `{+eval/depth}` or `{-eval/depth}`
4. Write the annotated PGN to a new file

**Option 3: Manual conversion**
Convert Lichess format (`[%eval 0.18]`) to required format (`{+0.18/20}`) using text processing tools.

### Example Python Script Structure

A basic annotation script would:
- Use `python-chess` to parse PGN files
- Connect to Stockfish via UCI protocol
- Analyze each position before moves
- Format evaluations as `{+eval/depth}` or `{-eval/depth}`
- Write annotated PGN output

The script should handle:
- Converting centipawns to pawns for display
- Formatting mate scores as `{+M21/depth}` or `{-M21/depth}`
- Setting appropriate search depth and time limits

## Complete Workflow

### Step 1: Annotate PGN File

```bash
cd /Users/scchess/Sources/pgn2binpack
source venv/bin/activate
python3 annotate_pgn.py game.pgn game_annotated.pgn 20 0.1
```

This creates `game_annotated.pgn` with evaluations in the format:
```
1. e4 { +0.37/16 } 1... d6 { -0.28/16 } 2. d4 { +0.45/17 } ...
```

### Step 2: Convert to Binpack

```bash
# Build pgn2binpack (if not already built)
cargo build --release

# Convert annotated PGN to binpack
./target/release/pgn2binpack game_annotated.pgn -o output.binpack
```

### Step 3: Verify (Optional)

```bash
# View binpack contents
./target/release/pgn2binpack --view output.binpack --limit 10

# Count unique positions
./target/release/pgn2binpack --unique output.binpack
```

## Files Created

1. **`annotate_pgn.py`** - Python script for annotating PGN files with Stockfish evaluations
2. **`annotate_with_stockfish.sh`** - Shell script wrapper (optional)
3. **`cutechess/`** - Cloned and built Cute Chess repository (for reference)
4. **`venv/`** - Python virtual environment with python-chess installed

## Key Findings

1. **No Engine Required for Conversion**: `pgn2binpack` works without evaluations, but evaluations enhance the training data quality.

2. **Format Mismatch**: Lichess PGN format (`[%eval ...]`) is incompatible. Evaluations must be in curly braces (`{+eval/depth}`).

3. **Tool Limitation**: `cutechess-cli` is designed for tournaments, not PGN annotation. The Python script provides the needed functionality.

4. **Evaluation Format**: The tool expects evaluations in pawns (not centipawns) with depth information, e.g., `{+1.01/26}`.

## Troubleshooting

### Stockfish Not Found
If Stockfish is in a different location, update the `stockfish_path` variable in `annotate_pgn.py`.

### Python Module Not Found
Ensure the virtual environment is activated:
```bash
source venv/bin/activate
```

### Build Issues with Cute Chess
Make sure Qt5 is properly installed and environment variables are set:
```bash
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/qt@5/lib"
export CPPFLAGS="-I/opt/homebrew/opt/qt@5/include"
```

## References

- **pgn2binpack repository**: The main tool for converting PGN to binpack format
- **Cute Chess**: https://github.com/cutechess/cutechess
- **python-chess**: Python library for chess game handling
- **Stockfish**: https://stockfishchess.org/

## Summary

We successfully:
1. ✅ Analyzed the pgn2binpack repository and its requirements
2. ✅ Identified the evaluation format requirements (curly braces)
3. ✅ Built cutechess-cli from source (for reference)
4. ✅ Created a Python annotation script using Stockfish
5. ✅ Successfully annotated a PGN file with the correct format
6. ✅ Verified the output format is compatible with pgn2binpack

The annotation workflow is now ready for use with any PGN file that needs Stockfish evaluations added.

