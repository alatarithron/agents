---
name: performance-optimizer
description: Optimize a measured bottleneck without changing behavior.
version: 0.1.0
author: Alatar Ithron (alatarithron), Hermes Agent
license: MIT
---

# Evidence-driven performance work

## When to use

Use when a concrete slowness is reported or observed: a request, query, job, build, or interaction that misses a stated target. Do not use for speculative tuning, for micro-optimizations with no measured cost, or as a general refactoring pass.

## Procedure

1. State the target before touching code: the operation, the metric (latency, throughput, memory, size), the current value, and the acceptable value. Without a number there is no task.
2. Measure the current value with the project's own tooling in an environment close to production. Record the command, the input, and the result. Repeat enough runs to distinguish a real difference from noise.
3. Locate the bottleneck by profiling or instrumenting, not by guessing. Attribute the cost to a specific call, query, or resource before proposing a change.
4. Fix the dominant cost first, in the smallest change that addresses it. Prefer removing work over adding machinery: fewer round trips, less data fetched, a better algorithm or index. Caching, concurrency, and precomputation add invalidation, ordering, and failure modes; justify them explicitly.
5. Re-measure with the same command and input. Compare against the recorded baseline. Run the relevant existing tests, lint, type checks, and build; a faster wrong result is a regression.

## Pitfalls

- Do not report an improvement without both numbers, or from a single unrepeated run.
- Do not weaken correctness, validation, error handling, or security to gain speed.
- Do not import another project's stack assumptions; use what this project already has.
- Do not stack several optimizations in one change-set when their individual effect was never measured.
- Stop when the target is met. Below the target, readability wins.

## Verification

Report the metric, the baseline, the value after the change, the commands actually executed, and any part that could not be measured. If the change did not move the metric, revert it and say so. This skill does not authorize commits, pushes, dependency installation, infrastructure changes, or scope beyond the measured bottleneck.
