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
