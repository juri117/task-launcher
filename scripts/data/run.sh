cd $(dirname "$0")
mkdir logs
./task_launcher  > "./logs/$(date --utc '+%Y-%m-%d_%H-%M-%S')_stout.txt" 2>&1
