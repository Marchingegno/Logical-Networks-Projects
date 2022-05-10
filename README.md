
# Logical Networks FPGA design - Politecnico di Milano
Project for the Logical Network course of Politecnico di Milano, 2019.

## Description
The assignment was to describe and synthesize, using VHDL, an FPGA used to solve the problem given in the assignment.
The problem is as follows:

Given a 256x256 space realize a hardware component that, given a set of points and a chosen point, returns the point(s) closest to the chosen one using Manhattan distance.
A binary mask can be given that compels to ignore points corresponding to 0s in the mask.

<img src="https://i.imgur.com/CSDqhv9.png" width=425 height=250></img>

The component should have the following interface:
* __i_clk__ is the CLOCK signal of the Test Bench;
* __i_start__ is the START signal of the Test Bench;
* __i_rst__ is the RESET signal that initializes the machine to receive the START signal;
* __i_data__ is the vector signal from the memory after a read request;
* __o_address__ is the output vector signal that communicates the address to the memory;
* __o_done__ is the signal that ends elaboration;
* __o_en__ is the ENABLE signal of the memory;
* __o_we__ is the WRITE ENABLE signal: 1 for writing, 0 for reading;
* __o_data__ is the data to be written in the memory from the component;

## Solution
Our solution minimizes the total clock cycles at the expense of the area employed.
The solution is divided in three phases:
1. Reading necessary data from memory
2. Searching for the closest point(s)
3. Presenting the solution

<img src="https://i.imgur.com/04ao0YH.png" width=600 height=325></img>

We based the solution on a finite-state machine. To minimize clock cycles, we designed multitasking states: for example, the state __MEM_MASK__ memorizes the mask and also requests the X coordinate of the chosen point.
States are as follows:
* __WAIT_START__: initializes all signals and waits for __i_start__;
* __START__: requests the mask value from the memory;
* __MEM_MASK__: memorizes the input mask and, at the same time, requests the X coordinate of the chosen point;
* __MEM_XPOINT__: memorizes the X coordinate of the chosen point and requests its Y coordinate;
* __MEM_YPOINT__: memorizes the Y coordinate of the chosen point and requests the X coordinate of the first centroid;
* __MEM_XCENTROID__: 
   *  if the centroid is to be considered, memorizes the X coordinate and requests its Y coordinate;
   * if the centroid is to be skipped, requests the X coordinate of the next centroid;
   * if there are no more centroid to be considered, go to the solution phase.
* __MEM_YCENTROID__: memorizes Y coordinate of the centroid.
* __COMPUTE_MIN_DIST__: update minimum distance from the chosen point and can ask for the X coordinate of the next centroid;
* __GIVE_OUTPUT__: assign to the memory register the solution mask;

<img src="https://i.imgur.com/tSTaMNp.png" width=325 height=400></img>

## Optimizations
* If a centroid is to be skipped, its coordinate are not saved in the registers and its distance is not computed;
* If the input mask is trivial, the machine goes directly to the __GIVE_OUTPUT__ state;
* There is no wait_result state: the machine reads and requests the next data point in the same clock cycle.

## Results
From the Report Timing we can calculate the minimum clock period with no errors. Given a Worst Negative Slack of 90.445 ns and the RAM response delay is 2 ns, the minimum period is as follows:

<img src="https://i.imgur.com/gEhpo6I.png" width=675 height=112></img>

On the xc7a200tfbg484-1 FPGA component of Vivado.

__document.pdf__ is the complete report of the assignment in italian.

## Developers

- Matteo Marchisciana (https://github.com/Marchingegno)
- Andrea Marcer (https://github.com/AndreaMarcer)
