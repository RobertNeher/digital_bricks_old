# Digital Bricks

Simulation of digital circuits.

## Standard gates

All gates except the Inverter have 2 input ports by default, which can be increased to 3, 4, or 8 inputs via the context menu.

* AND
* NAND
* OR
* NOR
* XOR
* NXOR
* Inverter

## Flip-flops

* D (with Reset and Preset)
* RS
* JK (with Reset and Preset)

## Input/Output Components

* Circuit Input/Output: Use these to define the pins exposed when reusing a circuit as a custom component.
* Oscillator: Generates a clock signal with parameterizable frequency.
* LED: Visual indicator with customizable "High" and "Low" state colors.
* Button: Interactive toggle component. Click to switch between High (on) and Low (off).
* 7 and 16 segment display: Multi-segment indicators with customizable colors and font sizes.

## Custom Components

* Select any part of your circuit and save it as a "blueprint" to reuse it as a single component.
* Custom components are stored in `blueprints.json` and can be reloaded using the refresh icon in the Custom compartment.
* Custom components maintain the same visual style (surrounding box and pins) as standard gates.

### Creating Custom Circuits

1. Design your circuit using standard gates, IO components, and other custom circuits.
2. Use **Circuit Input/Output** components to define the external pins. Inputs should be on the left, outputs on the right.
3. Select all items to be included, then click the **Save (Disk)** icon in the selection toolbar.
4. Provide a name; if the name already exists, the blueprint will be overwritten.

## Interaction

* **Connections**: Drag from a source pin to any target input pin. Right-click a connection to delete it.
* **Selection**: Click to select, or use a selection marquee. Selected items can be moved as a group.
* **Context Menu**: Right-click any component to access its parameters (labels, frequency, colors, pin counts).
* **Canvas**: The canvas is an expansive 10000x10000 area, allowing for very large and complex designs.

## File Operations

Use the icons in the top-right toolbar:
1. **Save**: Saves the current design to `circuit.json`.
2. **Save As**: Choose a specific location and filename.
3. **Open**: Load a previously saved circuit design.
4. **Clear Canvas**: Empties the canvas (requires confirmation).

## Shortcut Keys

| Key | Action |
| ---- | -------- |
| `Ctrl + A` | Select All |
| `Ctrl + S` | Save |
| `Ctrl + O` | Open |
| `Up/Down/Left/Right` | Move selected items |
| `Backspace / Del` | Delete selected items |
| `Enter` | Submit values in parameter dialogs |
