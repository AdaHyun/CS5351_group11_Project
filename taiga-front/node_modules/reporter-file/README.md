reporter-file
==========

Similar to the xunit-file reporter. Allows you to specify any report style to
run, but will also write to the specified file

## How to use

1. Add "reporter-file" to your package.json devDependencies
2. Run mocha with either `-R reporter-file` or `--reporter reporter-file`

## Specifying the Reporter
The reporter can be specified in the MOCHA_REPORTER environment variable or
the config.json file. If neither of these are provided, it will defaul to XUnit

> MOCHA_REPORTER=Spec

### Default Mocha Reporter Options
Mocha comes with several reporters that can be used:
 - Dot
 - Doc
 - TAP
 - JSON
 - HTML
 - List
 - Min
 - Spec
 - Nyan
 - XUnit
 - Markdown
 - Progress
 - Landing
 - JSONCov
 - HTMLCov
 - JSONStream


## Specifying the Output
The output file is saved to the file given in the MOCHA_REPORTER_FILE environment variable, the file named in config.json, or process.cwd()/xunit.xml

> MOCHA_REPORTER_FILE=output/xunit.xml mocha -R xunit-file

## Credits
The original idea and basis for the output file structure came from
[xunit-file](https://npmjs.org/package/xunit-file)
