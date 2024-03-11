#!/usr/bin/env ruby

# A generator for IIIF compatible image tiles and metadata
# Try "./create_iiif_s3.rb -h"
#
require 'iiif_s3'
require 'open-uri'
require 'optparse'
require_relative '../../lib/iiif_s3/manifest_override'
IiifS3::Manifest.prepend IiifS3::ManifestOverride

@supported_img_types = [".bmp", ".gif", ".jpg", ".jpeg", ".png", ".tif", ".tiff"]

# Create directories on local disk for manifests/tiles to upload them to S3
def create_directories(path)
  FileUtils.mkdir_p(path) unless Dir.exists?(path)
end

# Get label and description metadata from csv file
def get_metadata(csv_url, id)
  begin
    open(csv_url) do |u|
      csv_file_name = File.basename(csv_url)
      csv_file_path = "#{@config.output_dir}/#{csv_file_name}"
      File.open(csv_file_path, 'wb') { |f| f.write(u.read) }
      CSV.read(csv_file_path, 'r:bom|utf-8', headers: true).each do |row|
        if row.header?("identifier")
          if row.field("identifier") == id
            return row.field("title"), row.field("description")
          end
        else
          puts "No identifier header found"
          return
        end
      end
      puts "No matching identifier found"
    end
  rescue StandardError => e
    puts "An error occurred processing #{csv_url}: #{e.message}"
  end
end

def add_image(file, id, idx)
  name = File.basename(file, File.extname(file))
  page_num = idx + 1
  label, description = get_metadata(@csv_url, id)
  obj = {
    "path" => "#{file}",
    "id"       => id,
    "label"    => label,
    "is_master" => page_num == 1,
    "page_number" => page_num,
    "is_document" => false,
    "description" => description,
  }

  obj["section"] = "p#{page_num}"
  obj["section_label"] = "Page #{page_num}"
  @data.push IiifS3::ImageRecord.new(obj)
end

def is_image_file?(file)
  # this needs to be replaced with some mime-type guessing gem
  is_img = @supported_img_types.include?(File.extname(file).downcase)
end

options = {}
optparse = OptionParser.new do |parser|
  parser.banner = "Usage: create_iiif_s3.rb -c collection_identifer -m csv_metadata_file -i image_folder_path -b metadata_base_path -r dest_dest_root_folder"

  # short option, long option, description of the option
  parser.on("-c", "--collection_identifier ID", "Parent collection identifier") do |collection_identifier|
    options[:collection_identifier] = collection_identifier
  end
  parser.on("-m", "--metadata_file File", "Metadata CSV file") do |metadata_file|
    options[:metadata_file] = metadata_file
  end
  parser.on("-i", "--image_folder Path", "Path to image folder") do |img_folder|
    options[:image_folder] = img_folder
  end
  parser.on("-b", "--base_path Path", "Base path of metadata file") do |base_path|
    options[:base_url] = base_path
  end
  parser.on("-r", "--dest_root_folder Path", "Path to root folder") do |dest_root_folder|
    options[:dest_root_folder] = dest_root_folder
  end
  # s3 upload is handled in the bash calling script after tiling completes
  options[:upload_to_s3] = false
  parser.on_tail("-h", "--help", "Prints this help") do
    puts parser
    exit
  end
end.parse!

unless @csv_url = options[:metadata_file]
  puts "Please provide metadata_file name."
  puts "Try './create_iiif_s3.rb -h'"
  exit
else
  begin
    # collection pattern, e.g., Ms1990_025, is legacy and no longer required
    collection_identifier = options[:collection_identifier]
    unless image_folder_path = options[:image_folder]
      puts "Please provide path to image folder."
      puts "Try './create_iiif_s3.rb -h'"
      exit
    else
      begin
        @input_folder = image_folder_path.slice(image_folder_path.index("#{collection_identifier}")..-1)
        puts "Access folder: #{@input_folder}"
        # # sort image files in the image folder
        # all_access_image_files = Dir[image_folder_path + "*"]
        # @image_files = all_access_image_files.select{ |f| is_image_file?(f) }.sort        
      rescue StandardError => e
        puts "An error occurred processing image folder at #{image_folder_path}: #{e.message}"
      end
    end
  rescue StandardError => e
      puts "An error occurred process manifest file #{@csv_url}: #{e.message}"
  end
end

# Setup Temporary stores
@data = []
# Set up configuration variables
opts = {}
unless opts[:base_url] = options[:base_url]
  puts "Please provide base path for manifest file."
  puts "Try './create_iiif_s3.rb -h'"
  exit
end
opts[:image_directory_name] = "tiles"
opts[:output_dir] = "tmp"
opts[:variants] = { "reference" => 600, "access" => 1200 }
# get the option if upload to S3, absence is false, presence is true
opts[:upload_to_s3] = false
opts[:image_types] = @supported_img_types
opts[:document_file_types] = [".pdf"]
# prefix uses dest_root_folder
unless options[:dest_root_folder]
  puts "Please provide path to root folder"
  puts "Try './create_iiif_s3.rb -h'"
  exit
else
  opts[:prefix] = "#{options[:dest_root_folder]}/#{@input_folder.split('/')[0..-3].join('/')}"
end

puts "Instantiating IIIF S3 Builder"
iiif = IiifS3::Builder.new(opts)
@config = iiif.config

puts "IiifS3::Builder configuration: (iiif.config)"
puts @config.inspect
# sort image files in the image folder
begin
  all_access_image_files = Dir[image_folder_path + "*"]
  @image_files = all_access_image_files.select{ |f| is_image_file?(f) }.sort
rescue StandardError => e
  puts "An error occurred processing image folder at #{image_folder_path}: #{e.message}"
end

path = "#{@config.output_dir}#{@config.prefix}/"
create_directories(path)

# generate a path on disk for "output_dir/prefix/image_dir"
img_dir = "#{path}#{@config.image_directory_name}/".split("/")[0...-1].join("/")
create_directories(img_dir)

id = @input_folder.split("/")[-2]

@image_files.each_with_index do |image_file, idx|
  puts "Adding image file #{image_file} to iiif data object..."
  add_image(image_file, id, idx)
end
puts "Passing iiif data object to iiif_s3 gem for processing..."
iiif.load(@data)
iiif.process_data
puts "Processing complete"
puts "Exiting job."
