# Changelog

## 0.2.0

- Improves
  - Cleaner emission of signal by `StateMachinePlayer`
  - Add `autostart` property to `StateMachinePlayer`
  - Auto disable `StateMachinePlayer` when exit
  - `StackMachinePlayer` lock update by default
- Bugfixes:
  - Fix `StateMachinePlayer` doesn't transit after reset
- Refactor
  - Move transitions list from `State` to `StateMachine`
  - Rename `StackPlayer` signal `changed(from, to)` to `current_changed(from, to)`

## 0.1.0

- Features:
  - Simple FSM implementation
  - Simple `StackPlayer` debugger to visualize stack
  - Graph editor to edit `StateMachine`
  - Undo/redo supported
  - Saving `StateMachine`
