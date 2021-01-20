#!/usr/bin/env nextflow 

// testing if user can select a handful of tools, or if it must be 'all or one'
// inspiration from SAREK pipeline

// nextflow run tool_choice.nf --tool "ciriquant, dcc"
// activates process A + C
// works as expected

params.tool = null

// Check parameter existence
def checkParameterExistence(it, list) {
    if (!list.contains(it)) {
        log.warn "Unknown parameter: ${it}"
        return false
    }
    return true
}

// Compare each parameter with a list of parameters
def checkParameterList(list, realList) {
    return list.every{ checkParameterExistence(it, realList) }
}

toolList = defineToolList()
tool = params.tool ? params.tool.split(',').collect{it.trim().toLowerCase()} : []
if (!checkParameterList(tool, toolList)) exit 1, 'Unknown tool, see --help for more information'


// Define list of available tools
def defineToolList() {
    return [
        'ciriquant',
        'circexplorer2',
        'find_circ',
        'circrna_finder',
        'dcc',
        'mapsplice',
        'uroborus',
	'combine'
        ]
}

// set up some test processes

process a {

	echo true


	output:
	stdout to outa

	when: ('ciriquant' in tool || 'combine' in tool)
	
	script:
	"""
	echo "process A"
	"""
}

process b {
		
	echo true

	output:
	stdout to outb

	when: ('circexplorer2' in tool || 'combine' in tool)

	script:
	"""
	echo "process B"
	"""
}

process c {
	
	echo true

	output:
	stdout to outc

	when: ('dcc' in tool || 'combine' in tool)

	script:
	"""
	echo "process C"
	"""
}
