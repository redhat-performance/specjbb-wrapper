Automation wrapper for specjbb 2005

Description:
             SPECjbb2005 (Java Server Benchmark) is SPEC's benchmark for evaluating
             the performance of server side Java. Like its predecessor, SPECjbb2000,
             SPECjbb2005 evaluates the performance of server side Java by emulating
             a three-tier client/server system (with emphasis on the middle tier).
             The benchmark exercises the implementations of the JVM (Java Virtual
             Machine), JIT (Just-In-Time) compiler, garbage collection, threads and
             some aspects of the operating system. It also measures the performance
             of CPUs, caches, memory hierarchy and the scalability of shared memory
             processors (SMPs). SPECjbb2005 provides a new enhanced workload,
             implemented in a more object-oriented manner to reflect how real-world
             applications are designed and introduces new features such as XML
             processing and BigDecimal computations to make the benchmark a more
             realistic reflection of today's applications.
             For more information see: https://www.spec.org/jbb2005/
  
Location of underlying workload:
             As specjbb 2005 is a licensed product, you will need to upload the kit to be
             used. Upload location is ~/uploads

Packages required: bc,numactl
Java Version: uses /bin/java

To run:
[root@hawkeye ~]# git clone https://github.com/redhat-performance/specjbb-wrapper
[root@hawkeye ~]# specjbb-wrapper///specjbb/specjbb_run

The script will by default set the starting and ending warehouses based on the size of the system.

Options
/root/specjbb-wrapper///specjbb/specjbb_run --usage
Usage /root/specjbb-wrapper///specjbb/specjbb_run:
  --inc-warehouses: how many warehouses to increment each time, default
    else increment_warehouse=echo 256/8.
  --max_nodes: Runs one jvm per node.
  --node_pinning: If set to y, then will bind to the numa node, default is n.
  --nr-jvms: number of jvms to use, default 1 and the # numa nodes.
  --regression: regression runs, settings, measurement=120, total 8 warehouse data points.
  --start-warehouses: Number of warehouses to start at, default 2, if cpus < 16 else value is calculated.
  --stop-warehouse: Warehouses top stop at.  Default is ncpus.
  --usage: this is usage message.
  --use_pbench_version: Instead of running the wrappers version.
    of specjbb, use pbench-specjbb when pbench is requested.
General options
  --home_parent <value>: Our parent home directory.  If not set, defaults to current working directory.
  --host_config <value>: default is the current host name.
  --iterations <value>: Number of times to run the test, defaults to 1.
  --pbench: use pbench-user-benchmark and place information into pbench, defaults to do not use.
  --pbench_user <value>: user who started everything. Defaults to the current user.
  --pbench_copy: Copy the pbench data, not move it.
  --pbench_stats: What stats to gather. Defaults to all stats.
  --run_label: the label to associate with the pbench run. No default setting.
  --run_user: user that is actually running the test on the test system. Defaults to user running wrapper.
  --sys_type: Type of system working with, aws, azure, hostname.  Defaults to hostname.
  --sysname: name of the system running, used in determing config files.  Defaults to hostname.
  --tuned_setting: used in naming the tar file, default for RHEL is the current active tuned.  For non
    RHEL systems, default is none.
  --usage: this usage message.
