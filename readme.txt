*! readme.txt for yaml package
*! Author: João Pedro Azevedo
*! Version: 2.0.0
*! Date: July 2026

TITLE
    yaml: Stata module for YAML file processing

DESCRIPTION
    yaml is a unified Stata command for reading, writing, and manipulating
    YAML configuration files. It provides a complete interface through nine
    subcommands that enable Stata users to integrate YAML-based workflows
    into their data pipelines.

    The command implements a restricted block-style subset of YAML 1.2
    (3rd Edition, 2021), the current authoritative YAML standard. This
    subset covers the most commonly used features for configuration files
    and metadata management.

    Since v1.7.0 the command includes a high-performance Mata-based bulk
    parser with optional wide-format collapse, and since v1.9.0 a one-step
    indicators preset for wbopendata/unicefdata metadata files.

SUBCOMMANDS
    yaml read      - Parse YAML file into Stata dataset or frame
    yaml write     - Export dataset or frame back to YAML format
    yaml describe  - Display structure of loaded YAML data
    yaml list      - List keys, values, or children of a key
    yaml get       - Retrieve attributes of a specific key
    yaml validate  - Validate required keys and types
    yaml dir       - List all YAML data in memory (dataset and frames)
    yaml frames    - List all YAML frames in memory (Stata 16+)
    yaml clear     - Clear YAML data from memory

FILES
    Source (src/y/):
    yaml.ado                    - Main command dispatcher
    yaml_read.ado               - Read YAML file into dataset or frame
    yaml_write.ado              - Write dataset or frame to YAML
    yaml_describe.ado           - Display YAML structure
    yaml_list.ado               - List keys and values
    yaml_get.ado                - Retrieve key attributes
    yaml_validate.ado           - Validate required keys and types
    yaml_dir.ado                - List YAML data in memory
    yaml_frames.ado             - List YAML frames in memory
    yaml_clear.ado              - Clear YAML data from memory
    yaml.sthlp                  - Help documentation
    yaml_examples.sthlp         - Usage examples
    yaml_whatsnew.sthlp         - Version history

    Internal helpers (src/_/):
    _yaml_fastread.ado          - Fast-read parser helper
    _yaml_tokenize_line.ado     - Streaming tokenization helper
    _yaml_mataread.ado          - Mata bulk-load parser
    _yaml_collapse.ado          - Wide-format collapse helper

    Example files (in examples/):
    yaml_basic_examples.do       - Basic examples for all yaml subcommands
    yaml_basic_examples.log      - Log file from basic examples

    Sample YAML files (in examples/data/):
    config.yaml             - Sample project configuration
    indicators.yaml         - Sample indicator metadata
    settings.yaml           - Sample data processing settings
    pipeline_config.yaml    - Sample pipeline configuration
    test_config.yaml        - Basic test configuration
    test_config2.yaml       - Extended test configuration
    unicef_indicators.yaml  - UNICEF indicator metadata
    unicef_dataflows.yaml   - UNICEF dataflow metadata
    fastread_indicators.yaml - Large indicator file for fastread/bulk

INSTALLATION
    Copy all package files from src/y/ and src/_/ (see src/yaml.pkg)
    to your personal ado directory.

    . adopath
    * Copy files to the PERSONAL directory shown

    Alternatively, if distributed via SSC:
    . ssc install yaml

REQUIREMENTS
    Stata 14.0 or later (basic functionality)
    Stata 16.0 or later (frame support)

EXAMPLES
    Basic usage:

    . yaml read using "config.yaml", replace
    . yaml describe
    . yaml get database:host
    . yaml list indicators, keys children

    Bulk parsing and collapse (Stata 16+):

    . yaml read using "indicators.yaml", bulk replace
    . yaml read using "indicators.yaml", bulk collapse replace

    Indicators preset (one-step metadata parsing):

    . yaml read using "unicef_indicators.yaml", indicators replace

QA TESTING
    The package includes an automated QA suite (qa/run_tests.do) with 27
    tests organized in five categories:

    ENV-01 to ENV-03   - Environment checks (command, help, version)
    EX-01  to EX-03    - Example smoke tests
    REG-01 to REG-09   - Regression tests (BUG-1 through BUG-9)
    FEAT-01 to FEAT-09 - Feature tests (v1.6.0 through v1.8.0 features)
    INT-01 to INT-03   - Integration tests (downstream packages, version sync)

    Latest QA run:
    Date:     06 Jul 2026
    Version:  2.0.0
    Stata:    17
    Tests:    27 run, 27 passed, 0 failed
    Result:   ALL TESTS PASSED

VERSION HISTORY
    2.0.0  (06Jul2026) - Sequences of mappings, unified quoting,
                         write fidelity, multi-level get paths, r(found)
    1.9.2  (22Feb2026) - Parser parity fixes (list-item quotes, parent_stack)
    1.9.0  (20Feb2026) - INDICATORS preset for wbopendata/unicefdata
    1.8.0  (20Feb2026) - Collapse filter options: colfields(), maxlevel()
    1.7.0  (20Feb2026) - Mata bulk-load, collapse, strL support
    1.6.0  (18Feb2026) - Block scalars, continuation lines, embedded quotes
    1.5.1  (18Feb2026) - Bug fixes (BUG-1/2/3), abbreviations, error messages
    1.5.0  (04Feb2026) - Streaming tokenization, index frames, benchmarks
    1.4.0  (04Feb2026) - Fast-read mode, fields(), listkeys(), cache()
    1.3.1  (17Dec2025) - Frame return-value fix, hyphen normalization

NOTES
    - The implementation is pure Stata with no external dependencies
    - Targets a restricted block-style subset of the YAML 1.2 specification
    - Block scalars and continuation lines are supported since v1.6.0
    - Advanced YAML features (anchors, aliases, flow style) are not supported
    - All dataset names should be lowercase for cross-platform compatibility

REFERENCES
    Ben-Kiki, O., Evans, C., & döt Net, I. (2021). YAML Ain't Markup Language
    (YAML™) Version 1.2 (Revision 1.2.2). https://yaml.org/spec/1.2.2/

CONTACT
    João Pedro Azevedo
    UNICEF, Division of Data, Analytics, Planning and Monitoring
    jpazevedo@unicef.org

ALSO SEE
    Project repository: https://github.com/jpazvd/yaml
