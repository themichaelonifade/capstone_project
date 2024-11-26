#!/bin/bash

# Paths
DATA_HUB="data-hub"
INCOMING_DATA="incoming-data"
MERGED_FILE="db/integrated_data.csv"
TEMP_FILE="temp_combined.csv"

# Step 1: Initial merge of all files in the datahub folder
if [ ! -f "$MERGED_FILE" ]; then
    echo "Performing initial merge of all files in $DATA_HUB..."
    if ls $DATA_HUB/*.csv 1> /dev/null 2>&1; then
        cat $DATA_HUB/*.csv > "$TEMP_FILE"
        awk '!seen[$0]++ || NR==1' "$TEMP_FILE" > "$MERGED_FILE"
        rm "$TEMP_FILE"
        echo "Initial merge complete. File saved to $MERGED_FILE"
    else
        echo "No files found in $DATA_HUB. Exiting..."
        exit 1
    fi
fi

# Step 2: Process new incoming files
echo "Checking for new files in $INCOMING_DATA..."
if ls $INCOMING_DATA/*.csv 1> /dev/null 2>&1; then
    for file in $INCOMING_DATA/*.csv; do
        # Check if the file already exists in datahub
        filename=$(basename "$file")
        if [ -f "$DATA_HUB/$filename" ]; then
            echo "File $filename already exists in $DATA_HUB. Skipping..."
            continue
        fi
        
        # Record the initial number of rows in the merged file
        initial_rows=$(wc -l < "$MERGED_FILE")

        # Merge the new file with the merged file
        echo "Merging $filename with the existing merged file..."
        cat "$file" >> "$TEMP_FILE"
        awk '!seen[$0]++ || NR==1' "$MERGED_FILE" "$TEMP_FILE" > "$MERGED_FILE"
        rm "$TEMP_FILE"

        # Record the number of rows added from the incoming file
        new_rows=$(wc -l < "$file")
        added_rows=$((new_rows - initial_rows))

        # Move the new file to the datahub folder
        mv "$file" "$DATA_HUB/"
        echo "File $filename merged and moved to $DATA_HUB."

        # Display row counts
        echo "Rows initially in the merged file: $initial_rows"
        echo "Rows added from $filename: $added_rows"
    done
else
    echo "No new files found in $INCOMING_DATA."
fi

echo "Data integration complete. Final merged file is located at $MERGED_FILE."

