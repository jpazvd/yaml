{smcl}
{* *! version 1.4.0  04Feb2026}{...}
{viewerjumpto "Overview" "yaml_whatsnew##overview"}{...}
{viewerjumpto "Version history" "yaml_whatsnew##history"}{...}

{title:yaml: What's new}

{marker overview}{...}
{title:Overview}

{pstd}
This file tracks feature updates to the {cmd:yaml} command.

{marker history}{...}
{title:Version history}

{pstd}{bf:1.5.0} (04Feb2026)
{p 4 8 2}- Added canonical early-exit targets and streaming tokenization options.{p_end}
{p 4 8 2}- Added index frame materialization for repeated queries (Stata 16+).{p_end}
{p 4 8 2}- Added fast-scan block-scalar capture and unsupported-feature checks.{p_end}
{p 4 8 2}- Added file readability and empty-file checks for yaml read.{p_end}
{p 4 8 2}- Added benchmark script and performance targets in scripts/benchmark_yaml_parse.do.{p_end}

{pstd}{bf:1.4.0} (04Feb2026)
{p 4 8 2}- Added {cmd:fastscan} mode for speed-first parsing of large, regular YAML files.{p_end}
{p 4 8 2}- Added {cmd:fields()} to restrict extraction to specific keys.{p_end}
{p 4 8 2}- Added {cmd:listkeys()} for list-block extraction in fast-scan mode.{p_end}
{p 4 8 2}- Added {cmd:cache()} to store parsed output in a frame (Stata 16+).{p_end}
{p 4 8 2}- Updated help examples to show fast-scan usage.{p_end}

{pstd}{bf:1.3.1} (17Dec2025)
{p 4 8 2}- Fixed return value propagation from frame context in {cmd:yaml get} and {cmd:yaml list}.{p_end}
{p 4 8 2}- Fixed hyphen-to-underscore normalization in {cmd:yaml get} search prefix.{p_end}
