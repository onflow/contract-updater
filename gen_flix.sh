#!/bin/bash

# Define the directories to traverse
directories=("transactions" "scripts")

# Iterate over each directory
for directory in "${directories[@]}"; do
    # Define the root directory for the current iteration
    root_dir="./$directory"
    
    # Use find to search for all files in the directory and its subdirectories
    find "$root_dir" -type f | while IFS= read -r filepath; do
        # Call the flow executable with the filepath as a parameter
        flow flix generate "$filepath" --save "$filepath.flix.json"
    done

    # Move all *.flix.json files to the flix directory
    find "./$directory" -type f -name "*.flix.json" -exec mv {} "./flix" \;
done

