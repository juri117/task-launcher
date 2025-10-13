
echo "Are you sure you want to continue? (yes/no)"
read -r confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Operation cancelled by user"
    exit 0
fi

echo "Continuing with operation..."