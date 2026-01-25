# Digital Bricks

Simulation of digital ircuits.

## Standard gates
All, but Inverter do have 2 input ports, which may be increased to 3, 4, or 8 inputs
* AND
* NAND
* OR
* NOR
* XOR
* NXOR
* Inverter
* Constant value: Either 1 or 0 as parameter

## FLip-flops
* D
* RS

# Input/Output Components
* Circuit Input/Ouput: For circuit developmeent definition of pins exposed for reuse and gaining access to internal logic
* Oscillator: with frequency as parameter
* LED: definable on and off color as parameters
* 7 and 16 segment display

## Custom
* In this compartment you get list of your blueprint circuits
* All circuits here are stored in a "blueprints.json" file and can be reloaded by clicking on the upward arrow (right from compartment name)

### Definition of your own custom circuits
 1 Design your circuit with the standard gates and other custom circuits
 
  * Use "Circuit Input/Output" to define the pins to be exposed when reusing. The input pins are on the left side of the circuit the output pins on the right

 2 Select all items which should be part of the circuit. Don't forget the input and output pins.
 
 3 After selection click on the disc symbol and set the name of your custom circuit. If the name exists already, the existing circuit will be _overwritten_

## Connections
Just drag from source pin to any target pin, but output pins.
Right-click on connection to delete it

## Parameter
Access parameter of circuit by right-clicking on the circuit.

## Save, read circuit design
Use the icons in the task bar on the top right:
1 Save: Uses circuit.json as default name

2 Save as: Define the location and file name and press 'Save'

3 Open: Select a circuit design (a JSON file)

4 Clear canvas: clicking on the reload symbol empties the entire canvas. A confirmation is requested to prevent an unintential deletion.

# Keys

| Key | Meaning |
|---- | --------|
| ^a | Select all |
| ^s | Save |
| ^o | Open |
| \<up\> | Move selected items upwards |
| \<down\> | Move selected items downwards |
| \<left\> | Move selected items left |
| Backspace | Delete selected items |
| Del | Delete selected items |

| \<right\> | Move selected items right |

