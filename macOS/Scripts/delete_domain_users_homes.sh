#!/bin/bash

# Get the list of all users
domain_users=$(ls -l /Users | grep 'Domain Users' | awk '{print $3}')

# Iterate over each user
while IFS= read -r user; do
    echo "Deleting user: $user"
    
    # Try to delete the user 3 times
    for i in {1..3}; do
      if rm -rf "/Users/$user"; then
        echo "Attempt $i: Deleted home directory: /Users/$user"
      else
        echo "Attempt $i: Failed to delete home directory: /Users/$user"
      fi
        break
    done
done <<< "$domain_users"

exit 0
