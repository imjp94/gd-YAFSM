# gd-YAFSM (**g**o**d**ot-**Y**et **A**nother **F**inite **S**tate **M**achine)

Simple Finite State Machine implemented in "Godotic" way

⚠️ **Warning**
> This project is still in early development and breaking changes are expected, thus, it is not recommended to be used in production.
> Testing & reporting bugs are greatly appreciated.

## Feature

- Zero learning curve
  > Similar workflow as using `AnimationTree`, and not required to inherit any custom class, just plug and play
- Lightweight
  > Compact data structure
- Reusable
  > Same `StateMachine` reference can be used repeatedly in different `StateMachinePlayer`

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

### Code

After setup `StateMachine` with editor, you can connect to the following signals from a `StateMachinePlayer`:

- `changed(from, to)`: Current state name changed
- `transit_out(from)`: State name transit out from
- `transit_in(to)`: State name transit into
- `update(state, delta)`: Time to update(defined by `process_mode`), up to user to handle anything, for example, update movement of `KinematicBody`

That's it!

For most of the case, you don't have to inherit from any custom class by this plugin, simply just connect signals to your existing node and you're good to go.

> See documentation below for more details

### Debug

- Stack
  > Add `StackPlayerDebugger` to `StackPlayer`(so as `StateMachinePlayer`) to visualize the stack on screen.

## Documentation

Refer to [Documentation](addons/imjp94.yafsm/README.md) located in addons/imjp94.yafsm/README.md
