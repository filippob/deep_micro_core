#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "❌ Usage: $0 <input_folder> <output_folder>"
    exit 1
fi

INPUT_FOLDER=$1
OUTPUT_FOLDER=$2

echo "🚀 Running merge_qiime2_tables.py..."
python merge_qiime2_tables.py "$INPUT_FOLDER" "$OUTPUT_FOLDER"

echo "🚀 Running merge_qiime2_rep_seqs.py..."
python merge_qiime2_rep_seqs.py "$INPUT_FOLDER" "$OUTPUT_FOLDER"

echo "🚀 Running merge_qiime2_taxonomy.py..."
python merge_qiime2_taxonomy.py "$INPUT_FOLDER" "$OUTPUT_FOLDER"

echo "✅ All scripts executed successfully!"
