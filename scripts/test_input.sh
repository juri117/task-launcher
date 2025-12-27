
echo "Are you sure you want to continue? (yes/no)"
read -r confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Operation cancelled by user"
    exit 0
fi

echo "password (correct is: 123): "
read -rs password

if [ "$password" != "123" ]; then
    echo "Invalid password"
else
    echo "Valid password"
fi

echo "Continuing with operation..."