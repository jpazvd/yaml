*! readme.txt for yaml package
*! Author: João Pedro Azevedo
*! Version: 1.3.0
*! Date: December 2025

TITLE
    yaml: Stata module for YAML file processing

DESCRIPTION
    yaml is a unified Stata command for reading, writing, and manipulating 
    YAML configuration files. It provides a complete interface through nine 
    subcommands that enable Stata users to integrate YAML-based workflows 
    into their data pipelines.

    The command implements the JSON Schema subset of YAML 1.2 (3rd Edition, 
    2021), the current authoritative YAML standard. This JSON-compatible 
    subset covers the most commonly used features for configuration files 
    and metadata management.

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
    yaml.ado                    - Main command file
    yaml.sthlp                  - Help documentation
    
    Example files (in examples/):
    yaml_sj_article_examples.do  - Do-file reproducing Stata Journal article examples
    yaml_sj_article_examples.log - Log file from example execution
    yaml_basic_examples.do       - Basic examples for all yaml subcommands
    yaml_basic_examples.log      - Log file from basic examples

    Sample YAML files (in examples/data/):
    config.yaml             - Sample project configuration
    indicators.yaml         - Sample indicator metadata
    settings.yaml           - Sample data processing settings
    pipeline_config.yaml    - Sample pipeline configuration
    test_config.yaml        - Basic test configuration
    test_config2.yaml       - Extended test configuration

INSTALLATION
    Copy yaml.ado and yaml.sthlp to your personal ado directory.
    
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

NOTES
    - The implementation is pure Stata with no external dependencies
    - Targets the JSON-compatible subset of YAML 1.2 specification
    - Advanced YAML features (anchors, aliases, block scalars, flow style) 
      are not supported
    - All dataset names should be lowercase for cross-platform compatibility

REFERENCES
    Ben-Kiki, O., Evans, C., & döt Net, I. (2021). YAML Ain't Markup Language 
    (YAML™) Version 1.2 (Revision 1.2.2). https://yaml.org/spec/1.2.2/

CONTACT
    João Pedro Azevedo
    UNICEF, Division of Data, Analytics, Planning and Monitoring
    jpazevedo@unicef.org

ALSO SEE
    Stata Journal article: "Reading and writing YAML files in Stata: 
    A lightweight framework for reproducible and cross-platform analytics"
