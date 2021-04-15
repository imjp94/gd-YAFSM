# Changelog

## 0.5.0

- Breaking changes:
  - Rename StateMachinePlayer._*_param() functions to *_nested_param()
- Features:
  - Support remote debug when select StateMachinePlayer node in remote SceneTree
    - View live parameters with ParameterPanel
    - Visualize flow of StateMachine
- Improves:
  - Add StateDirectory.goto()
  - Minimize size of StateNode name edit for ease of opening nested layer
- Bugfixes:
  - Fix graph content above scrollbars
  - Fix StateMachineEditor & PathViewer didn't free removed child
  - Fix StateMachinePlayer's nested trigger are not flushed
  - Fix hard to select text in StateNode name edit

## 0.4.1

- Features:
  - Add StateMachine.validate() function to identify & fix corrupted StateMachine Resource
- Improves:
  - Clip FlowChartLine by connecting nodes
  - Position nodes by its center
  - Add transparency when dragging nodes
- Bugfixes:
  - Fix self connection is possible when reconnecting line

## 0.4.0

- Breaking changes:
  - `set_param`/`set_trigger`/`clear_param`/`erase_param`/etc... always `auto_update` by default
  - `StateMachinePlayer` enter/exit signals now pass one argument(base state that entry/exit)
  - Rename `State.ENTRY`/`EXIT_KEY` to `ENTRY`/`EXIT_STATE`
- Feature:
  - Support Nested `StateMachine`
  - Added `StateDirectory` class to traverse state path like file directory
  - Added `StringCondition`
  - Reconnection of transition line in FlowChart
  - Add unsaved indicator in `StateMachineEditor`
  - Add has_param function to `StateMachinePlayer`
  - Add logo
- Improves:
  - Disallow connection to Entry and connection from Exit
  - Avoid selecting node when connecting
  - Make StackPlayerDebugger ignore mouse
- Bugfixes:
  - Fix `StateMachineEditor` is not cleared when `StateMachinePlayer` changed
  - Fix `StateMachineEditor` trying to save built-in resource(StateMachine)
  - Fix `StateMachienEditor` doesn't save external resouce(StateMachine) when saving scene
  - Fix dragging node with weird mouse offset after delete connection
  - Fix recursive transition when `update()` called in transited signal

## 0.3.0

- Features:
  - Switch from GraphEdit to FlowChart editor

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
