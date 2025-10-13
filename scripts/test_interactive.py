#!/usr/bin/env python3

import sys

print("Interactive Test Script")
print("Type 'quit' to exit")
print("=" * 30)

while True:
    try:
        user_input = input("Enter something: ")
        if user_input.lower() == 'quit':
            print("Goodbye!")
            break
        print(f"You entered: {user_input}")
    except EOFError:
        print("\nEOF received, exiting...")
        break
    except KeyboardInterrupt:
        print("\nInterrupted, exiting...")
        break

print("Script finished")
