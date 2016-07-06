'use strict';
var fs = require('fs');
var __ = require('underscore'); 

/**
 * Computes RHEL amis for different instance types using AWS CLI.
 * AMIs are sorted by time and latest one is chosen.
 *
 *
 * @param {String} region
 * @param {String} RHEL Version
 * @returns {String} ami
 */

var child_process = require('child_process');
var argv = require('minimist')(process.argv.slice(2));
var version = argv['version'] || argv['v'] || "6.5";
var RHELami = 'RHEL-'+version + "*" + "-x86_64*";
var AWS = '/usr/local/bin/aws '

function escapeRegExp(string) {
    return string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");
}

function replaceAll(string, find, replace) {
  return string.replace(new RegExp(escapeRegExp(find), 'g'), replace);
}

function getRegions() {
  var cmd = AWS + " ec2 describe-regions"
  var regions = child_process.execSync(cmd, { encoding: 'utf8' });
  regions = JSON.parse(regions);
  return __.pluck(regions.Regions,'RegionName');
}

//array of regions
var regions =  argv['region'] && argv['region'].split(",") || getRegions();


function getAMIbyName(name,region,type) {
  var cmd = AWS + " ec2 describe-images --filters \"Name=name,Values=AMI-PLACEHOLDER\" \"Name=virtualization-type,Values=VTYPE-PLACEHOLDER\" --owners 309956199498 --region REGION-PLACEHOLDER";
  cmd = replaceAll(cmd,"AMI-PLACEHOLDER",name);
  cmd = replaceAll(cmd,"REGION-PLACEHOLDER",region);
  cmd = replaceAll(cmd,"VTYPE-PLACEHOLDER",type);

  var ami = child_process.execSync(cmd, { encoding: 'utf8' });

  return JSON.parse(ami);
}

function CompareCreationDate(a,b) {
	return Date.parse(a.CreationDate) - Date.parse(b.CreationDate) 
}

function getRHELamis() {
  var types = ["paravirtual","hvm"];
  var amis = {};
  for (var v in regions) {
  	var region = regions[v];
  	var data = {};
  	for (var t in types) {
        try {
            var type = types[t];
            var ami = getAMIbyName(RHELami,region,type);
            var amiArray = Object.keys(ami.Images).map(function (key) {return ami.Images[key]});
            var amiArraySorted = amiArray.sort(CompareCreationDate);
            data[type] = amiArraySorted[amiArraySorted.length-1].ImageId;            
        }
        catch(e) {
            data[type] = ''
        }
  	}
  	amis[region] = data;
  }
  return amis;
}

var RHELamis = getRHELamis();

console.log(JSON.stringify(RHELamis, null, 4));

