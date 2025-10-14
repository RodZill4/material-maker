# ------------------------------------------------------------------------------
# Creates a structure that contains all the data about the results of running
# tests.  This was created to make an intermediate step organizing the result
# of a run and exporting it in a specific format.  This can also serve as a
# unofficial GUT export format.
# ------------------------------------------------------------------------------
var json = JSON.new()
var strutils = GutStringUtils.new()

func _export_tests(gut, collected_script):
	var to_return = {}
	var tests = collected_script.tests
	for test in tests:
		if(test.get_status_text() != GutUtils.TEST_STATUSES.NOT_RUN):
			var orphans = gut.get_orphan_counter().get_orphan_ids(
				collected_script.get_filename_and_inner(),
				test.name)
			var orphan_node_strings = []
			for o in orphans:
				if(is_instance_id_valid(o)):
					orphan_node_strings.append(strutils.type2str(instance_from_id(o)))

			to_return[test.name] = {
				"status":test.get_status_text(),
				"passing":test.pass_texts,
				"failing":test.fail_texts,
				"pending":test.pending_texts,
				"orphan_count":orphan_node_strings.size(),
				"orphans":orphan_node_strings,
				"time_taken": test.time_taken
			}

	return to_return

# TODO
#	errors
func _export_scripts(gut):
	var collector = gut.get_test_collector()
	if(collector == null):
		return {}

	var scripts = {}

	for s in collector.scripts:
		var test_data = _export_tests(gut, s)
		scripts[s.get_full_name()] = {
			'props':{
				"tests":test_data.keys().size(),
				"pending":s.get_pending_count(),
				"failures":s.get_fail_count(),
				"skipped":s.was_skipped,
			},
			"tests":test_data
		}
	return scripts

func _make_results_dict():
	var result =  {
		'test_scripts':{
			"props":{
				"pending":0,
				"failures":0,
				"passing":0,
				"tests":0,
				"time":0,
				"orphans":0,
				"errors":0,
				"warnings":0,
				"risky":0
			},
			"scripts":[]
		}
	}
	return result


func get_results_dictionary(gut, include_scripts=true):
	var scripts = []

	if(include_scripts):
		scripts = _export_scripts(gut)

	var result =  _make_results_dict()

	var totals = gut.get_summary().get_totals()

	var props = result.test_scripts.props
	props.pending = totals.pending
	props.failures = totals.failing_tests
	props.passing = totals.passing_tests
	props.tests = totals.tests
	props.errors = gut.logger.get_errors().size()
	props.warnings = gut.logger.get_warnings().size()
	props.time =  gut.get_elapsed_time()
	props.orphans = gut.get_orphan_counter().get_count()
	props.risky = totals.risky

	result.test_scripts.scripts = scripts

	return result


func write_json_file(gut, path):
	var dict = get_results_dictionary(gut)
	var json_text = JSON.stringify(dict, ' ')

	var f_result = GutUtils.write_file(path, json_text)
	if(f_result != OK):
		var msg = str("Error:  ", f_result, ".  Could not create export file ", path)
		GutUtils.get_logger().error(msg)

	return f_result



func write_summary_file(gut, path):
	var dict = get_results_dictionary(gut, false)
	var json_text = JSON.stringify(dict, ' ')

	var f_result = GutUtils.write_file(path, json_text)
	if(f_result != OK):
		var msg = str("Error:  ", f_result, ".  Could not create export file ", path)
		GutUtils.get_logger().error(msg)

	return f_result
