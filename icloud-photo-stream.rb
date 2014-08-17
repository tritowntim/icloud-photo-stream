Bundler.require

Dotenv.load

album_name = ENV['ICLOUD_PHOTO_ALBUM_NAME']

sql=<<-EOS
  SELECT a.GUID     album_guid
       , name
       , ac.GUID    collection_guid
       , batchDate
       , photoDate
       , photoNumber
    FROM Albums a
    JOIN AssetCollections ac
      ON a.GUID = ac.albumGUID
   WHERE a.name = '#{album_name}'
EOS

db = SQLite3::Database.new(ENV['ICLOUD_PHOTO_SHARED_STREAM_DATABASE'])
images = db.execute(sql)

image_sub_directories = images.map { |image| image[2] }

icloud_photo_directory = ENV['ICLOUD_PHOTO_DIRECTORY']

images_by_sub_directory = image_sub_directories.map do |image_sub_directory|
  image_path = "#{icloud_photo_directory}/#{image_sub_directory}/*"
  Dir[image_path]
end

all_images = images_by_sub_directory.flatten

export_path = ENV['EXPORT_PATH']
exported, exists = 0, 0

all_images.each do |image|
  suffix = File.extname(image)
  guid = File.dirname(image).split('/').last
  file_name = File.basename(image).gsub(suffix,'')
  new_file_name =  "#{file_name}-#{guid}#{suffix}"

  export_file_path = "#{export_path}/#{new_file_name}"
  if File.file?(export_file_path)
    exists += 1
    puts "#{export_file_path} - already exists"
  else
    FileUtils.cp image, export_file_path
    exported += 1
    puts "#{export_file_path} - exported"
  end
end

puts "iCloud Photo Stream image and video file count = #{all_images.count} ..."
puts all_images.group_by { |image| File.extname(image) }.map { |ext, paths| [ext, paths.count] }.to_h
puts "image and video files: exported = #{exported}, already exists = #{exists}"
