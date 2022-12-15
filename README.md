# flutter task launcher

A graphical task launcher written in flutter, setup via json file, support for different terminal apps, should run on windows, linux, macos (tested on windows).

![](docs/img/screenshot01.png)

## example

place a `setup.json` file next to the executable with e.g.
```json
{
    "profiles": [
        {
            "name": "git-bash",
            "executable": "C:/Program Files/Git/bin/bash.exe",
            "setup": [
                "export LANG=C.UTF-8"
            ]
        },
        {
            "name": "wsl",
            "executable": "wsl.exe",
            "params": [
                "-d",
                "Ubuntu"
            ],
            "setup": [
                "cd ~"
            ]
        }
    ],
    "tasks": [
        {
            "name": "test ipconfig",
            "cmd": "ipconfig"
        },
        {
            "name": "test ping",
            "cmd": "ping",
            "params": [
                "192.168.0.0"
            ]
        },
        {
            "name": "test ls",
            "cmd": "ls"
        },
        {
            "name": "test ls in git bash",
            "profile": "git-bash",
            "cmd": "ls"
        },
        {
            "name": "test help",
            "cmd": "help"
        },
        {
            "name": "sleep",
            "profile": "git-bash",
            "cmd": "sleep 20"
        },
        {
            "name": "python test",
            "cmd": "python",
            "workingDirectory": "./scripts",
            "params": [
                "test.py"
            ]
        },
        {
            "name": "python test error",
            "cmd": "python",
            "workingDirectory": "./scripts",
            "params": [
                "test_error.py"
            ]
        },
        {
            "name": "python test big text",
            "cmd": "python",
            "workingDirectory": "./scripts",
            "params": [
                "big_text.py"
            ]
        },
        {
            "name": "release",
            "profile": "git-bash",
            "cmd": "./scripts/release.sh"
        }
    ]
}
```