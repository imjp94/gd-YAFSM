# gd-YAFSM (**g**o**d**ot-**Y**et **A**nother **F**inite **S**tate **M**achine)

Designer-friendly Finite State Machine implemented in "Godotic" way

⚠️ **Warning**
> It is not recommended to be used in production yet, as api might be changed before v1.0.
> Testing & reporting bugs are greatly appreciated.

## Feature

- Designer-friendly
  > Design `StateMachine` in a flowchart-like editor
- Self-explanatory
  > Understand what the `StateMachine` trying to achieve from flowchart
- Zero learning curve
  > Similar workflow as using `AnimationTree`, and not required to inherit any custom class, just plug and play
- Reusability
  > As a `Resource`, `StateMachine` can be used repeatedly in different scenarios(`StateMachinePlayer`) and provide different outcome based on the input.
- Minimal
  > Compact data structure for `StateMachine` resource file

For more detail, see [CHANGELOG.md](CHANGELOG.md)

## Installation

- Install directly from Godot Asset Library

or

- Download this respository,
  1. Move `addons/imjp94.yafsm` to your `{project_dir}`
  2. Enable it from Project -> Settings -> Plugins

## Usage

### Editor

1. Add `StateMachinePlayer` node from "Create New Node" window.

2. Select created node and the state machine editor should shows up.

3. Click on "Create StateMachine" button to get started.

Finally, right-click on graph to add state node.

Special states:

- Entry: Entry point of a `StateMachine`, always required
- Exit: `State` that break the flow of `StateMachine`, unless restarted with `StateMachinePlayer.restart()`, mainly used in nested-`StateMachine`.

### Code

After setup `StateMachine` with editor, you can connect to the following signals from a `StateMachinePlayer`:

- `transited(from, to)`: Transition of state
- `update(state, delta)`: Time to update(defined by `process_mode`), up to user to handle anything, for example, update movement of `KinematicBody`

That's it!

For most of the case, you don't have to inherit from any custom class by this plugin, simply just connect signals to your existing node and you're good to go.

> See documentation below for more details

### Debug

- Stack
  > Add `res://addons/imjp94.yafsm/src/debugger/StackPlayerDebugger.tscn` to `StackPlayer`(so as `StateMachinePlayer`) to visualize the stack on screen.

## Documentation

Refer to [Documentation](addons/imjp94.yafsm/README.md) located in addons/imjp94.yafsm/README.md
