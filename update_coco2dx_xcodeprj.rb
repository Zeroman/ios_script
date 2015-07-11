#!/usr/bin/ruby


# use command install : gem install xcodebuild-rb xcodeproj

require 'find'
require 'rubygems'
require 'xcodeproj'


def find_source(path, exts)
    list=[]

    Find.find(path) do |f|
        new_f = f[path.size, f.size]
        if File.directory?(f) and new_f != ''
            list << new_f
            next
        end

        ext = File.extname(f).downcase
        if exts.include?(ext)
            list << new_f
            #p new_f
        end
    end

    list.sort
    return list
end

def add_src(path, group, targets)
    exts = ['.cpp', '.h', '.m', '.mm']
    srcs = find_source path, exts
    for src in srcs
        # Add a file to the project in the main group
        file = group.find_file_by_path(path + src)
        if file == nil
            p 'add new file ' + src
            file = group.new_file(src)
        end

        ext = File.extname(src).downcase
        if ['.cpp', '.mm', '.m'].include?(ext)
            for target in targets
                target.add_file_references([file])
            end
        end
    end
end

def add_res(path, group, targets)
    exts = ['.png', '.ttf', '.wav', '.mp3', '.plist']

    ress = find_source path, exts
    for res in ress
        # Add a file to the project in the main group
        file = group.find_file_by_path(path + res)
        if file == nil
            file = group.new_file(res)
        end

        for target in targets
            target.add_resources([file])
        end
    end
end
 


product_name = "test"
if ARGV.size > 0
    product_name = ARGV[0]
end

# Open the existing Xcode prj
prj_file = product_name + '.xcodeproj'
unless File.exist?(prj_file)
    p 'Can not open ' + prj_file
    exit
end
prj = Xcodeproj::Project.open(prj_file)

p prj.targets
#p prj.groups
#p prj['Classes']
#p '------------'

for target in prj.targets
    target.source_build_phase.files.clear
    target.resources_build_phase.files.clear
end
ios_target = prj.targets[0]
mac_target = prj.targets[1]

group = prj['Classes']
group.clear
add_src('../Classes/', group, prj.targets)

group = prj['Resources']
group.clear
add_res('../Resources/', group, prj.targets)

group = prj['ios']
add_src('ios/', group, [ios_target])

group = prj['mac']
add_src('mac/', group, [mac_target])

# Save the prj file
prj.save()

