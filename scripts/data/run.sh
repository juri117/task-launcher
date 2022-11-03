mkdir logs
start ./task_launcher.exe  > "./logs/$(date --utc '+%Y-%m-%d_%H-%M-%S')_stout.txt" 2>&1
