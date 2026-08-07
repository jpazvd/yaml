{smcl}
{* *! version 2.0.1  06Aug2026}{...}
{vieweralsosee "yaml examples" "help yaml_examples"}{...}
{vieweralsosee "yaml what's new" "help yaml_whatsnew"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] import delimited" "help import delimited"}{...}
{vieweralsosee "[R] frames" "help frames"}{...}
{viewerjumpto "Syntax" "yaml##syntax"}{...}
{viewerjumpto "Description" "yaml##description"}{...}
{viewerjumpto "Subcommands" "yaml##subcommands"}{...}
{viewerjumpto "Examples" "yaml##examples"}{...}
{viewerjumpto "Stored results" "yaml##results"}{...}
{viewerjumpto "Limitations" "yaml##limitations"}{...}
{viewerjumpto "References" "yaml##references"}{...}
{viewerjumpto "Author" "yaml##author"}{...}
{hline}
{cmd:help yaml}{right:{bf:version 2.0.1}}
{hline}

{title:Title}

{phang}
{bf:yaml} {hline 2} Read and write YAML files in Stata


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:yaml} {it:subcommand} [{cmd:using} {it:filename}] [{cmd:,} {it:options}]


{marker subcommands}{...}
{title:Subcommands}

{synoptset 16 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{opt read}}read YAML file into current dataset (default) or frame{p_end}
{synopt:{opt write}}write Stata data to YAML file{p_end}
{synopt:{opt describe}}display structure of loaded YAML data{p_end}
{synopt:{opt list}}list keys and values{p_end}
{synopt:{opt get}}get metadata attributes for a specific key{p_end}
{synopt:{opt validate}}validate YAML data against requirements{p_end}
{synopt:{opt dir}}list all YAML data in memory (dataset and frames){p_end}
{synopt:{opt frames}}list only YAML frames in memory (Stata 16+){p_end}
{synopt:{opt clear}}clear YAML data from memory{p_end}
{synoptline}
{p2colreset}{...}
{pstd}
See {bf:{help yaml_whatsnew:What's New}} for version history.
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:yaml} provides a unified interface for working with YAML files in Stata.
YAML (YAML Ain't Markup Language) is a human-readable data serialization format 
commonly used for configuration files and data exchange.

{pstd}
{bf:Default behavior:} YAML data is loaded into the {bf:current dataset}.
This allows the command to work with Stata 14 and later.

{pstd}
{bf:Frame option:} Use {opt frame(name)} to store YAML data in a separate Stata
frame, allowing multiple YAML files in memory simultaneously. This requires
Stata 16 or later. The argument is a {it:logical} name: the {cmd:yaml_} prefix
is added automatically (and is idempotent, so {cmd:frame(cfg)} and
{cmd:frame(yaml_cfg)} both address frame {cmd:yaml_cfg}). {cmd:r(frame)}
reports the full frame name, including the prefix (e.g., {cmd:yaml_cfg}).


{marker read}{...}
{title:yaml read}

{p 8 17 2}
{cmd:yaml read}
{cmd:using} {it:filename}
[{cmd:,} {opt frame(name)} {opt l:ocals} {opt s:calars} {opt p:refix(string)} {opt replace} {opt v:erbose}
{opt fastread} {opt fields(string)} {opt listkeys(string)} {opt cache(string)}]

{pstd}
Reads a YAML file and parses its contents into the current dataset (default) or a frame.

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt frame(name)}}load into frame yaml_{it:name} instead of dataset (Stata 16+){p_end}
{synopt:{opt l:ocals}}also store values as local macros in r(){p_end}
{synopt:{opt s:calars}}also store numeric values as Stata scalars{p_end}
{synopt:{opt p:refix(string)}}prefix for macro/scalar names; default is "yaml_"{p_end}
{synopt:{opt replace}}replace existing data in memory{p_end}
{synopt:{opt v:erbose}}display parsing progress{p_end}
{synopt:{opt fastread}}use fast-read parser (speed-first, limited YAML subset){p_end}
{synopt:{opt fields(string)}}restrict extraction to specific field keys{p_end}
{synopt:{opt listkeys(string)}}extract list blocks for specified fields (fastread only){p_end}
{synopt:{opt blockscalars}}capture block scalars ({cmd:|}, {cmd:>}) in any parse mode (opt-in){p_end}
{synopt:{opt targets(string)}}early-exit targets for canonical parse (exact keys){p_end}
{synopt:{opt earlyexit}}stop parsing once all targets are found (canonical){p_end}
{synopt:{opt stream}}use streaming tokenization for canonical parse{p_end}
{synopt:{opt index(string)}}materialize an index frame for repeated queries; the name takes the {cmd:yaml_} prefix like {opt frame()} (Stata 16+){p_end}
{synopt:{opt cache(string)}}cache parsed results in a frame (Stata 16+){p_end}
{synopt:{opt bulk}}use Mata bulk-load parser for high-performance parsing{p_end}
{synopt:{opt collapse}}produce wide-format output (one row per top-level key){p_end}
{synopt:{opt colfields(string)}}filter collapsed output to specific field names (semicolon-separated){p_end}
{synopt:{opt maxlevel(#)}}limit collapsed columns by depth (1=no underscores, 2=one underscore, etc.){p_end}
{synopt:{opt indicators}}preset for wbopendata/unicefdata indicator metadata (implies bulk collapse){p_end}
{synopt:{opt strl}}use strL storage for values exceeding 2045 characters{p_end}
{synoptline}

{pstd}
{opt fastread} is not compatible with {opt locals} or {opt scalars}.

{pstd}
{opt targets()} and {opt earlyexit} apply to canonical parsing only and are not supported
with {opt fastread}.

{pstd}
{opt cache()} accepts a frame name (e.g., {cmd:cache(mycache)}) or a named form
{cmd:cache(frame=mycache)}. The stored frame is prefixed as {cmd:yaml_} if not already.

{pstd}
The following variables are created in canonical mode:
{p_end}
{phang2}{cmd:key} - Full key name (nested keys use underscore separator){p_end}
{phang2}{cmd:value} - Value as string{p_end}
{phang2}{cmd:level} - Nesting level (1 = root){p_end}
{phang2}{cmd:parent} - Parent key name{p_end}
{phang2}{cmd:type} - Value type (string, numeric, boolean, null, parent, list_map){p_end}

{pstd}
In {opt fastread} mode, the following variables are created:{p_end}
{phang2}{cmd:key} - Top-level key (e.g., indicator code){p_end}
{phang2}{cmd:field} - Field name under the key{p_end}
{phang2}{cmd:value} - Field value{p_end}
{phang2}{cmd:list} - 1 if list item, 0 otherwise{p_end}
{phang2}{cmd:line} - Line number in the YAML file{p_end}

{pstd}
{bf:Sequences of mappings:} list items that are themselves mappings
({cmd:- key: value}, including nested mappings under the item) are supported
by the canonical parser. Each item is stored as a structural row
{it:list}_{it:N} of type {cmd:list_map}, with the item's keys as its
children; {cmd:yaml write} re-emits these rows in dash form. The {opt bulk}
and {opt fastread} parsers {bf:reject} such items with an explicit error
instead of storing a corrupted representation.

{pstd}
{bf:Quoting:} one rule applies in all parse modes (canonical, fast-read,
bulk): surrounding quotes are stripped only when the first and last
characters of the value are the same quote character; quoted values are
always typed {cmd:string}; escape sequences are kept literal.

{pstd}
{bf:Performance options:} the following opt-in options trade generality for
speed on large files; see {help yaml_whatsnew:what's new} for details.
{p_end}
{phang2}{opt bulk} uses a Mata bulk-load parser that reads the whole file
into memory for vectorized processing; unlike the canonical parser, it
preserves dots and hyphens in key names (useful for entity codes).{p_end}
{phang2}{opt collapse} produces wide-format output with one row per
top-level key (commonly combined with {opt bulk}); {opt colfields(string)}
restricts the columns to named fields (semicolon-separated) and
{opt maxlevel(#)} limits columns by nesting depth.{p_end}
{phang2}{opt strl} stores values as strL, allowing values longer than 2045
characters.{p_end}
{phang2}{opt indicators} is a preset for wbopendata/unicefdata indicator
metadata that enables {opt bulk} and {opt collapse} with a standard
{cmd:colfields()} selection.{p_end}


{marker write}{...}
{title:yaml write}

{p 8 17 2}
{cmd:yaml write}
{cmd:using} {it:filename}
[{cmd:,} {opt frame(name)} {opt scalars(namelist)}
{opt replace} {opt v:erbose} {opt indent(#)} {opt header(string)} {opt ti:mestamp} {opt noheader}]

{pstd}
Writes Stata data from the current dataset (default) or a frame to a YAML file.

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt frame(name)}}write from frame yaml_{it:name} (Stata 16+){p_end}
{synopt:{opt scalars(namelist)}}write specified scalars{p_end}
{synopt:{opt replace}}replace existing file{p_end}
{synopt:{opt v:erbose}}display progress{p_end}
{synopt:{opt indent(#)}}spaces per indent level; default is 2{p_end}
{synopt:{opt header(string)}}custom header comment (replaces the default {cmd:# Generated by Stata yaml write} line){p_end}
{synopt:{opt ti:mestamp}}add a {cmd:# Date:} line to the header; off by default so output is reproducible{p_end}
{synopt:{opt noheader}}omit the header comment entirely{p_end}
{synoptline}

{pstd}
{bf:Required variables:} the dataset (or frame) being written must contain the
canonical variables {cmd:key}, {cmd:value}, {cmd:level}, and {cmd:type};
{cmd:parent} is used, when present, to reconstruct leaf key names. The
fast-read and query-oriented layouts cannot be written back.

{pstd}
{bf:Literal fidelity:} boolean rows are emitted as {cmd:true}/{cmd:false}
(not {cmd:1}/{cmd:0}) and null rows as an empty value ({cmd:key:}), so a
read-write cycle preserves YAML literals. Sequence-of-mappings rows (type
{cmd:list_map}) are re-emitted in dash form, with the item's first key-value
pair folded onto the dash line and the remaining children indented beneath it.

{pstd}
{bf:Reproducible output:} by default the header is a single fixed
{cmd:# Generated by Stata yaml write} line with no wall-clock timestamp, so a
written file is byte-for-byte reproducible across runs (useful under version
control and for regression testing). Specify {opt timestamp} to record a
{cmd:# Date:} line, or {opt noheader} to omit the header comment entirely.

{pstd}
{bf:Note:} rows are written in {it:observation order}. Sorting or dropping
rows between {cmd:yaml read} and {cmd:yaml write} changes the output and can
misplace children relative to their parents; list indices are not
renumbered. Comments and the original quoting style are not preserved: the
output is a normalized rendering of the stored rows.

{pstd}
{bf:Note:} To write scalar values to YAML, create scalars first, then use the {opt scalars()} option.
Local macros cannot be passed to programs in Stata.


{marker describe}{...}
{title:yaml describe}

{p 8 17 2}
{cmd:yaml describe}
[{cmd:,} {opt frame(name)} {opt level(#)}]

{pstd}
Displays the structure of YAML data in the current dataset (default) or a frame.

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt frame(name)}}describe frame yaml_{it:name} (Stata 16+){p_end}
{synopt:{opt level(#)}}maximum nesting level to display; default is all{p_end}
{synoptline}


{marker list}{...}
{title:yaml list}

{p 8 17 2}
{cmd:yaml list}
[{it:parent}]
[{cmd:,} {opt frame(name)} {opt keys} {opt values} {opt sep:arator(string)} {opt child:ren} {opt stata} {opt noh:eader}]

{pstd}
Lists keys and values from YAML data. Optional {it:parent} filters to keys under
that parent. The parent may be a multi-level colon path: {cmd:a:b:c} addresses
the flattened key {cmd:a_b_c}.

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt frame(name)}}list from frame yaml_{it:name} (Stata 16+){p_end}
{synopt:{opt keys}}return matching keys as delimited list in r(keys){p_end}
{synopt:{opt values}}return matching values as delimited list in r(values){p_end}
{synopt:{opt sep:arator(string)}}delimiter for lists; default is space{p_end}
{synopt:{opt child:ren}}return only immediate children of parent, as bare child names{p_end}
{synopt:{opt stata}}format output as Stata compound quotes: {cmd:`"item1"' `"item2"'}{p_end}
{synopt:{opt noh:eader}}suppress all printed output (results still stored in r()){p_end}
{synoptline}

{pstd}
With {opt children}, the returned and displayed keys are {bf:bare child names}:
the parent prefix is stripped, so {cmd:yaml list indicators, keys children}
returns {cmd:CME_MRY0T4 CME_MRY0}, not {cmd:indicators_CME_MRY0T4 ...}.
{cmd:yaml list} also stores the scalar {cmd:r(found)}, equal to 1 if any key
matched and 0 otherwise.


{marker get}{...}
{title:yaml get}

{p 8 17 2}
{cmd:yaml get}
{it:parent}{cmd::}{it:keyname} | {it:keyname}
[{cmd:,} {opt frame(name)} {opt attr:ibutes(namelist)} {opt q:uiet}]

{pstd}
Gets metadata attributes for a specific key (e.g., indicator code) and returns them
as separate r() macros. This is useful for querying indicator metadata by code.

{pstd}
{bf:Colon syntax:} Use {it:parent}{cmd::}{it:keyname} to specify the parent hierarchy.
For example, {cmd:indicators:CME_MRY0T4} searches for CME_MRY0T4 under indicators.
This is equivalent to searching for key {cmd:indicators_CME_MRY0T4_*}.
Colon paths may be multi-level: {cmd:a:b:c} addresses the flattened key
{cmd:a_b_c}, with the parent/key split made at the {it:last} colon
(parent {cmd:a_b}, key {cmd:c}).

{pstd}
{bf:Scalar leaves:} when the key holds a value directly and has no children
(e.g., {cmd:yaml get input_file} on a top-level scalar), the value is
returned in {cmd:r(value)}.

{pstd}
{bf:Block sequences of scalars:} when the key is a block sequence of scalar
items (stored as indexed children {it:key}_1, {it:key}_2, ...), a whole-node
{cmd:yaml get} returns the item values space-joined in {cmd:r(value)} and their
count in {cmd:r(n_attrs)}; individual items remain addressable by index
(e.g., {cmd:yaml get} {it:key}{cmd::1}).

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt frame(name)}}get from frame yaml_{it:name} (Stata 16+){p_end}
{synopt:{opt attr:ibutes(namelist)}}specific attributes to retrieve; default is all{p_end}
{synopt:{opt q:uiet}}suppress output display{p_end}
{synoptline}

{pstd}
{bf:Stored results:}
{p_end}
{phang2}{cmd:r(key)} - the key that was searched{p_end}
{phang2}{cmd:r(parent)} - the parent hierarchy (if colon syntax used){p_end}
{phang2}{cmd:r(found)} - 1 if attributes found, 0 otherwise{p_end}
{phang2}{cmd:r(n_attrs)} - number of attributes found{p_end}
{phang2}{cmd:r(value)} - the key's own value for a scalar leaf, or the space-joined item values for a block sequence of scalars{p_end}
{phang2}{cmd:r({it:attribute})} - value for each attribute found (e.g., r(label), r(unit)){p_end}


{marker validate}{...}
{title:yaml validate}

{p 8 17 2}
{cmd:yaml validate}
[{cmd:,} {opt required(keylist)} {opt types(string)} {opt frame(name)} {opt q:uiet}]

{pstd}
Checks that specified keys exist and that selected keys match required value
types in the current dataset (default) or a frame ({cmd:yaml check} is a
synonym). On success a one-line pass summary is printed.

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt required(keylist)}}verify that all listed keys exist{p_end}
{synopt:{opt types(string)}}verify types as {it:key:type} pairs ({cmd:numeric}, {cmd:string}, {cmd:boolean}){p_end}
{synopt:{opt frame(name)}}validate frame yaml_{it:name} (Stata 16+){p_end}
{synopt:{opt q:uiet}}suppress output; results returned silently in {cmd:r()}{p_end}
{synoptline}

{pstd}
{bf:Stored results:}
{p_end}
{phang2}{cmd:r(valid)} - 1 if all checks passed, 0 otherwise{p_end}
{phang2}{cmd:r(n_errors)} - number of failed checks{p_end}
{phang2}{cmd:r(n_warnings)} - number of warnings{p_end}
{phang2}{cmd:r(missing_keys)} - required keys that were not found{p_end}
{phang2}{cmd:r(type_errors)} - keys that failed a type check{p_end}


{marker dir}{...}
{title:yaml dir}

{p 8 17 2}
{cmd:yaml dir}
[{cmd:,} {opt det:ail}]

{pstd}
Lists all YAML data currently loaded in memory. This includes both the current 
dataset (if it contains YAML data) and any YAML frames (Stata 16+).

{pstd}
YAML data is identified by:
{p_end}
{phang2}1. Presence of standard YAML variables: {cmd:key}, {cmd:value}, {cmd:level}, {cmd:type}{p_end}
{phang2}2. The {cmd:_dta[yaml_source]} characteristic set by {cmd:yaml read}{p_end}
{phang2}3. Frame names with {cmd:yaml_} prefix (for frames){p_end}

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt det:ail}}show number of entries and source file for each{p_end}
{synoptline}

{pstd}
{bf:Stored results:}
{p_end}
{phang2}{cmd:r(n_total)} - total number of YAML sources in memory{p_end}
{phang2}{cmd:r(n_dataset)} - 1 if YAML data in current dataset, 0 otherwise{p_end}
{phang2}{cmd:r(n_frames)} - number of YAML frames loaded{p_end}


{marker frames}{...}
{title:yaml frames}

{p 8 17 2}
{cmd:yaml frames}
[{cmd:,} {opt det:ail}]

{pstd}
Lists only YAML frames currently loaded in memory. Requires Stata 16+.
Use {cmd:yaml dir} to see both the current dataset and frames.

{pstd}
YAML frames are identified by the {cmd:yaml_} prefix in their frame name.

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt det:ail}}show number of entries and source file for each frame{p_end}
{synoptline}

{pstd}
{bf:Stored results:}
{p_end}
{phang2}{cmd:r(n_frames)} - number of YAML frames loaded{p_end}


{marker clear}{...}
{title:yaml clear}

{p 8 17 2}
{cmd:yaml clear}
[{it:framename}]
[{cmd:,} {opt all}]

{pstd}
Clears YAML data from memory.

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:(no argument)}clear current dataset (default){p_end}
{synopt:{it:framename}}clear specific frame yaml_{it:framename} (Stata 16+){p_end}
{synopt:{opt all}}clear all yaml_* frames (Stata 16+){p_end}
{synoptline}


{marker examples}{...}
{title:Examples}

{pstd}
{bf:The command links below are clickable}: click one to run it in the current
session. The {bf:Quick start} needs nothing but Stata's own {cmd:auto} data.
The numbered examples read small demonstration files that ship with the
package; run the {bf:Setup} links once to locate them and store their paths in
the globals {cmd:$ycfg} and {cmd:$yset}. A Stata loop must be entered as
several lines, so it cannot be a single link; each loop block instead carries a
{bf:click to run} link that executes it through {cmd:yaml_examples}. Examples 2b, 10 and 13
additionally need an indicator catalog installed by {help wbopendata} or
{help unicefdata}
({stata ssc install unicefdata}, {stata ssc install wbopendata}).
{p_end}

{pstd}
{bf:Quick start} {hline 2} write, read back and query a YAML file using only
Stata's example data:{p_end}

{phang2}{cmd:.} {stata `"sysuse auto, clear"'}{p_end}
{phang2}{cmd:.} {stata `"quietly summarize price"'}{p_end}
{phang2}{cmd:.} {stata `"scalar n_cars = r(N)"'}{p_end}
{phang2}{cmd:.} {stata `"scalar mean_price = round(r(mean), .01)"'}{p_end}
{phang2}{cmd:.} {stata `"yaml write using "auto_summary.yaml", scalars(n_cars mean_price) replace"'}{p_end}
{phang2}{cmd:.} {stata `"type "auto_summary.yaml""'}{p_end}
{phang2}{res:# Generated by Stata yaml write}{p_end}
{phang2}{res:n_cars: 74}{p_end}
{phang2}{res:mean_price: 6165.26}{p_end}
{phang2}{cmd:.} {stata `"yaml read using "auto_summary.yaml", replace"'}{p_end}
{phang2}{cmd:.} {stata `"yaml get mean_price"'}{p_end}
{phang2}{space 2}{res:value: 6165.26}{p_end}

{pstd}
{bf:Setup} {hline 2} locate the demonstration files shipped with the package
(click each block once; the numbered examples reuse the globals, and
{cmd:type} shows the file exactly as shipped):{p_end}

{phang2}{cmd:.} {stata `"findfile yaml_demo_config.yaml"'}{p_end}
{phang2}{cmd:.} {stata `"global ycfg "`r(fn)'""'}{p_end}
{phang2}{cmd:.} {stata `"type "`r(fn)'""'}{p_end}
{phang2}{res:# Demonstration file shipped with the yaml package}{p_end}
{phang2}{res:name: My Project}{p_end}
{phang2}{res:version: 1.0}{p_end}
{phang2}{res:indicators:}{p_end}
{phang2}{space 2}{res:CME_MRY0T4:}{p_end}
{phang2}{space 4}{res:label: Under-five mortality rate}{p_end}
{phang2}{space 4}{res:unit: Deaths per 1000 live births}{p_end}
{phang2}{space 4}{res:dataflow: CME}{p_end}
{phang2}{space 2}{res:CME_MRY0:}{p_end}
{phang2}{space 4}{res:label: Infant mortality rate}{p_end}
{phang2}{space 4}{res:unit: Deaths per 1000 live births}{p_end}
{phang2}{space 4}{res:dataflow: CME}{p_end}

{phang2}{it:// yaml_demo_settings.yaml is used by Example 3}{p_end}
{phang2}{cmd:.} {stata `"findfile yaml_demo_settings.yaml"'}{p_end}
{phang2}{cmd:.} {stata `"global yset "`r(fn)'""'}{p_end}
{phang2}{cmd:.} {stata `"type "`r(fn)'""'}{p_end}
{phang2}{res:# Demonstration file shipped with the yaml package}{p_end}
{phang2}{res:environment: production}{p_end}
{phang2}{res:threads: 4}{p_end}
{phang2}{res:verbose: false}{p_end}

{pstd}
{bf:Example 1: Read YAML into current dataset (default)}{p_end}

{phang2}{cmd:.} {stata `"yaml read using "$ycfg", replace"'}{p_end}
{phang2}{cmd:.} {stata `"yaml describe"'}{p_end}
{phang2}{res:----------------------------------------------------------------------}{p_end}
{phang2}{res:YAML structure (showing up to level 3):}{p_end}
{phang2}{res:----------------------------------------------------------------------}{p_end}
{phang2}{res:name: My Project}{p_end}
{phang2}{res:version: 1.0}{p_end}
{phang2}{res:indicators:}{p_end}
{phang2}{space 2}{res:CME_MRY0T4:}{p_end}
{phang2}{space 4}{res:label: Under-five mortality rate}{p_end}
{phang2}{space 4}{res:unit: Deaths per 1000 live births}{p_end}
{phang2}{space 4}{res:dataflow: CME}{p_end}
{phang2}{space 2}{res:CME_MRY0:}{p_end}
{phang2}{space 4}{res:label: Infant mortality rate}{p_end}
{phang2}{space 4}{res:unit: Deaths per 1000 live births}{p_end}
{phang2}{space 4}{res:dataflow: CME}{p_end}
{phang2}{res:----------------------------------------------------------------------}{p_end}
{phang2}{res:Total keys: 11}{p_end}
{phang2}{res:----------------------------------------------------------------------}{p_end}
{phang2}{cmd:.} {stata `"list key value in 1/3, clean noobs"'}{p_end}
{phang2}{it:// the parsed file is an ordinary Stata dataset, so list/browse work}{p_end}

{pstd}
{bf:Example 2: Read YAML into a frame (Stata 16+)}{p_end}

{phang2}{cmd:.} {stata `"yaml read using "$ycfg", frame(config)"'}{p_end}
{phang2}{it:// Creates frame yaml_config, preserves current dataset}{p_end}
{phang2}{cmd:.} {stata `"yaml describe, frame(config)"'}{p_end}
{phang2}{it:// same structure listing as Example 1, read from the frame}{p_end}
{phang2}{cmd:.} {stata `"yaml dir"'}{p_end}
{phang2}{it:// confirms what is loaded in memory}{p_end}

{pstd}
{bf:Example 2b: Fast-scan for large metadata (opt-in)}{p_end}

{phang2}{cmd:.} {stata `"findfile _wbopendata_indicators.yaml"'}{p_end}
{phang2}{cmd:.} {stata `"yaml read using "`r(fn)'", replace fastread fields(name description source_id topic_ids) listkeys(topic_ids topic_names) cache(ind_cache)"'}{p_end}
{phang2}{cmd:.} {stata `"list in 1/5"'}{p_end}

{pstd}
{bf:Example 3: Work with multiple YAML files using frames (Stata 16+)}{p_end}

{phang2}{cmd:.} {stata `"yaml read using "$ycfg", frame(cfg)"'}{p_end}
{phang2}{cmd:.} {stata `"yaml read using "$yset", frame(settings)"'}{p_end}
{phang2}{cmd:.} {stata `"yaml frames, detail"'}{p_end}
{phang2}{res:------------------------------------------------------------}{p_end}
{phang2}{res:YAML frames in memory}{p_end}
{phang2}{res:------------------------------------------------------------}{p_end}
{phang2}{space 2}{res:1. yaml_cfg (11 entries)}{p_end}
{phang2}{space 5}{res:Source: ...\yaml_demo_config.yaml}{p_end}
{phang2}{space 2}{res:2. yaml_settings (3 entries)}{p_end}
{phang2}{space 5}{res:Source: ...\yaml_demo_settings.yaml}{p_end}
{phang2}{res:------------------------------------------------------------}{p_end}
{phang2}{res:Total: 2 YAML frame(s)}{p_end}
{phang2}{it:// Source shows the full path each file was read from; frames created}{p_end}
{phang2}{it:// by earlier examples are listed too}{p_end}

{pstd}
{bf:Example 4: Get indicator codes for looping}{p_end}

{phang2}{cmd:.} {stata `"yaml read using "$ycfg", replace"'}{p_end}
{phang2}{cmd:.} {stata `"yaml list indicators, keys children"'}{p_end}
{phang2}{res:Key}{p_end}
{phang2}{res:CME_MRY0T4}{p_end}
{phang2}{res:CME_MRY0}{p_end}
{phang2}{it:// the child names are also returned in r(keys)}{p_end}
{phang2}{cmd:. foreach ind in `r(keys)' {c -(}}{p_end}
{phang2}{space 6}{cmd:display "Processing: `ind'"}{p_end}
{phang2}{space 2}{cmd:{c )-}}{p_end}
{phang2}{res:Processing: CME_MRY0T4}{p_end}
{phang2}{res:Processing: CME_MRY0}{p_end}
{phang2}({stata "yaml_examples yaml_ex_loop":click to run the block above}){p_end}

{pstd}
{bf:Example 5: List keys with Stata compound quotes}{p_end}

{pstd}
The {opt stata} option does not change what is displayed; it wraps each name in
{cmd:r(keys)} in compound quotes, so the loop is safe when keys contain spaces
or other special characters.{p_end}

{phang2}{cmd:.} {stata `"yaml list indicators, keys children stata"'}{p_end}
{phang2}{res:Key}{p_end}
{phang2}{res:CME_MRY0T4}{p_end}
{phang2}{res:CME_MRY0}{p_end}
{phang2}{it:// r(keys) now holds: `"CME_MRY0T4"' `"CME_MRY0"'}{p_end}
{phang2}{cmd:. foreach ind in `r(keys)' {c -(}}{p_end}
{phang2}{space 6}{cmd:display "Processing: `ind'"}{p_end}
{phang2}{space 2}{cmd:{c )-}}{p_end}
{phang2}{res:Processing: CME_MRY0T4}{p_end}
{phang2}{res:Processing: CME_MRY0}{p_end}
{phang2}({stata "yaml_examples yaml_ex_loopstata":click to run the block above}){p_end}

{pstd}
{bf:Example 6: Get indicator metadata by code (colon syntax)}{p_end}

{phang2}{cmd:.} {stata `"yaml read using "$ycfg", replace"'}{p_end}
{phang2}{cmd:.} {stata `"yaml get indicators:CME_MRY0T4"'}{p_end}
{phang2}{space 2}{res:label: Under-five mortality rate}{p_end}
{phang2}{space 2}{res:unit: Deaths per 1000 live births}{p_end}
{phang2}{space 2}{res:dataflow: CME}{p_end}
{phang2}{cmd:.} {stata `"return list"'}{p_end}
{phang2}{res:scalars:}{p_end}
{phang2}{space 12}{res:r(n_attrs) =  3}{p_end}
{phang2}{space 14}{res:r(found) =  1}{p_end}
{phang2}{res:macros:}{p_end}
{phang2}{space 13}{res:r(parent) : "indicators"}{p_end}
{phang2}{space 16}{res:r(key) : "CME_MRY0T4"}{p_end}
{phang2}{space 11}{res:r(dataflow) : "CME"}{p_end}
{phang2}{space 15}{res:r(unit) : "Deaths per 1000 live births"}{p_end}
{phang2}{space 14}{res:r(label) : "Under-five mortality rate"}{p_end}

{pstd}
{bf:Example 7: Get specific attributes only}{p_end}

{phang2}{cmd:.} {stata `"yaml get indicators:CME_MRY0T4, attributes(label unit)"'}{p_end}
{phang2}{space 2}{res:label: Under-five mortality rate}{p_end}
{phang2}{space 2}{res:unit: Deaths per 1000 live births}{p_end}

{pstd}
{bf:Example 8: Loop over indicators and get metadata}{p_end}

{phang2}{cmd:.} {stata `"yaml list indicators, keys children"'}{p_end}
{phang2}{cmd:. foreach ind in `r(keys)' {c -(}}{p_end}
{phang2}{space 6}{cmd:yaml get indicators:`ind', quiet}{p_end}
{phang2}{space 6}{cmd:display "`ind': `r(label)' (`r(unit)')"}{p_end}
{phang2}{space 2}{cmd:{c )-}}{p_end}
{phang2}{res:CME_MRY0T4: Under-five mortality rate (Deaths per 1000 live births)}{p_end}
{phang2}{res:CME_MRY0: Infant mortality rate (Deaths per 1000 live births)}{p_end}
{phang2}({stata "yaml_examples yaml_ex_loopget":click to run the block above}){p_end}

{pstd}
{bf:Example 9: Query from frame}{p_end}

{phang2}{cmd:.} {stata `"yaml read using "$ycfg", frame(cfg)"'}{p_end}
{phang2}{cmd:.} {stata `"yaml get indicators:CME_MRY0, frame(cfg)"'}{p_end}
{phang2}{space 2}{res:label: Infant mortality rate}{p_end}
{phang2}{space 2}{res:unit: Deaths per 1000 live births}{p_end}
{phang2}{space 2}{res:dataflow: CME}{p_end}

{pstd}
{bf:Example 10: Parse wbopendata/unicefdata indicator metadata} {it:(requires an indicator catalog installed by one of those packages; see Example 13)}{p_end}

{phang2}{cmd:.} {stata `"findfile _wbopendata_indicators.yaml"'}{p_end}
{phang2}{cmd:.} {stata `"yaml read using "`r(fn)'", indicators replace"'}{p_end}
{phang2}{it:// Creates a wide-format dataset with one row per indicator and the}{p_end}
{phang2}{it:// variables ind_code, code, name, source_id, source_name, topic_ids,}{p_end}
{phang2}{it:// topic_names (list fields are joined with semicolons)}{p_end}
{phang2}{cmd:.} {stata `"list ind_code code name in 1/3"'}{p_end}

{pstd}
The {cmd:indicators} preset automatically enables {cmd:bulk} + {cmd:collapse} with
default {cmd:colfields()} for standard indicator metadata fields. This replaces
custom vectorized parsers and delivers ~60% faster performance.

{pstd}
{bf:Example 11: Write from dataset to YAML, and round-trip an edit}{p_end}

{phang2}{cmd:.} {stata `"yaml read using "$ycfg", replace"'}{p_end}
{phang2}{cmd:.} {stata `"yaml write using "output.yaml", replace"'}{p_end}
{phang2}{cmd:.} {stata `"type "output.yaml""'}{p_end}
{phang2}{res:# Generated by Stata yaml write}{p_end}
{phang2}{res:name: My Project}{p_end}
{phang2}{res:version: 1.0}{p_end}
{phang2}{res:indicators:}{p_end}
{phang2}{space 2}{res:CME_MRY0T4:}{p_end}
{phang2}{space 4}{res:label: Under-five mortality rate}{p_end}
{phang2}{space 4}{res:unit: Deaths per 1000 live births}{p_end}
{phang2}{space 4}{res:dataflow: CME}{p_end}
{phang2}{space 2}{res:CME_MRY0:}{p_end}
{phang2}{space 4}{res:label: Infant mortality rate}{p_end}
{phang2}{space 4}{res:unit: Deaths per 1000 live births}{p_end}
{phang2}{space 4}{res:dataflow: CME}{p_end}
{phang2}{it:// yaml write needs the canonical key/value/level/type layout, so read}{p_end}
{phang2}{it:// the file first if another command replaced the data in memory}{p_end}
{phang2}{cmd:.} {stata `"view file "output.yaml""'}{p_end}
{phang2}{it:// opens the file in the Stata Viewer (interactive Stata only)}{p_end}
{phang2}{it:// (to write named scalars instead, see the Quick start above)}{p_end}

{pstd}
Editing values between the read and the write round-trips a change back to
disk. Edit values freely, but keep the row order: {cmd:yaml write} emits rows in
observation order, so sorting or dropping rows can misplace children.{p_end}

{phang2}{cmd:.} {stata `"replace value = "2.0" if key == "version""'}{p_end}
{phang2}{cmd:.} {stata `"yaml write using "config_updated.yaml", replace"'}{p_end}
{phang2}{cmd:.} {stata `"type "config_updated.yaml""'}{p_end}
{phang2}{res:# Generated by Stata yaml write}{p_end}
{phang2}{res:name: My Project}{p_end}
{phang2}{res:version: 2.0}{p_end}
{phang2}{res:indicators:}{p_end}
{phang2}{space 2}{res:CME_MRY0T4:}{p_end}
{phang2}{space 4}{res:label: Under-five mortality rate}{p_end}
{phang2}{it:// ... remaining keys unchanged}{p_end}

{pstd}
{help checksum} confirms the edit reached the file. Here the two files are the
same length---{cmd:1.0} and {cmd:2.0} have equal width---so the size alone
proves nothing, while the checksum differs. Compare the two values rather than
reading them: {cmd:checksum} prints a number and a size that depend on the line
endings your Stata writes, so they are not the same on every machine.{p_end}

{phang2}{cmd:.} {stata `"checksum "output.yaml""'}{p_end}
{phang2}{cmd:.} {stata `"local before = r(checksum)"'}{p_end}
{phang2}{cmd:.} {stata `"checksum "config_updated.yaml""'}{p_end}
{phang2}{cmd:.} {stata `"display cond(r(checksum) == `before', "identical", "the file changed")"'}{p_end}
{phang2}{res:the file changed}{p_end}

{pstd}
{bf:Reproducible output.} Two writes of the same data, on the same machine,
produce files that are byte-identical {it:to each other}, because the default
header records no wall-clock time. That is what keeps a generated
configuration free of spurious version-control diffs. It is a claim about
repeated runs, not about different machines: the checksum {it:value} still
depends on the line endings a given Stata writes, so only the comparison
below reproduces everywhere.{p_end}

{phang2}{cmd:.} {stata `"yaml write using "run1.yaml", replace"'}{p_end}
{phang2}{cmd:.} {stata `"yaml write using "run2.yaml", replace"'}{p_end}
{phang2}{cmd:.} {stata `"checksum "run1.yaml""'}{p_end}
{phang2}{cmd:.} {stata `"local r1 = r(checksum)"'}{p_end}
{phang2}{cmd:.} {stata `"checksum "run2.yaml""'}{p_end}
{phang2}{cmd:.} {stata `"display cond(r(checksum) == `r1', "byte-identical", "the file changed")"'}{p_end}
{phang2}{res:byte-identical}{p_end}
{phang2}{it:// both also match config_updated.yaml above: the edited data is still}{p_end}
{phang2}{it:// in memory, so the same bytes are written}{p_end}

{pstd}
Add {opt timestamp} when the write time is wanted as provenance. The file then
carries a {cmd:# Date:} line, and successive writes are no longer
byte-identical:{p_end}

{phang2}{cmd:.} {stata `"yaml write using "stamped.yaml", replace timestamp"'}{p_end}
{phang2}{cmd:.} {stata `"type "stamped.yaml""'}{p_end}
{phang2}{res:# Generated by Stata yaml write}{p_end}
{phang2}{res:# Date: 27 Jul 2026 02:56:17}{p_end}
{phang2}{res:name: My Project}{p_end}
{phang2}{res:version: 2.0}{p_end}
{phang2}{it:// ... remaining keys unchanged}{p_end}
{phang2}{it:// use noheader to omit the comment header altogether}{p_end}

{pstd}
The same comparison now reports the opposite result: with the header recording
the moment of writing, two runs no longer agree. The pause matters---the stamp
has one-second resolution, so two writes inside the same second would still
match---and the files are again the same length, so only the {cmd:# Date:}
line accounts for the difference:{p_end}

{phang2}{cmd:.} {stata `"yaml write using "stamped1.yaml", replace timestamp"'}{p_end}
{phang2}{cmd:.} {stata `"sleep 1000"'}{p_end}
{phang2}{cmd:.} {stata `"yaml write using "stamped2.yaml", replace timestamp"'}{p_end}
{phang2}{cmd:.} {stata `"checksum "stamped1.yaml""'}{p_end}
{phang2}{cmd:.} {stata `"local s1 = r(checksum)"'}{p_end}
{phang2}{cmd:.} {stata `"checksum "stamped2.yaml""'}{p_end}
{phang2}{cmd:.} {stata `"display cond(r(checksum) == `s1', "identical", "the files differ")"'}{p_end}
{phang2}{res:the files differ}{p_end}
{phang2}{it:// contrast with the default above, where the same two writes agreed:}{p_end}
{phang2}{it:// this is the cost of recording provenance in the file itself}{p_end}

{pstd}
Sizes and checksums differ between Stata flavours---console Stata ends lines
with a line feed, the graphical Stata with a carriage return and line feed, so
the same content can be twelve bytes longer in one and not the other. That is
why the examples above compare the two values instead of quoting them.{p_end}

{pstd}
{bf:Example 12: Clear YAML data}{p_end}

{phang2}{cmd:.} {stata `"yaml clear"'}{p_end}
{phang2}{res:Cleared current dataset.}{p_end}
{phang2}{cmd:.} {stata `"yaml clear config"'}{p_end}
{phang2}{res:Cleared frame yaml_config.}{p_end}
{phang2}{cmd:.} {stata `"yaml clear, all"'}{p_end}
{phang2}{res:Cleared all yaml_* frames.}{p_end}
{phang2}{cmd:.} {stata `"yaml dir"'}{p_end}
{phang2}{it:// confirms nothing is left in memory}{p_end}

{pstd}
{bf:Example 13: Query catalogs installed by other packages} {it:(requires unicefdata/wbopendata)}{p_end}

{pstd}
The {help unicefdata} and {help wbopendata} packages install their metadata
catalogs as YAML files on the adopath; {help findfile} locates one and
{cmd:yaml} reads it with no download. Click the lines in order (each uses the
previous line's result):{p_end}

{phang2}{cmd:.} {stata `"findfile _unicefdata_regions.yaml"'}{p_end}
{phang2}{cmd:.} {stata `"yaml read using "`r(fn)'", frame(reg)"'}{p_end}
{phang2}{cmd:.} {stata `"yaml get regions:UNICEF_ESA, frame(reg)"'}{p_end}
{phang2}{space 2}{res:value: Eastern and Southern Africa}{p_end}

{phang2}{cmd:.} {stata `"findfile _wbopendata_topics.yaml"'}{p_end}
{phang2}{cmd:.} {stata `"yaml read using "`r(fn)'", frame(top)"'}{p_end}
{phang2}{cmd:.} {stata `"yaml get topics:'1':name, frame(top)"'}{p_end}
{phang2}{space 2}{res:value: Agriculture & Rural Development}{p_end}

{pstd}
{bf:Example 14: Retrieve several keys, or match a key pattern}{p_end}

{pstd}
{cmd:yaml get} returns one key per call. Retrieve several named keys by looping
over {cmd:yaml get}; select keys by pattern by loading the file into a frame
once and filtering its {cmd:key} column with {help regexm()}, which is faster
than repeated lookups (the large-catalog pattern of the article's applications).{p_end}

{phang2}{cmd:.} {stata `"yaml read using "$ycfg", frame(cfg)"'}{p_end}

{phang2}{it:// several named keys}{p_end}
{phang2}{cmd:. foreach i in CME_MRY0T4 CME_MRY0 {c -(}}{p_end}
{phang2}{space 6}{cmd:yaml get indicators:`i':label, frame(cfg) quiet}{p_end}
{phang2}{space 6}{cmd:display "`i': `r(value)'"}{p_end}
{phang2}{space 2}{cmd:{c )-}}{p_end}
{phang2}{res:CME_MRY0T4: Under-five mortality rate}{p_end}
{phang2}{res:CME_MRY0: Infant mortality rate}{p_end}

{phang2}{it:// all keys matching a pattern}{p_end}
{phang2}{cmd:. frame yaml_cfg {c -(}}{p_end}
{phang2}{space 6}{cmd:quietly levelsof value if regexm(key, "_label$"), local(labs) clean}{p_end}
{phang2}{space 2}{cmd:{c )-}}{p_end}
{phang2}{cmd:. display `"`labs'"'}{p_end}
{phang2}{res:Infant mortality rate Under-five mortality rate}{p_end}
{phang2}({stata "yaml_examples yaml_ex_multikey":click to run both blocks above}){p_end}

{pstd}
{bf:Example 15: Sequences of mappings (harmonization maps)}{p_end}

{pstd}
A block sequence whose items are themselves mappings---the shape used by
value-recoding maps and CI configurations---is stored with one structural row
per item, addressed by its index. A third demonstration file,
{cmd:yaml_demo_harmonize.yaml}, is installed with the package:{p_end}

{phang2}{cmd:survey: MICS6}{p_end}
{phang2}{cmd:variable: male}{p_end}
{phang2}{cmd:values:}{p_end}
{phang2}{space 2}{cmd:- from: 1}{p_end}
{phang2}{space 4}{cmd:to: 1}{p_end}
{phang2}{space 4}{cmd:label: Male}{p_end}
{phang2}{space 2}{cmd:- from: 2}{p_end}
{phang2}{space 4}{cmd:to: 0}{p_end}
{phang2}{space 4}{cmd:label: Female}{p_end}

{phang2}{cmd:.} {stata `"findfile yaml_demo_harmonize.yaml"'}{p_end}
{phang2}{cmd:.} {stata `"yaml read using "`r(fn)'", replace"'}{p_end}
{phang2}{cmd:.} {stata `"yaml describe"'}{p_end}
{phang2}{res:survey: MICS6}{p_end}
{phang2}{res:variable: male}{p_end}
{phang2}{res:values:}{p_end}
{phang2}{space 2}{res:1:}{p_end}
{phang2}{space 4}{res:from: 1}{p_end}
{phang2}{space 4}{res:to: 1}{p_end}
{phang2}{space 4}{res:label: Male}{p_end}
{phang2}{space 2}{res:2:}{p_end}
{phang2}{space 4}{res:from: 2}{p_end}
{phang2}{space 4}{res:to: 0}{p_end}
{phang2}{space 4}{res:label: Female}{p_end}
{phang2}{cmd:.} {stata `"yaml list values, keys children"'}{p_end}
{phang2}{res:Key}{p_end}
{phang2}{res:1}{p_end}
{phang2}{res:2}{p_end}
{phang2}{cmd:.} {stata `"yaml get values:1"'}{p_end}
{phang2}{space 2}{res:value: }{p_end}
{phang2}{space 2}{res:from: 1}{p_end}
{phang2}{space 2}{res:to: 1}{p_end}
{phang2}{space 2}{res:label: Male}{p_end}
{phang2}{it:// the item row itself carries no value; its children follow}{p_end}
{phang2}{cmd:.} {stata `"yaml get values:2:label"'}{p_end}
{phang2}{space 2}{res:value: Female}{p_end}
{phang2}{it:// each item is addressed like a named nested mapping, so a recode loop}{p_end}
{phang2}{it:// can read from:/to: pairs straight out of the file}{p_end}

{pstd}
{bf:Example 16: A harmonization crosswalk across two MICS rounds}{p_end}

{pstd}
Survey rounds rename things. Of the six household-listing variables below,
three keep their names between MICS5 and MICS6 and three move. A program that
hard-codes either round has to be rewritten for the other; a crosswalk does
not. Three demonstration files ship with the package: one source file per
round, and one target file both rounds are harmonized to.{p_end}

{synoptset 26 tabbed}{...}
{synoptline}
{synopt:{bf:concept}}{space 3}MICS5{space 8}MICS6{space 8}IPUMS MICS{p_end}
{synopt:relationship_to_head}{space 3}HL3{space 10}HL3{space 10}RELATE{p_end}
{synopt:sex}{space 3}hl4{space 10}hl4{space 10}SEX{p_end}
{synopt:age}{space 3}hl6{space 10}hl6{space 10}AGE{p_end}
{synopt:mother_alive}{space 3}hl11{space 9}hl12{space 9}MOTHERALIVE{p_end}
{synopt:ever_attended_school}{space 3}ed3{space 10}ed4{space 10}SCHOOLEVER{p_end}
{synopt:highest_level_attended}{space 3}ed4a{space 9}ed5a{space 9}EDLEVEL{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The names above are those of the published IPUMS MICS / UNICEF MICS variable
crosswalk (IPUMS MICS, {it:Comparison of UNICEF Variable Names and IPUMS Variable
Names}, list as of December 2024). Each source file carries the whole crosswalk
row---what its round calls the variable, the canonical IPUMS name, its label and
the unit of analysis---tagged with a {cmd:concept}; the target file adds only what
a source row cannot know, the canonical value labels and documentation
identifiers, keyed by the same concept:{p_end}

{phang2}{it:// yaml_demo_mics5.yaml -- one entry per crosswalk row}{p_end}
{phang2}{cmd:source: MICS5}{p_end}
{phang2}{cmd:variables:}{p_end}
{phang2}{space 2}{cmd:- name: hl11}{p_end}
{phang2}{space 4}{cmd:ipums_name: MOTHERALIVE}{p_end}
{phang2}{space 4}{cmd:ipums_label: Natural mother alive}{p_end}
{phang2}{space 4}{cmd:unit: hl}{p_end}
{phang2}{space 4}{cmd:concept: mother_alive}{p_end}
{phang2}{space 2}{cmd:- name: ed3}{p_end}
{phang2}{space 4}{cmd:ipums_name: SCHOOLEVER}{p_end}
{phang2}{space 4}{cmd:ipums_label: Household member has ever attended school}{p_end}
{phang2}{space 4}{cmd:unit: hl}{p_end}
{phang2}{space 4}{cmd:concept: ever_attended_school}{p_end}

{phang2}{it:// yaml_demo_mics6.yaml -- the same rows, round 6 names}{p_end}
{phang2}{cmd:source: MICS6}{p_end}
{phang2}{cmd:variables:}{p_end}
{phang2}{space 2}{cmd:- name: hl12}{p_end}
{phang2}{space 4}{cmd:ipums_name: MOTHERALIVE}{p_end}
{phang2}{space 4}{cmd:ipums_label: Natural mother alive}{p_end}
{phang2}{space 4}{cmd:unit: hl}{p_end}
{phang2}{space 4}{cmd:concept: mother_alive}{p_end}
{phang2}{space 2}{cmd:- name: ed4}{p_end}
{phang2}{space 4}{cmd:ipums_name: SCHOOLEVER}{p_end}
{phang2}{space 4}{cmd:ipums_label: Household member has ever attended school}{p_end}
{phang2}{space 4}{cmd:unit: hl}{p_end}
{phang2}{space 4}{cmd:concept: ever_attended_school}{p_end}

{pstd}
Each entry carries the whole crosswalk row---the IPUMS harmonized name, its
label, the unit of analysis (the data file the variable lives on) and the
concept---so a round file can be checked line by line against the published
table, and the generator needs nothing else to rename and label. The target
file is left with only what a source row cannot know, the canonical value
labels, keyed by the same concept:{p_end}

{phang2}{it:// yaml_demo_target.yaml}{p_end}
{phang2}{cmd:standard: IPUMS MICS}{p_end}
{phang2}{cmd:concepts:}{p_end}
{phang2}{space 2}{cmd:- concept: sex}{p_end}
{phang2}{space 4}{cmd:ddi: individual.sex}{p_end}
{phang2}{space 4}{cmd:codes:}{p_end}
{phang2}{space 6}{cmd:- code: 1}{p_end}
{phang2}{space 8}{cmd:label: Male}{p_end}
{phang2}{space 6}{cmd:- code: 2}{p_end}
{phang2}{space 8}{cmd:label: Female}{p_end}

{pstd}
{cmd:yaml_harmonize}, installed with the package, turns a pair of crosswalk
files into a documented do-file:{p_end}

{phang2}{cmd:yaml_harmonize using} {it:source.yaml}{cmd:, target(}{it:target.yaml}{cmd:)}{p_end}
{phang2}{space 4}{cmd:[saving(}{it:filename}{cmd:) replace project(}{it:string}{cmd:) author(}{it:string}{cmd:) timestamp ddiexport]}{p_end}

{pstd}
It reports coverage and returns {cmd:r(n_mapped)} and {cmd:r(n_skipped)}, so a
pipeline can stop when a round stops mapping cleanly. Like {cmd:yaml write}, it
records no wall-clock time unless {opt timestamp} is given, so a regenerated
do-file is byte-identical when the crosswalk has not changed:{p_end}

{phang2}{cmd:.} {stata "yaml_examples yaml_ex_harmonize 5":yaml_examples yaml_ex_harmonize 5}{p_end}
{phang2}{res:yaml_harmonize: wrote harmonize_mics5.do (6 mapped, 0 skipped)}{p_end}

{pstd}
The emitted file documents itself. Each block names the concept, the round's
variable and the canonical one, and the unit of analysis. Everything that touches
the variable sits inside one guard, so a round that does not carry it says so and
moves on rather than halting the run. Abridged here to the Viewer's width; the
generated file also carries a {cmd:Project:} line, the {cmd:Inputs} descriptions,
a {cmd:Generator:} line, and the other five concept blocks:{p_end}

{phang2}{res:*===============================================================}{p_end}
{phang2}{res:* harmonize_mics5.do}{p_end}
{phang2}{res:*}{p_end}
{phang2}{res:* Purpose:   Rename and label a MICS5 extract to the IPUMS MICS}{p_end}
{phang2}{res:*            canonical variables.}{p_end}
{phang2}{res:*}{p_end}
{phang2}{res:* GENERATED FILE - DO NOT EDIT.}{p_end}
{phang2}{res:* Edit the crosswalk files below and regenerate with yaml_harmonize.}{p_end}
{phang2}{res:*}{p_end}
{phang2}{res:* Inputs}{p_end}
{phang2}{res:*   Source:  yaml_demo_mics5.yaml}{p_end}
{phang2}{res:*   Target:  yaml_demo_target.yaml}{p_end}
{phang2}{res:*}{p_end}
{phang2}{res:* Coverage:  6 variable(s) mapped, 0 skipped}{p_end}
{phang2}{res:*===============================================================}{p_end}
{phang2}{res:}{p_end}
{phang2}{res:*---------------------------------------------------------------}{p_end}
{phang2}{res:* mother_alive}{p_end}
{phang2}{res:*   MICS5: hl11   ->   IPUMS MICS: MOTHERALIVE}{p_end}
{phang2}{res:*   unit of analysis: hl}{p_end}
{phang2}{res:*---------------------------------------------------------------}{p_end}
{phang2}{res:capture confirm variable hl11}{p_end}
{phang2}{res:if (_rc) {c -(}}{p_end}
{phang2}{space 4}{res:display as text "  hl11 not in data; MOTHERALIVE skipped"}{p_end}
{phang2}{res:{c )-}}{p_end}
{phang2}{res:else {c -(}}{p_end}
{phang2}{space 4}{res:rename hl11 MOTHERALIVE}{p_end}
{phang2}{space 4}{res:label variable MOTHERALIVE "Natural mother alive"}{p_end}
{phang2}{space 4}{res:char MOTHERALIVE[ddi] "individual.motherAlive"}{p_end}
{phang2}{res:{c )-}}{p_end}

{pstd}
Running the same command against {cmd:yaml_demo_mics6.yaml} produces the round-6
file, in which that block reads {cmd:rename hl12 MOTHERALIVE}. The two apply the
same six labels and the same six DDI characteristics; they differ in the three
variable names that had to differ, in the round label carried in the header and in
each block comment, and in the study values driving the DDI export. Both leave
datasets that can be appended.{p_end}

{pstd}
A concept whose target entry defines {cmd:codes:} also gets a {cmd:label define},
written outside the guard because a value label does not need the variable to
exist, and a {cmd:label values} inside it:{p_end}

{phang2}{res:label define SEX_lbl 1 "Male" 2 "Female", replace}{p_end}
{phang2}{res:capture confirm variable hl4}{p_end}
{phang2}{res:if (_rc) {c -(}}{p_end}
{phang2}{space 4}{res:display as text "  hl4 not in data; SEX skipped"}{p_end}
{phang2}{res:{c )-}}{p_end}
{phang2}{res:else {c -(}}{p_end}
{phang2}{space 4}{res:rename hl4 SEX}{p_end}
{phang2}{space 4}{res:label variable SEX "Sex of household member"}{p_end}
{phang2}{space 4}{res:char SEX[ddi] "individual.sex"}{p_end}
{phang2}{space 4}{res:label values SEX SEX_lbl}{p_end}
{phang2}{res:{c )-}}{p_end}

{pstd}
{bf:Why keep the crosswalk in files like these?}{p_end}

{phang2}{bf:Plain text, so version control can see it.} A crosswalk is a
research decision, not a byproduct: it records that {cmd:ed3} and {cmd:ed4} are
the same question. Held as ASCII it diffs line by line, so a reviewer sees
exactly which mapping changed, {cmd:git blame} says who changed it and when,
and a correction arrives as a reviewable pull request. The same table in a
spreadsheet is opaque to all of this.{p_end}

{phang2}{bf:Separate files, so each side can move on its own.} A new round is a
new source file; the target file is untouched. Rounds genuinely gain and lose
variables---MICS6 adds concepts the earlier rounds have no question for, and
some MICS5 variables have no MICS6 counterpart---so a concept present on one
side only is normal, and the generator reports it rather than skipping it
quietly. Adding a category or a survey does not mean editing the recoding
program, because there is no recoding program to edit: it is generated.{p_end}

{phang2}{bf:YAML, so a person can check it.} The mapping is read and approved
by whoever knows the questionnaire, who is not necessarily the person who
writes Stata. YAML is legible without any tooling, nests naturally for value
labels, and is already the format the surrounding pipeline reads (see
section~2 of the accompanying article), so the same file can be consumed by R
or Python steps without a second copy in another format.{p_end}

{phang2}{bf:And it scales to documentation standards.} A generated do-file
gives every harmonized variable a label, and its value labels, from one place.
That is precisely what a DDI exporter works from: {cmd:dta2ddi} builds DDI XML
for software such as Nesstar Publisher out of a dataset's file and variable
descriptions (Nguyen 2014). Harmonizing through a crosswalk means those
descriptions are complete and identical across rounds before the exporter ever
runs, instead of depending on whatever each round's do-file happened to
label.{p_end}

{phang2}The {cmd:ddi:} entry in the target file goes further: it is emitted as
a {help char:characteristic} on the variable, so a concept identifier attached
once travels into every dataset the crosswalk produces and is available to any
step that looks for it.{p_end}

{phang2}With {opt ddiexport}, the crosswalk also writes the export call itself.
{cmd:dta2ddi} substitutes {cmd:;XXX;}-style markers in an appended template from
twenty-five opaque option slots, {cmd:xxx()} through {cmd:vvv()}. Naming those
slots once in the target file ({cmd:xxx} means country, {cmd:yyy} means
year) is what makes the generated call readable, and each survey supplies its
own values from its {cmd:study:} block (this extract is abridged too):{p_end}

{phang2}{res:* DDI export}{p_end}
{phang2}{res:*}{space 3}{res:dta2ddi replaces ;XXX;-style markers in the appended}{p_end}
{phang2}{res:*}{space 3}{res:template with the values of its xxx()...vvv() options.}{p_end}
{phang2}{res:*}{space 3}{res:Each slot below is named in the target crosswalk:}{p_end}
{phang2}{res:*}{space 5}{res:xxx = country -> ETH}{p_end}
{phang2}{res:*}{space 5}{res:yyy = year -> 2014}{p_end}
{phang2}{res:*}{space 5}{res:zzz = survey -> MICS5}{p_end}
{phang2}{res:capture which dta2ddi}{p_end}
{phang2}{res:if (_rc) {c -(}}{p_end}
{phang2}{space 4}{res:display as text "dta2ddi not installed; skipping DDI export (ssc install dta2ddi)"}{p_end}
{phang2}{res:{c )-}}{p_end}
{phang2}{res:else {c -(}}{p_end}
{phang2}{space 4}{res:tempfile _harmonized}{p_end}
{phang2}{space 4}{res:quietly save "`_harmonized'", replace}{p_end}
{phang2}{space 4}{res:capture confirm file "ddi_template.xml"}{p_end}
{phang2}{space 4}{res:if (_rc) {c -(}}{p_end}
{phang2}{space 8}{res:display as text "ddi_template.xml not found; skipping DDI export"}{p_end}
{phang2}{space 4}{res:{c )-}}{p_end}
{phang2}{space 4}{res:else {c -(}}{p_end}
{phang2}{space 8}{res:dta2ddi, using("`_harmonized'") save("ETH_2014_MICS5.xml") ///}{p_end}
{phang2}{space 12}{res:append("ddi_template.xml") ///}{p_end}
{phang2}{space 12}{res:id(ETH_2014_MICS5) stats(min max mean stdev) ///}{p_end}
{phang2}{space 12}{res:xxx(ETH) yyy(2014) zzz(MICS5)}{p_end}
{phang2}{space 4}{res:{c )-}}{p_end}
{phang2}{res:{c )-}}{p_end}

{phang2}{cmd:dta2ddi} documents a dataset on disk, so the generated call saves the
harmonized data first and exports that, not the raw extract the renames were
applied to. The call is guarded twice over, on {cmd:dta2ddi} being installed and on
the template being present, so a do-file generated on one machine still runs on
another. Driving those slots from a spreadsheet, as such loops
usually are, leaves {cmd:xxx(ETH)} with nothing to say what {cmd:xxx} is; here
the meaning is in the file and travels with the mapping.{p_end}

{phang2}The general point is the leverage, not the particular field.
Retro-fitting an identifier to a few hundred hand-written harmonization
do-files is the kind of task that does not get done; adding one line per
concept to a single target file is. The same holds for whatever else a standard
grows, be it a controlled vocabulary, a provenance URI or a units field, because the
do-files are output, not source.{p_end}

{pstd}
{bf:Example 17: Validate a configuration file}{p_end}

{phang2}{cmd:.} {stata `"yaml read using "$ycfg", replace"'}{p_end}
{phang2}{cmd:.} {stata `"yaml validate, required(name version indicators) types(version:numeric)"'}{p_end}
{phang2}{res:Validation passed (3 required keys, 1 type checks)}{p_end}
{phang2}{it:// r(valid), r(n_errors), r(missing_keys) and r(type_errors) are returned}{p_end}
{phang2}{it:// so a pipeline can stop before running on a malformed configuration}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:yaml read} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(n_keys)}}number of keys parsed (canonical and fast-read modes){p_end}
{synopt:{cmd:r(max_level)}}maximum nesting depth (canonical mode){p_end}
{synopt:{cmd:r(cache_hit)}}1 if cache was used, 0 otherwise{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(filename)}}name of file read{p_end}
{synopt:{cmd:r(frame)}}full name of frame created, including the {cmd:yaml_} prefix (if frame option used; canonical and cached reads){p_end}
{synopt:{cmd:r(yaml_mode)}}parsing mode: {cmd:canonical}, {cmd:fastread}, or {cmd:bulk}{p_end}
{synopt:{cmd:r(yaml_*)}}values from YAML file (when {opt locals} specified){p_end}

{pstd}
{cmd:yaml list} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(found)}}1 if any key matched, 0 otherwise{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(keys)}}delimited list of matching keys (with {opt keys}; bare child names with {opt children}){p_end}
{synopt:{cmd:r(values)}}delimited list of matching values (with {opt values}){p_end}
{synopt:{cmd:r(parent)}}parent key used for filtering{p_end}
{p2colreset}{...}


{marker limitations}{...}
{title:Limitations}

{pstd}
{cmd:yaml} requires Stata 14.0 for basic functionality.
The {opt frame()} option requires Stata 16.0 or later.

{pstd}
{cmd:yaml} handles common YAML structures but does not support:

{phang2}- Anchors and aliases (&anchor, *alias){p_end}
{phang2}- Complex keys{p_end}
{phang2}- Flow style ({c -(}key: value{c )-}){p_end}
{phang2}- Document markers (---){p_end}

{pstd}
{bf:Block scalars} (multi-line strings with {cmd:|} or {cmd:>}) are supported via
{opt blockscalars} in all parse modes (canonical, fast-read, and bulk).

{pstd}
{cmd:fastread} mode is optimized for shallow mappings and list blocks, and does not
support anchors, aliases, or complex nested structures; like {opt bulk}, it
rejects sequence-of-mappings items ({cmd:- key: value}) with an error. Use the
canonical parser for the widest coverage of the supported subset.

{pstd}
{bf:Performance options} ({opt bulk}, {opt collapse}, {opt strl}) enable high-performance
parsing via Mata. The {opt bulk} option uses a Mata-based parser that loads the
entire file into memory for vectorized processing. Combine with {opt collapse}
to produce wide-format output with one row per top-level key.
The {opt strl} option stores values as strL to allow values exceeding 2045 characters.

{pstd}
{bf:Collapse filter options (v1.8.0):} When using {opt collapse}, the default behavior
creates columns for every field path in the YAML structure. For deeply nested YAML files
(like indicator metadata), this can produce hundreds of columns. Use these options to
filter the collapsed output:

{p 8 12 2}
{opt colfields(string)} filters columns to include only specified field names. 
Provide fields as a semicolon-separated list (e.g., {cmd:colfields(code;name;source_id)}).
Uses exact case-sensitive matching against the final field name (the part after the last underscore).

{p 8 12 2}
{opt maxlevel(#)} limits columns by nesting depth, measured as the number of underscores
in the field name plus one. Level 1 includes fields with no underscores (e.g., {it:code}, {it:name}).
Level 2 adds fields with one underscore (e.g., {it:source_id}, {it:topic_names}).
Level 3 adds fields with two underscores (e.g., array elements like {it:topic_ids_1}).

{pstd}
{bf:Example:} For wbopendata/unicefdata indicator metadata with fields like {it:code}, {it:name},
{it:source_id}, {it:description}, use:

{p 8 15 2}
{cmd:yaml read using "indicators.yaml", bulk collapse colfields(code;name;source_id;description)}

{pstd}
This produces a dataset with one row per indicator and only the four specified columns,
instead of the hundreds that would be created with full collapse.


{marker references}{...}
{title:References}

{pstd}
IPUMS MICS. 2024. {it:Comparison of UNICEF Variable Names and IPUMS Variable
Names}. List as of December 2024. Minneapolis, MN: IPUMS.
{browse "https://mics.ipums.org/mics/resources/training_exercises/2024_12_var_names_ipums_unicef.pdf"}
{p_end}

{pstd}
Nguyen, M. C. 2014. {it:DDI maker from Stata}. World Bank (mimeo).
Available as {cmd:dta2ddi}, Statistical Software Components S457930, Boston
College Department of Economics ({stata "ssc describe dta2ddi":ssc describe dta2ddi}).
{p_end}


{marker author}{...}
{title:Author}

{pstd}
João Pedro Azevedo{break}
UNICEF{break}
jpazevedo@unicef.org


{marker seealso}{...}
{title:Also see}

{psee}
{space 2}Help: {help yaml_examples:yaml examples}, {help yaml_whatsnew:what's new}, {help frames}, {help infile}, {help import delimited}, {help file}
{p_end}
