# SPECjbb2005 (Java Server Benchmark) Wrapper

## Description

This wrapper facilitates the automated execution of the SPECjbb2005 benchmark. SPECjbb2005 is SPEC's benchmark for evaluating the performance of server-side Java. It emulates a three-tier client/server system with emphasis on the middle tier, exercising the JVM, JIT compiler, garbage collection, threads, and operating system aspects. It also benchmarks CPUs, caches, memory hierarchy, and SMP scalability. The 2005 version introduced XML processing and BigDecimal computations for more realistic workload representation.

The wrapper provides:
- Automated SPECjbb2005 configuration and execution.
- Automatic warehouse sizing based on system CPU count.
- Support for multiple JVM instances across NUMA nodes.
- Optional NUMA node pinning for memory and CPU binding.
- Configurable Java version selection (11, 17, 21, 23, 24, 25).
- Support for x86_64 and aarch64 architectures.
- Support for multiple OS variants (RHEL, Ubuntu, SLES, Amazon Linux).
- Result collection, processing, and verification.
- CSV and JSON output formats.
- System configuration metadata capture.
- Integration with test_tools framework.
- Optional Performance Co-Pilot (PCP) integration.

For more information see: https://www.spec.org/jbb2005/

## Command-Line Options

```
SPECjbb Options:
  --inc-warehouses <value>: How many warehouses to increment each time.
      Default is end_warehouse/8 for systems with > 16 CPUs, else 2.
  --java_exec <path>: Path to the Java executable to use.
      Default is auto-detected based on OS and java_version.
  --java_version <number>: Version of Java to run (11, 17, 21, 23, 24, 25).
      Default is 21.
  --max_jvms: Run one JVM per NUMA node (sets nr_jvms to number of NUMA nodes).
  --node_pinning <y|n>: Bind JVMs to NUMA nodes using numactl. Default is n.
  --nr-jvms <value>: Number of JVMs to use. Default is 1 and the number of NUMA nodes.
      Accepts comma-separated list (e.g., "1,node" to run with 1 JVM then all nodes).
  --regression: Regression mode with reduced settings (measurement=120s, 8 warehouse data points).
  --runtime <seconds>: Seconds to run the test for.
  --specjbb_kit <filename>: Name of the SPECjbb2005 kit archive in ~/uploads.
      Default is the most recent SPECjbb2005_kit* file found in ~/uploads.
  --start-warehouses <value>: Number of warehouses to start at.
      Default is calculated based on CPU count; 2 if CPUs <= 16.
  --stop-warehouses <value>: Number of warehouses to stop at. Default is 2x the number of CPUs.
  --usage: Display this usage message.

General test_tools options:
  --debug: Enable bash -x debug output for wrapper troubleshooting.
  --home_parent <value>: Parent home directory. If not set, defaults to current working directory.
  --host_config <value>: Host configuration name, defaults to current hostname.
  --iterations <value>: Number of times to run the test, defaults to 1.
  --json_skip: Skip JSON conversion of test CSV results.
  --no_pkg_install: Do not install any packages (system or pip). Useful for pre-provisioned systems.
  --no_system_packages: Do not install system packages via the package manager. Pip packages are still installed.
  --no_pip_packages: Do not install Python pip packages. System packages are still installed.
  --run_label <value>: Label to associate with the run. No default.
  --run_user: User that is actually running the test on the test system. Defaults to current user.
  --sys_type: Type of system working with (aws, azure, hostname). Defaults to hostname.
  --sysname: Name of the system running, used in determining config files. Defaults to hostname.
  --test_tools_release <tag>: Version tag of test_tools-wrappers to check out and use.
  --tuned_setting: Used in naming the results directory. For RHEL, defaults to current active tuned profile.
      For non-RHEL systems, defaults to 'none'. If set to a profile name, activates that tuned profile.
  --use_pcp: Enable Performance Co-Pilot monitoring during test execution.
  --verify_skip: Skip result verification against the Pydantic schema.
  --tools_git <value>: Git repo to retrieve the required tools from.
      Default: https://github.com/redhat-performance/test_tools-wrappers
  --usage: Display this usage message.
```

## What the Script Does

The `specjbb_run` script performs the following workflow:

1. **Environment Setup**:
   - Archives any previous SPECjbb results from `/tmp` into a timestamped archive directory.
   - Clones the test_tools-wrappers repository if not present (default: ~/test_tools).
   - Sources error codes and general setup utilities.
   - Gathers hardware information via `gather_data`.

2. **Package Installation**:
   - Installs required base dependencies via package_tool using `specjbb.json` (bc, zip, unzip, numactl, git).
   - Installs Java packages for the selected version via the corresponding `specjbb_<version>.json` file.
   - Dependencies are defined for different OS variants (RHEL, Ubuntu, SLES, Amazon Linux).

3. **Java Detection**:
   - **RHEL/CentOS/Amazon Linux**: Uses `/etc/alternatives/jre_<version>/bin/java`.
   - **Ubuntu**: Uses `/usr/lib/jvm/java-<version>-openjdk-*/bin/java`.

4. **Warehouse Sizing**:
   - Automatically detects the number of CPUs in the system.
   - Calculates ending warehouse count as 2x the number of logical CPUs.
   - For systems with > 16 CPUs: calculates start and increment warehouses to produce ~8 data points.
   - For systems with <= 16 CPUs: starts at 2 warehouses, incrementing by 2.
   - In regression mode: uses 8 evenly-spaced warehouse data points with 120s measurement time.

5. **SPECjbb Kit Extraction**:
   - Locates the SPECjbb2005 kit archive in `~/uploads` (or uses `--specjbb_kit` path).
   - Extracts the kit into the script's working directory.

6. **JVM Configuration**:
   - Determines number of JVMs to run based on `--nr-jvms` or `--max_jvms` settings.
   - Calculates Java heap size (`-Xms`/`-Xmx`) based on CPU count and number of JVMs.
   - Scales stack size proportionally: base of 8192 MiB, increasing every 256 CPUs per JVM.

7. **Test Execution**:
   - Generates a `prop.file` from `SPECjbb.props` with calculated warehouse and timing parameters.
   - For multi-JVM runs: starts a SPECjbb Controller process first, then launches individual JVM instances.
   - Optionally binds each JVM to its corresponding NUMA node via `numactl --membind --cpunodebind` when `--node_pinning y` is set.
   - Each JVM runs `spec.jbb.JBBmain` with the generated properties file.
   - Waits for all JVM processes to complete.
   - Executes for the specified number of iterations.

8. **Data Collection**:
   - Captures system configuration (CPU, memory, NUMA topology, kernel version) via the per-JVM `run.sh` helper.
   - Records SPECjbb output files with warehouse counts and business operations per second (BOPs).
   - Logs timestamps for each test run.
   - Optionally records PCP performance data.

9. **Result Processing**:
   - Extracts warehouse and BOPs data from SPECjbb output files.
   - For multi-JVM runs: sums warehouse counts and BOPs across all JVMs.
   - Sorts data by warehouse count and generates CSV with aggregated results.
   - Creates JSON output for verification.

10. **Verification**:
    - Validates results against the Pydantic schema (`results_schema.py`).
    - Ensures all required fields are present and valid (Warehouses > 0, Bops > 0, Numb_JVMs > 0, timestamps).
    - Uses `csv_to_json` and `verify_results` from test_tools.

11. **Output**:
    - Creates timestamped results directory in `/tmp/results_specjbb_<tuned>_<YYYY.MM.DD-HH.MM.SS>`.
    - Saves raw SPECjbb output files, processed CSV/JSON, and system metadata.
    - Optionally saves PCP performance data.
    - Archives results to configured storage location via `save_results`.

## Dependencies

**Location of underlying workload**: SPECjbb2005 is a licensed product. You must upload the kit yourself. Place the `SPECjbb2005_kit*` archive in `~/uploads`. The wrapper will automatically locate and extract the most recent kit found in that directory.

**General packages required**: bc, zip, unzip, numactl, git

**Java packages** (installed automatically based on `--java_version`):
- **Java 21** (default):
  - RHEL: java-21-openjdk-headless
  - Ubuntu: openjdk-21-jre-headless
  - SLES: java-21-openjdk
  - Amazon Linux: java-21-amazon-corretto
- **Java 17**:
  - Ubuntu: openjdk-17-jre-headless
  - SLES: java-17-openjdk
  - Amazon Linux: java-17-amazon-corretto
- **Java 11**:
  - Ubuntu: openjdk-11-jre-headless
  - SLES: java-11-openjdk
  - Amazon Linux: java-11-amazon-corretto
- **Java 23**: Amazon Linux only (java-23-amazon-corretto)
- **Java 24**: Amazon Linux only (java-24-amazon-corretto)
- **Java 25**: Ubuntu only (openjdk-25-jre-headless)

To run:
```bash
# Upload your SPECjbb2005 kit first
cp SPECjbb2005_kit*.tar.gz ~/uploads/

# Clone and run
git clone https://github.com/redhat-performance/specjbb-wrapper
cd specjbb-wrapper/specjbb
./specjbb_run
```

The script will automatically detect the system size and select appropriate warehouse parameters.

## The SPECjbb2005 Benchmark

SPECjbb2005 (Java Business Benchmark) emulates a three-tier client/server system, focusing on the middle (business logic) tier. It models a wholesale company with warehouses and associated sales districts.

### Key SPECjbb Parameters

1. **Warehouses**: The primary scaling parameter. Each warehouse represents an independent unit of work. More warehouses means more concurrent threads and higher system utilization. The wrapper automatically scales warehouses based on CPU count.

2. **JVM Instances**: The number of independent Java Virtual Machine processes. Running one JVM per NUMA node can improve memory locality. The wrapper supports 1 to N JVMs, where N is the number of NUMA nodes.

3. **Ramp-up Time**: Warm-up period (in seconds) before measurement begins. Default is 60 seconds. Allows the JIT compiler to optimize hot paths.

4. **Measurement Time**: Duration (in seconds) of the actual measurement period. Default is 60 seconds; regression mode uses 120 seconds.

5. **Performance Metric**: SPECjbb2005 reports performance in **BOPs** (Business Operations Per Second). Higher values indicate better performance. Results are reported per warehouse count, producing a throughput curve.

### Multi-JVM Architecture

When running with multiple JVMs (`--nr-jvms` > 1 or `--max_jvms`):
- A **Controller** process (`spec.jbb.Controller`) is started first to coordinate the run.
- Individual **JBBmain** processes are launched for each JVM instance.
- Each JVM handles a subset of the total warehouses (total warehouses / number of JVMs).
- Results from all JVMs are summed to produce the aggregate throughput.

## Output Files

The results directory contains:

- **results_specjbb.csv**: CSV file with warehouse counts, BOPs, and JVM configuration.
- **results_specjbb.json**: JSON output validated against the Pydantic schema.
- **SPEC\*.txt**: Raw SPECjbb output files with detailed per-warehouse results.
- **\*.run.sh.out.\***: Per-JVM output files with system metadata and benchmark results.
- **test_results_report**: File indicating test status ("Ran" or "Failed").
- **meta_data\*.yml**: System metadata (CPU info, memory, NUMA topology, kernel version).
- **PCP data** (if --use_pcp option used): Performance Co-Pilot monitoring data.

### Results Schema

Results are validated against the following Pydantic schema (`results_schema.py`):

| Field | Type | Constraint |
|-------|------|------------|
| Warehouses | int | > 0 |
| Bops | int | > 0 |
| Numb_JVMs | int | > 0 |
| Start_Date | datetime | required |
| End_Date | datetime | required |

## Examples

### Basic run with defaults
```bash
./specjbb_run
```
This runs with:
- Java 21
- Automatic warehouse sizing based on CPU count
- 1 iteration
- 1 JVM
- No NUMA pinning

### Run with a specific Java version
```bash
./specjbb_run --java_version 17
```
Uses Java 17 instead of the default Java 21.

### Run one JVM per NUMA node
```bash
./specjbb_run --max_jvms
```
Launches one JVM per NUMA node for optimal memory locality.

### Run with NUMA node pinning
```bash
./specjbb_run --max_jvms --node_pinning y
```
Launches one JVM per NUMA node and binds each JVM to its corresponding NUMA node using `numactl`.

### Run with specific number of JVMs
```bash
./specjbb_run --nr-jvms 4
```
Runs with exactly 4 JVM instances.

### Run with custom warehouse range
```bash
./specjbb_run --start-warehouses 8 --stop-warehouses 128 --inc-warehouses 8
```
Tests from 8 to 128 warehouses, incrementing by 8 each step.

### Run multiple iterations
```bash
./specjbb_run --iterations 3
```
Runs the benchmark 3 times to check consistency.

### Run regression test
```bash
./specjbb_run --regression
```
Runs with reduced settings: 120-second measurement, 8 warehouse data points. When combined with node counts, runs with 1 node and the maximum number of nodes.

### Run with PCP monitoring
```bash
./specjbb_run --use_pcp
```
Collects Performance Co-Pilot data during the run.

### Specify a particular SPECjbb kit
```bash
./specjbb_run --specjbb_kit SPECjbb2005_kit_v1.07.tar.gz
```
Uses the specified kit archive from `~/uploads` instead of auto-detecting the most recent one.

### Combination example
```bash
./specjbb_run --max_jvms --node_pinning y --java_version 21 --iterations 3 --use_pcp
```
Runs one JVM per NUMA node with pinning, uses Java 21, runs 3 iterations, and collects PCP data.

## How Warehouse Sizing Works

The script automatically calculates SPECjbb warehouse parameters based on system hardware:

### Ending Warehouse Count
1. Detects the number of logical CPUs in the system.
2. Sets the ending warehouse count to 2x the logical CPU count.
3. Can be overridden with `--stop-warehouses`.

### Starting Warehouse Count
1. For systems with > 16 CPUs: calculated to produce approximately 8 data points across the warehouse range.
   All divisions use integer arithmetic (bash `bc`), so results are truncated toward zero.
   ```
   increment = end_warehouse / 8          (integer division)
   start = (end_warehouse - (increment * 8)) + increment
   ```
2. For systems with <= 16 CPUs: starts at 2.
3. Can be overridden with `--start-warehouses`.

### Increment
1. For systems with > 16 CPUs: `end_warehouse / 8` (integer division, truncated toward zero).
2. For systems with <= 16 CPUs: 2.
3. Can be overridden with `--inc-warehouses`.

### Multi-JVM Adjustment
When running with multiple JVMs, the warehouse parameters are divided by the number of JVMs:
- Each JVM runs `end_warehouse / nr_jvms` warehouses.
- Increment and starting warehouses are similarly divided.
- Results are aggregated across JVMs during post-processing.

### Regression Mode
When `--regression` is used:
- Measurement time is set to 120 seconds.
- Increment is recalculated to produce exactly 8 data points.
- The benchmark is run with 1 node and the maximum number of nodes.

## How JVM Stack Sizing Works

The wrapper automatically calculates the Java heap size based on system resources:

1. Detects the total number of logical CPUs.
2. Doubles the CPU count for the calculation basis (`wcpus = cpus * 2`).
3. Calculates stack size using:
   ```
   stack_size = (1 + ((wcpus / 256) / act_jvms)) * 8192 MiB
   ```
4. On systems with <= 256 CPUs per JVM, each JVM gets 8192 MiB of heap.
5. On larger systems, heap scales proportionally to prevent premature termination.
6. Both `-Xms` and `-Xmx` are set to the same value to avoid heap resizing overhead.

## Return Codes

The script uses standardized error codes from test_tools error_codes:
- **0**: Success
- **101**: Git clone failure (test_tools repository)
- **E_GENERAL**: General execution errors (package installation failures, kit extraction failures, JVM launch failures).
- **E_NO_ARGS**: Missing required arguments
- **E_PARSE_ARGS**: Argument parsing failure
- **E_USAGE**: Invalid usage/arguments

A non-zero return code from `verify_results` indicates that the output data did not pass schema validation.

## Notes

### Licensed Workload
SPECjbb2005 is a licensed product from SPEC. The wrapper does not include the benchmark kit. You must obtain a license and upload the kit archive (`SPECjbb2005_kit*.tar.gz`) to `~/uploads` before running the wrapper.

### Architecture Support
- **x86_64**: Full support for AMD and Intel CPUs.
- **aarch64**: Supported. The per-JVM launcher adjusts the thread stack size (`-Xss448k` for aarch64 vs. `-Xss330k` for x86_64).

### Java Version Support
- Java 21 is the default and has the broadest OS support (RHEL, Ubuntu, SLES, Amazon Linux).
- Java 11 and 17 are supported on Ubuntu, SLES, and Amazon Linux (no RHEL package defined).
- Java 23 and 24 are only available on Amazon Linux (Corretto).
- Java 25 is only available on Ubuntu.
- Java 11 disables the `-XX:+AggressiveOpts` JVM flag (deprecated in later versions).

### NUMA Considerations
- For multi-socket systems, running one JVM per NUMA node (`--max_jvms`) typically improves performance by maintaining memory locality.
- Adding `--node_pinning y` further improves consistency by binding each JVM to its NUMA node via `numactl --membind --cpunodebind`.
- Single-node systems should use a single JVM (the default).

### Performance Tips
- Run multiple iterations to verify consistency.
- Ensure the system is idle (no other workloads) for best results.
- Consider the active tuned profile on RHEL systems.
- Use `--max_jvms --node_pinning y` on multi-socket systems for optimal throughput.
- The default warehouse range is designed to capture the throughput curve from low to high utilization.

### Data Reduction Utility
The repository includes `reduce_jbb.sh`, a standalone post-processing tool. When you have multiple SPECjbb result files from separate runs, it:
1. Combines all result files.
2. For each warehouse count, sorts the BOPs values.
3. Removes the highest and lowest values (trimmed mean).
4. Averages the remaining values.
5. Outputs the reduced data to `spec_sum.results`.

Usage:
```bash
cd <directory_with_SPEC_txt_files>
/path/to/reduce_jbb.sh
cat spec_sum.results
```

### Troubleshooting
- If the SPECjbb kit is not found, verify it is placed in `~/uploads` and the filename begins with `SPECjbb2005_kit`.
- If Java is not found, verify the correct version is installed and check the path in `/etc/alternatives/` (RHEL) or `/usr/lib/jvm/` (Ubuntu).
- If performance is unexpectedly low, check NUMA topology and consider using `--max_jvms --node_pinning y`.
- If JVMs terminate early on large systems, the wrapper should auto-scale the heap size, but you can verify by checking the stack_size calculation in the output.
- Use `--use_pcp` to collect detailed performance counters for analysis.
- For regression testing, use `--regression` to reduce run time while still producing meaningful results.
