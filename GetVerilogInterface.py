def readClip():
	import win32clipboard
	import win32con
	win32clipboard.OpenClipboard()
	data = None
	if (win32clipboard.IsClipboardFormatAvailable(win32con.CF_UNICODETEXT)):
		data = win32clipboard.GetClipboardData(win32con.CF_UNICODETEXT)
	win32clipboard.CloseClipboard()
	return data

def writeClip(data):
	import win32clipboard
	import win32con
	win32clipboard.OpenClipboard()
	win32clipboard.EmptyClipboard()
	win32clipboard.SetClipboardData(win32con.CF_UNICODETEXT, data)
	win32clipboard.CloseClipboard()
	return

def readFile(path):
	import os
	if (not os.path.isfile(path)):
		return None
	data = None
	with open(path) as file:
		data = file.read()
	return data

def getInterface(data):
	indent = "\t"
	if (not data):
		return None
	import re
	# try to remove comments, but no escape character or quotation marks are considered.
	data = re.sub(r"(\/\*(\s|.)*?\*\/)|(\/\/.*)", "", data)
	results = []
	# support multiple modules
	for module_match in re.finditer(r"\bmodule\s+.*?\s+endmodule\b", data, re.S):
		text = re.match(r"module\s+(\w+)\s*\(([^\(\)]*\))\s*;(.*)", module_match.group(), re.S)
		if (not text):
			continue
		result = [None, [], []]  # name, parameters, signals
		result[0] = text.group(1)
		print("module", result[0])
		# support macro nesting, but do not check the correctness
		macro_pattern = re.compile(r"(`ifn?def\s*\w+|`endif)\s*")
		signal_pattern = re.compile(r"((input|output|inout)\s+(reg|wire)?\s*(\[[^:]+:[^:]+\])?)?\s*(?P<name>\w+)\s*(\=[^,\)]*)?[,\)]\s*")
		param_group_pattern = re.compile(r"parameter\s+([^;]*;)")
		param_pattern = re.compile(r"(\w+)\s*=\s*(.*)\s*[,;]\s*")
		# process signals
		signals_define = text.group(2).strip()
		signal_index = 0;
		last_signal = None
		while (signal_index != len(signals_define)):
			signal_match = signal_pattern.match(signals_define, signal_index)
			if (signal_match):
				result[2].append(".{0}(),".format(signal_match.group("name")))
				print("signal", result[2][-1])
				signal_index = signal_match.end()
				last_signal = len(result[2])
			else:
				macro_match = macro_pattern.match(signals_define, signal_index)
				if (macro_match):
					result[2].append(macro_match.group().strip())
					print("signal", result[2][-1])
					signal_index = macro_match.end()
				else:
					result[2].append("!ERROR!")
					print("signal", result[2][-1])
					last_signal = len(result[2])
					break
		if (last_signal):
			result[2][last_signal-1] = result[2][last_signal-1].rstrip(",")
		# process parameters
		param_groups_define = text.group(3).strip()
		param_group_index = 0;
		macro_pending = []
		last_param = None
		while (True):
			macro_index = param_group_index
			param_group_match = param_group_pattern.search(param_groups_define, param_group_index)
			pos = len(param_groups_define)
			if (param_group_match):
				pos = param_group_match.start()
			while (True):
				macro_match = macro_pattern.search(param_groups_define, macro_index)
				if (not macro_match or macro_match.start() > pos):
					break
				macro_index = macro_match.end()
				data = macro_match.group().strip()
				if (data.startswith("`if")):
					macro_pending.append(data)
				elif (macro_pending):
					macro_pending.pop()
				else:
					result[1].append(data)
					print("parameter", result[1][-1])
			if (not param_group_match):
				break
			for macro in macro_pending:
				result[1].append(macro)
				print("parameter", result[1][-1])
			macro_pending = []
			params_define = param_group_match.group(1).strip()
			param_index = 0;
			while (param_index != len(params_define)):
				param_match = param_pattern.match(params_define, param_index)
				if (param_match):
					result[1].append(".{}({}),".format(param_match.group(1), param_match.group(2)))
					print("parameter", result[1][-1])
					param_index = param_match.end()
					last_param = len(result[1])
				else:
					macro_match = macro_pattern.match(params_define, param_index)
					if (macro_match):
						result[1].append(macro_match.group().strip())
						print("parameter", result[1][-1])
						param_index = macro_match.end()
					else:
						result[1].append("!ERROR!")
						print("parameter", result[1][-1])
						last_param = len(result[1])
						break
			param_group_index = param_group_match.end()
		if (last_param):
			result[1][last_param-1] = result[1][last_param-1].rstrip(",")
		results.append(result)
	# reconstruct strings
	strings = []
	for result in results:
		if (result[1]):
			strings.append("{} #(".format(result[0]))
		elif (result[2]):
			strings.append("{} {} (".format(result[0], result[0].upper()))
		else:
			strings.append("{} {} ()".format(result[0], result[0].upper()))
		if (result[1]):
			for line in result[1]:
				strings.append("{}{}".format(indent, line))
			strings.append("{}) {} (".format(indent, result[0].upper()))
		if (result[2]):
			for line in result[2]:
				strings.append("{}{}".format(indent, line))
			strings.append("{});".format(indent))
		strings.append("")
	return "\n".join(strings)

if __name__ == "__main__":
	import sys
	data = None
	if (len(sys.argv) > 1):
		data = readFile(sys.argv[1])
	if (not data):
		data = readClip()
	result = getInterface(data)
	if (result):
		writeClip(result)
	