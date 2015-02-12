#!/usr/bin/env ruby
# Sean McCalib - 01/24/15
# Modified - 01/25/15
# Public Domain - All code that I have written in this file is public domain
# apodbg - This Program is designed to  Fetch NASA's Picture of the Day and set it as the users background. The program matains an archieve of image files in a user chosen directory


#Ruby Gems Requirements Various Libraries to make my life easier. Thank You!!
require 'rubygems'
require 'nokogiri'  #Used to parse page to find Image URL
require 'open-uri'  #Used to Open URL to fetch data
require 'net/http'  #Used to fetch Image
require 'fileutils' #Used to Make User Image Directory Recursively
require 'yaml'      #Used for config file

#Global Config Variable - this variable stores our configuration, it comes preloaded with defaults!
$config = {"img_dir" => "#{ENV["HOME"]}/public/pictures/apod/", 
	  "bg_command" => "feh --bg-max",
	  "image_exts" => [ ".gif", ".png", ".jpg", ".jpeg", ".bmp"]};

$configfile = "#{ENV["HOME"]}/.config/apod/apod.yaml" #This global variable contians the location of the config file
base = 'http://apod.nasa.gov/apod/' #This Global Variable is the Base URL for Nasa's APOD Program

def makeConfigFile(values_hash, path)
	#Does Directory Exist?
	open(path, "w") do |cf|
		cf.write(values_hash.to_yaml);
	end
end

def setBg(image_path)
	`#{$config["bg_command"]}#{image_path}`
end

fetch_date = Time.now.strftime("%y%m%d")

#Read Config File
if(File.exists?($configfile))
	cf = YAML.load_file($configfile)
	$config["bg_command"] = cf["bg_command"] || $config["bg_command"]
	$config["img_dir"] = cf["img_dir"] || $config["img_dir"]
	$config["image_exts"] = cf["image_exts"] || $config["image_exts"]
else
	#make Config File
	makeConfigFile($config, $configfile)	
end


#Find out what day to fetch
if (ARGV.length >= 1)
	fetch_date = ARGV[0]
	puts "Date: #{fetch_date}"
else
	puts "Running with no arguments. Fetching Todays Image"
end
uri = "#{base}ap#{fetch_date}.html"

#Be sure the Image Directory Exists
if(! Dir.exists?($config["img_dir"]))
	puts "Creating Directory #{$config["img_dir"]}"
	FileUtils.mkdir_p $config["img_dir"]
end


#Do we Even need to do anything?? Does image already exist?
Dir.chdir($config["img_dir"])
if(!Dir.glob("#{fetch_date}.*").empty?)
	    puts "Found Image for #{fetch_date}... exiting"
	    setBg($config["img_dir"] + Dir.glob("#{fetch_date}.*")[0])
	    exit(1);
end

page = Nokogiri::HTML(open(uri));
img_uri =  page.css('img')[0].get_attribute('src')
link_uri = page.css('img')[0].parent.get_attribute('href')

def getImageExt(str)
	#Try a three character extension
	i = $config["image_exts"].index(str.downcase[-4..-1])
	#Do we need to try a 4 character extension?
	if(i == nil)
		i = $config["image_exts"].index(str.downcase[-5..-1])
	end
	return $config["image_exts"][i] unless i == nil
	return nil
end


if (getImageExt(link_uri))
	f = open($config["img_dir"] << fetch_date << getImageExt(link_uri), "wb")
	link_uri.strip!
	link_uri.insert(0, base) unless link_uri.index('http://') == 0
	puts "Getting Image from link #{link_uri}..."
	link_uri = URI(link_uri);
	img = Net::HTTP.get(link_uri);
	puts "Writing Image #{f.path}..."
	f.write(img);
else
	f = open($config["img_dir"] << fetch_date << getImageExt(img_uri), "wb")
	img_uri.strip!
	img_uri.insert(0, base) unless img_uri.index('http://') == 0	
	puts "Getting Image #{img_uri}..."
	img_uri = URI(img_uri);
	img = Net::HTTP.get(img_uri);
	puts "Writing Image #{f.path}..."
	f.write(img);
end
setBg(f.path);
f.close();
