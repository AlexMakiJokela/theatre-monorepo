#!/usr/bin/env bash

# Generate a random 5-digit PIN
PIN=$(((RANDOM % 90000) + 10000))
echo "You are about to destroy the core database, enter this pin to confirm: $PIN"

# Ask the user to enter the PIN
read -p "Enter the PIN: " entered_pin

# Compare the entered PIN with the generated PIN
if [ "$entered_pin" == "$PIN" ]; then
    echo "PIN verified."

    # as for the location of dump file
    read -p "Enter the location of dump file (empty to skip): " dump_file

    # check if entered anything for dump_file
    if [ -z "$dump_file" ]; then
        echo "Clearing core database..."
        mongosh --quiet --eval 'db.getMongo().getDBNames().forEach(function(i){try { console.log("Dropping",i);db.getSiblingDB(i).dropDatabase() } catch {}})'
        exit 0
    fi

    if [ -d "$dump_file" ]; then
        echo "Dump file found. Dropping and restoring databases..."
        mongosh --quiet --eval 'db.getMongo().getDBNames().forEach(function(i){try { console.log("Dropping",i);db.getSiblingDB(i).dropDatabase() } catch {}})'
        mongorestore --dir $dump_file
    else
        echo "Dump file not found. Aborting operation."
    fi

else
    echo "Incorrect PIN. Aborting operation."
fi
