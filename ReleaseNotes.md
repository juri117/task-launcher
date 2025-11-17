# Release Notes

## 1.0.03

**features:**
* replace paths starting with "./" with the abs path to this apps root folder
* use monospace font for log output
* allow sudo commands and pw input
* display ANSI colored text
* [ ] rework gui update logic (whole gui updated when log is appended)

## 1.0.02

**features:**
* rename default config file: setup.json -> config.json
* theme can be set in config, options are here: https://docs.flexcolorscheme.com/all_themes
* add option to set title in config (helps if you use multiple instances)

**bug-fixes:**
* fix log-file path on linux, use logs folder next to binary

## 1.0.01

**features:**
* support for loading different json config as cmd-line parameter
* support for communication with tasks, show text field when prompted for input by process

## 1.0.00

**features:**
* [x] option to log task output
* [x] update dependencies

**bug-fixes:**
* [x] fix linux app icon

## 0.00.005

**features:**
* [x] allow environment variable setup
* [x] add config value `maxLogLines` for max. number of log lines
* [x] read version from pubspec.yaml

**bug-fixes:**
* [x] fix bug in log list trim
* [x] make logs selectable
* [x] kill tasks on windows close did not work

## 0.00.004

**features:**
* [x] upgrade build-toolchain
* [x] rework log view (in hope of getting rid of some random crashes)
* [x] show version number in app-bar
* [x] add custom launch icon

## 0.00.003

**features:**
* [x] add floating button to scroll down and copy stdout
* [x] improve auto scroll behavior
* [x] make timer count while process is still running
* [x] add menu with option to reload setup.json

**bug-fixes:**
* [x] prevent app freeze by limiting console string length
* [x] improve scroll behavior

## 0.00.002

**features:**
* [x] add start and runtime info to task-list
* [x] add failed state (exclamation mark)
* [x] add colors to state icons
* [x] add setup steps for custom profiles
* [x] redesign process pipes to be more robust

## 0.00.001

**features:**
* [x] basic working app
* [x] support for different terminal-profiles