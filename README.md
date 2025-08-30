# Matrix-Vector Multiplication (MVM) Engine


A high-performance SystemVerilog implementation of a matrix-vector multiplication accelerator inspired by Microsoft's BrainWave deep learning architecture.

## 🚀 Project Overview

This project implements a complete digital hardware system for matrix-vector multiplication, featuring memory management, pipelined datapath components, and intelligent control logic. The design is optimized to achieve timing closure at **150+ MHz** on FPGA platforms.

### Key Features
- **Fully Pipelined Architecture**: Optimized for high throughput and performance
- **Parameterizable Design**: Configurable bit widths and memory depths
- **Scalable Compute Lanes**: Variable number of output lanes (OLANES)
- **Memory-Mapped Interface**: Efficient data loading and computation orchestration
- **Hardware Acceleration**: Similar architecture to commercial deep learning accelerators

## 📁 Project Structure

```
mvm-engine/
├── src/
│   ├── dot8.sv          # 8-lane dot product unit (pipelined)
│   ├── accum.sv         # Accumulator with control logic
│   ├── ctrl.sv          # FSM-based controller
│   ├── mvm.sv           # Top-level MVM engine
│   └── mem.sv           # Dual-port memory blocks (provided)
├── testbench/
│   └── mvm_tb.sv        # Comprehensive testbench
├── constraints/
│   └── constraints.xdc  # Timing constraints for synthesis
└── README.md
```

## 🏗️ Architecture

### System Components

1. **Dot Product Unit (`dot8.sv`)**
   - 8-element vector dot product computation
   - Fully pipelined with binary reduction tree
   - Configurable input/output bit widths

2. **Accumulator (`accum.sv`)**
   - Signed integer accumulation with overflow protection
   - First/last signal control for accumulation sequences
   - Configurable accumulation register width

3. **Controller (`ctrl.sv`)**
   - Two-state FSM (IDLE/COMPUTE)
   - Memory address generation and sequencing
   - Control signal orchestration for datapath

4. **Memory System (`mem.sv`)**
   - Dual-port memory blocks (1 read + 1 write port)
   - 2-cycle read/write latency
   - Parameterizable depth and data width

5. **Top-Level Integration (`mvm.sv`)**
   - Vector memory + NUM_OLANES compute lanes
   - Each lane: Matrix memory + Dot product + Accumulator
   - Round-robin matrix row distribution

### Data Layout

The engine uses an optimized memory layout where:
- **Vector data**: Stored as consecutive 8-element words
- **Matrix data**: Rows distributed across compute lanes in round-robin fashion
- **Output**: Parallel computation of result vector elements

## ⚙️ Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `IWIDTH` | Input element bit width | 8 |
| `OWIDTH` | Output element bit width | 32 |
| `NUM_OLANES` | Number of output compute lanes | 4 |
| `MEM_DATAW` | Memory data width | 64 |
| `VEC_MEM_DEPTH` | Vector memory depth | 1024 |
| `MAT_MEM_DEPTH` | Matrix memory depth | 1024 |

## 🔧 Getting Started

### Prerequisites
- Xilinx Vivado 2023.1 or later
- SystemVerilog simulation tools
- PYNQ board (for hardware deployment)

### Setup Instructions

1. **Create Vivado Project**
   ```bash
   # Create new project in Vivado
   # Add all .sv files to project sources
   # Add constraints.xdc to constraints
   ```

2. **Simulation**
   ```bash
   # Set mvm_tb.sv as top-level testbench
   # Run behavioral simulation
   # Verify functionality with provided test vectors
   ```

3. **Synthesis & Implementation**
   ```bash
   # Set timing goal to 150+ MHz
   # Use "-mode out_of_context" for maximum performance
   # Monitor timing closure and resource utilization
   ```

## 🧪 Testing

The project includes a comprehensive testbench (`mvm_tb.sv`) that:
- Generates random test vectors and matrices
- Configures memory layout automatically
- Verifies results against golden reference
- Measures performance metrics

### Running Tests
```systemverilog
// The testbench automatically:
// 1. Writes random data to vector/matrix memories
// 2. Configures start addresses and sizes
// 3. Initiates computation
// 4. Compares results with expected values
// 5. Reports pass/fail status
```

## 📊 Performance Optimization

### Timing Goals
- **Target Frequency**: 150+ MHz
- **Throughput**: Maximized for 512x512 matrices
- **Resource Utilization**: Optimized for PYNQ FPGA

### Optimization Strategies
1. **Pipeline Depth**: Balanced for frequency vs. latency
2. **Parallelism**: Configurable compute lanes
3. **Memory Banking**: Distributed matrix storage
4. **Control Logic**: Minimal FSM overhead

## 🏆 Bonus Challenge

Achieve maximum throughput by:
- Optimizing `NUM_OLANES` for target FPGA
- Maximizing operating frequency
- Minimizing computation cycles for 512x512 MVM
- Using out-of-context synthesis for best results

## 📋 Interface Specifications

### Top-Level Ports
```systemverilog
module mvm #(
    parameter IWIDTH = 8,
    parameter OWIDTH = 32,
    parameter NUM_OLANES = 4,
    // ... other parameters
) (
    input  logic clk,
    input  logic rst,
    
    // Vector memory interface
    input  logic [MEM_DATAW-1:0] i_vec_wdata,
    input  logic [VEC_ADDRW-1:0] i_vec_waddr,
    input  logic i_vec_wen,
    
    // Matrix memory interface  
    input  logic [MEM_DATAW-1:0] i_mat_wdata,
    input  logic [MAT_ADDRW-1:0] i_mat_waddr,
    input  logic [NUM_OLANES-1:0] i_mat_wen,
    
    // Control interface
    input  logic i_start,
    input  logic [VEC_ADDRW-1:0] i_vec_start_addr,
    input  logic [VEC_SIZEW-1:0] i_vec_num_words,
    input  logic [MAT_ADDRW-1:0] i_mat_start_addr,
    input  logic [MAT_SIZEW-1:0] i_mat_num_rows_per_olane,
    
    // Output interface
    output logic o_busy,
    output logic [OWIDTH-1:0] o_result [0:NUM_OLANES-1],
    output logic o_valid
);
```

## 🔍 Implementation Details

### Controller FSM
```
IDLE ──start──→ COMPUTE
 ↑                 │
 └─────done────────┘
```

**IDLE State**: Register input parameters, clear outputs
**COMPUTE State**: Generate addresses, sequence operations

### Pipeline Stages
1. **Memory Read** (2 cycles latency)
2. **Dot Product** (log₂(8) pipeline stages)
3. **Accumulation** (1 cycle)

## 🐛 Debugging Tips

1. **Simulation Waveforms**: Primary debugging approach
2. **Unit Testing**: Create individual testbenches for each module
3. **Timing Analysis**: Check critical paths in synthesis reports
4. **Memory Latency**: Account for 2-cycle read delay in controller

## 📚 References

- Microsoft BrainWave Architecture
- ECE 327 Digital Hardware Systems Course
- Xilinx UltraScale+ FPGA Documentation


## 👥 Contributors

Developed by Talha Amir

---

*"Synthesis is about understanding the whole and the parts at the same time, along with the relationships and the connections that make up the dynamics of the whole."* - Leyla Acaroglu
