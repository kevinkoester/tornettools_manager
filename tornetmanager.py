#!/usr/bin/env python3

import requests
import datetime
import pathlib
import shutil
import traceback

from collections import defaultdict

from subprocess import Popen, PIPE

DATA_URL_TEMPLATES = [
		"https://collector.torproject.org/archive/relay-descriptors/consensuses/consensuses-{year}-{month}.tar.xz",
		"https://collector.torproject.org/archive/relay-descriptors/server-descriptors/server-descriptors-{year}-{month}.tar.xz",
		"https://collector.torproject.org/archive/onionperf/onionperf-{year}-{month}.tar.xz",
		"https://metrics.torproject.org/bandwidth.csv?start={year}-{month}-01&end={year}-{month}-30"
		]

def call_cmd(cmd: str, cwd = None):
	print("Calling \"{}\"".format(cmd))
	process = Popen(cmd.split(" "), cwd = cwd)
	output, err = process.communicate()
	return output


def extract(path: pathlib.Path):
	cmd = "tar xaf {}".format(path.name)
	call_cmd(cmd, path.parent)

def get_dirs(data_date: datetime.date):
	data_dir = pathlib.Path("data/{}-{}".format(data_date.year, data_date.month))
	consensus_dir = data_dir / "consensuses-{year}-{month}".format(year=data_date.year, month=data_date.month)
	server_dir = data_dir / "server-descriptors-{year}-{month}".format(year=data_date.year, month=data_date.month)
	onion_dir = data_dir / "onionperf-{year}-{month}".format(year=data_date.year, month=data_date.month)
	bandwidth = data_dir / "bandwidth.csv"
	output_dir = data_dir / "output"

	return {"consensus" : consensus_dir, "server": server_dir, "onionperf": onion_dir, "bandwidth": bandwidth, "data_dir": data_dir, "output": output_dir}

def get_tornet_files(date: datetime.date):
	data_dict = get_dirs(date)
	p = data_dict["output"].glob("*")
	files = [x for x in p if x.is_file()]
	return files

def tornet_stage(date: datetime.date):
	data_dict = get_dirs(date)
	cmd = "tornettools stage {consensus} {server} {userstats} --onionperf_data_path {onionperf} --bandwidth_data_path {bandwidth} --geoip geoip --prefix {output_dir}"
	cmd = cmd.format(consensus=data_dict["consensus"], server=data_dict["server"], userstats="userstats.csv", onionperf=data_dict["onionperf"], bandwidth=data_dict["bandwidth"], output_dir=data_dict["output"])
	call_cmd(cmd)

def tornet_generate(date: datetime.date, network_scale: float, name: str):
	files = get_tornet_files(date)
	relayinfo = ""
	userinfo = ""
	tmodel = "tmodel-ccs2018.github.io"
	for f in files:
		print(f)
		if "relayinfo" in f.name:
			relayinfo = f
		if "userinfo" in f.name:
			userinfo = f
	cmd = "tornettools generate {relayinfo} {userinfo} {tmodel} --network_scale {scale} --prefix {name}".format(relayinfo=relayinfo, userinfo=userinfo, tmodel=tmodel, scale=network_scale, name=name)
	call_cmd(cmd)


def get_data(data_date: datetime.date):
	for data_template in DATA_URL_TEMPLATES:
		url = data_template.format(year=data_date.year, month=data_date.month)
		filename = url.split("/")[-1].split("?")[0]
		data_dir = pathlib.Path("data/{}-{}".format(data_date.year, data_date.month))
		data_dir.mkdir(parents=True, exist_ok=True)
		output_path = data_dir / filename
		if not output_path.is_file():
			print("Getting {}...".format(url))
			resp = requests.get(url)
			if resp.status_code == 200:
				with open(output_path, "wb") as output_file:
					output_file.write(resp.content)
					extract(output_path)
		else:
			print("{} already exists...".format(output_path))

def run_dirty(dirty_list, date, scale = 0.01):
	experiment_name = "{}-{}-dirty-{}-scale-{}".format(date.year, date.month, ",".join(map(str, dirty_list)), scale)
	experiments_to_run = []
	get_data(date)
	files = get_tornet_files(date)
	if len(files) == 0:
		tornet_stage(date)
	vanilla_name = "vanilla"
	# generate base experiment
	experiment_path = pathlib.Path(experiment_name) / "experiments"
	vanilla_path = experiment_path / vanilla_name
	tornet_generate(date, scale, vanilla_path)
	experiments_to_run.append(vanilla_path)
	# copy experiment config
	for dirtiness in dirty_list:
		dirty_path = experiment_path / "dirty-{}".format(dirtiness)
		experiments_to_run.append(dirty_path)
		try:
			shutil.copytree(vanilla_path, dirty_path)
			options_dict = defaultdict(str)
			with open(dirty_path / "conf/tor.markovclient.torrc" , "r") as conf_file:
				lines = conf_file.read().splitlines()
				for line in lines:
					splits = line.split(" ", 1)
					options_dict[splits[0]] = splits[1]
			options_dict["MaxCircuitDirtiness"] = dirtiness
			with open(dirty_path / "conf/tor.markovclient.torrc" , "w") as conf_file:
				for key, val in options_dict.items():
					conf_file.write("{} {}\n".format(key, val))
		except:
			print("Failed to copy for experiment {}. It might already exist".format(dirty_path))
			track = traceback.format_exc()
			print(track)
	
	# run experiments
	for experiment_path in experiments_to_run:
		cmd = "tornettools simulate -a \"-i node,ram\" {}".format(experiment_path)
		call_cmd(cmd)
		cmd = "tornettools parse {}".format(experiment_path)
		call_cmd(cmd)






	# change dirtiness

	# run experiment

test_date = datetime.date.fromisoformat("2020-11-01")
run_dirty([1, 10, 30, 60, 120, 180, 240, 300, 1200, 1800], test_date, 0.01)
#run_dirty([1, 1800], test_date, 0.001)

