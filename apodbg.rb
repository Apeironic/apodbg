#!/usr/bin/env ruby
# Sean McCalib - 01/24/15
# Modified - 01/25/15
# Public Domain - All code that I have written in this file is public domain
# apodbg - This Program is designed to  Fetch NASA's Picture of the Day and set it as the users background. The program matains an archieve of image files in a user chosen directory

require 'rubygems'
require 'nokogiri'  #Used to parse page to find Image URL
require 'open-uri'  #Used to Open URL to fetch data
require 'net/http'  #Used to fetch Image
require 'fileutils' #Used to Make User Image Directory Recursively
require 'yaml'      #Used for config file

$configfile = '/home/yang/.config/apod/apod.yaml' #This global variable contians the location of the config file
base = 'http://apod.nasa.gov/apod/' #This Global Variable is the Base URL for Nasa's APOD Program

#Defaults
# This is a list of default settigs in case the config file can't be found
default_img_dir = '/home/yang/public/pictures/apod/'
default_bg_command = 'feh --bg-max'
default_image_exts = [ '.gif' , '.png' , '.jpg' , '.jpeg' ]
fetch_date = Time.now.strftime("%y%m%d")

#Read Config File
config = YAML.load_file($configfile)
bg_command = config["system"]["bg_command"]
img_dir = config["system"]["img_dir"]
$image_exts = config["system"]["image_exts"]


#Find out what day to fetch
if (ARGV.length >= 1)
	fetch_date = ARGV[0]
	puts "Date: #{fetch_date}"
else
	puts "Running with no arguments. Fetching Todays Image"
end
uri = "#{base}/ap#{fetch_date}.html"

#Be sure the Image Directory Exists
if(! Dir.exists?(img_dir))
	puts "Creating Directory #{img_dir}"
	FileUtils.mkdir_p img_dir
end


#Do we Even need to do anything?? Does image already exist?
Dir.chdir(img_dir)
if(!Dir.glob("#{fetch_date}.*").empty?)
	    puts "Found Image for #{fetch_date}... exiting"
	    `#{bg_command} #{Dir.glob("#{fetch_date}.*")[0]}`
	    exit(1);
end

page = Nokogiri::HTML(open(uri));
img_uri =  page.css('img')[0].get_attribute('src')
link_uri = page.css('img')[0].parent.get_attribute('href')

def getImageExt(str)
	#Try a three character extension
	i = $image_exts.index(str.downcase[-4..-1])
	#Do we need to try a 4 character extension?
	if(i == nil)
		i = $image_exts.index(str.downcase[-5..-1])
	end
	return $image_exts[i] unless i == nil
	return nil
end


if (getImageExt(link_uri))
	f = open(img_dir << fetch_date << getImageExt(link_uri), "wb")
	link_uri.strip!
	link_uri.insert(0, base) unless link_uri.index('http://') == 0
	puts "Getting Image from link #{link_uri}..."
	link_uri = URI(link_uri);
	img = Net::HTTP.get(link_uri);
	puts "Writing Image #{f.path}..."
	f.write(img);
else
	f = open(img_dir << fetch_date << getImageExt(img_uri), "wb")
	img_uri.strip!
	img_uri.insert(0, base) unless img_uri.index('http://') == 0	
	puts "Getting Image #{img_uri}..."
	img_uri = URI(img_uri);
	img = Net::HTTP.get(img_uri);
	puts "Writing Image #{f.path}..."
	f.write(img);
end
`#{bg_command} #{f.path}`
f.close();
