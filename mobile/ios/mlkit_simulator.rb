# Lets ML Kit run on Apple Silicon simulators (iOS 26+, arm64 only).
#
# Google ships ML Kit as "fat" static frameworks: x86_64 (Intel simulator) +
# arm64 built for *devices*. An arm64 simulator refuses to link device code,
# so on every `pod install` we build a simulator copy of each framework under
# Pods/_SimulatorArm64, where the arm64 objects are re-tagged from platform
# iOS (2) to iOS simulator (7). The objects already carry an LC_BUILD_VERSION
# load command, so the tag is rewritten in place: no size change, no
# extraction, duplicate member names in the archives are harmless.
#
# Only simulator builds see the copy (FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]);
# device and archive builds keep linking Google's untouched binaries.
require 'fileutils'
require 'tmpdir'

module MlkitSimulator
  FRAMEWORKS = %w[
    MLImage
    MLKitCommon
    MLKitFaceDetection
    MLKitTextRecognition
    MLKitTextRecognitionCommon
    MLKitVision
  ].freeze
  OUTPUT_DIR = '_SimulatorArm64'.freeze
  SEARCH_PATH_VARIABLE = 'MLKIT_SIMULATOR_FRAMEWORKS'.freeze

  MH_MAGIC_64 = 0xfeedfacf
  LC_BUILD_VERSION = 0x32
  LC_VERSION_MIN_IPHONEOS = 0x25
  PLATFORM_IOS = 2
  PLATFORM_IOS_SIMULATOR = 7

  class Error < StandardError; end

  def self.install(installer)
    pods_root = installer.sandbox.root
    output = pods_root + OUTPUT_DIR
    FileUtils.rm_rf(output)
    built = FRAMEWORKS.filter_map do |name|
      source = pods_root + name + 'Frameworks' + "#{name}.framework"
      next unless source.exist?

      build_simulator_copy(source, output, name)
      name
    end
    return if built.empty?

    point_simulator_builds_at(installer, built)
    allow_simulator_arm64_in_pod_targets(installer, built)
    Pod::UI.puts "ML Kit: simulator arm64 copies built for #{built.join(', ')}"
  end

  def self.build_simulator_copy(source, output, name)
    FileUtils.mkdir_p(output)
    copy = output + "#{name}.framework"
    FileUtils.cp_r(source, copy)
    binary = (copy + name).to_s

    Dir.mktmpdir do |tmp|
      device_arm64 = File.join(tmp, 'arm64')
      intel = File.join(tmp, 'x86_64')
      lipo('-thin', 'arm64', binary, '-output', device_arm64)
      lipo('-thin', 'x86_64', binary, '-output', intel)

      data = File.binread(device_arm64)
      patched = retag(data, name)
      File.binwrite(device_arm64, data)
      lipo('-create', intel, device_arm64, '-output', binary)
      Pod::UI.puts "ML Kit: #{name} - #{patched} arm64 object(s) re-tagged for the simulator"
    end
  end

  # Rewrites the platform of every arm64 Mach-O object in +data+ (a static
  # archive or a single object). Returns the number of objects patched.
  def self.retag(data, name)
    if data.start_with?("!<arch>\n")
      patched = 0
      each_archive_member(data) do |offset, member_name|
        patched += retag_object(data, offset, "#{name}(#{member_name})")
      end
      patched
    else
      retag_object(data, 0, name)
    end
  end

  def self.each_archive_member(data)
    position = 8
    while position + 60 <= data.bytesize
      header = data.byteslice(position, 60)
      raw_name = header.byteslice(0, 16).strip
      size = header.byteslice(48, 10).strip.to_i
      body = position + 60
      if raw_name.start_with?('#1/')
        name_length = raw_name[3..].to_i
        member_name = data.byteslice(body, name_length).delete("\0")
        body += name_length
      else
        member_name = raw_name
      end
      yield body, member_name
      position += 60 + size
      position += 1 if position.odd?
    end
  end

  # Symbol tables, other non-object members and objects without a platform
  # are left alone (returns 0).
  def self.retag_object(data, offset, label)
    return 0 unless data.byteslice(offset, 4)&.unpack1('V') == MH_MAGIC_64

    command_count = data.byteslice(offset + 16, 4).unpack1('V')
    cursor = offset + 32
    command_count.times do
      command, size = data.byteslice(cursor, 8).unpack('VV')
      case command
      when LC_BUILD_VERSION
        platform = data.byteslice(cursor + 8, 4).unpack1('V')
        return 0 if platform == PLATFORM_IOS_SIMULATOR
        raise Error, "#{label}: unexpected platform #{platform}" unless platform == PLATFORM_IOS

        data[cursor + 8, 4] = [PLATFORM_IOS_SIMULATOR].pack('V')
        return 1
      when LC_VERSION_MIN_IPHONEOS
        raise Error, "#{label}: LC_VERSION_MIN_IPHONEOS cannot be re-tagged in place"
      end
      cursor += size
    end
    # No platform command at all (MLKitFaceDetection ships one pre-linked
    # object like that): the linker does not bind it to a platform, so it
    # links as is on both device and simulator.
    0
  end

  def self.point_simulator_builds_at(installer, frameworks)
    installer.aggregate_targets.each do |target|
      target.xcconfigs.each do |config_name, xcconfig|
        paths = xcconfig.attributes['FRAMEWORK_SEARCH_PATHS'].to_s
        next unless frameworks.any? { |name| paths.include?("/#{name}/Frameworks") }

        unless paths.include?(SEARCH_PATH_VARIABLE)
          xcconfig.attributes['FRAMEWORK_SEARCH_PATHS'] = "$(#{SEARCH_PATH_VARIABLE}) #{paths}"
        end
        xcconfig.attributes["#{SEARCH_PATH_VARIABLE}[sdk=iphonesimulator*]"] = "\"${PODS_ROOT}/#{OUTPUT_DIR}\""
        allow_simulator_arm64(xcconfig.attributes)
        xcconfig.save_as(target.xcconfig_path(config_name))
      end
    end
  end

  # The ML Kit podspecs exclude arm64 from simulator builds, and Flutter copies
  # that exclusion into Generated.xcconfig: the app then builds x86_64 only,
  # which iOS 26+ simulators refuse to install. With the re-tagged copies
  # arm64 links, so the exclusion goes (any other excluded arch stays).
  SIMULATOR_EXCLUDED_ARCHS = 'EXCLUDED_ARCHS[sdk=iphonesimulator*]'.freeze

  def self.allow_simulator_arm64(attributes)
    archs = attributes[SIMULATOR_EXCLUDED_ARCHS].to_s.split - ['arm64']
    if archs.empty?
      attributes.delete(SIMULATOR_EXCLUDED_ARCHS)
    else
      attributes[SIMULATOR_EXCLUDED_ARCHS] = archs.join(' ')
    end
  end

  def self.allow_simulator_arm64_in_pod_targets(installer, frameworks)
    support = installer.sandbox.target_support_files_root
    (frameworks + ['GoogleMLKit']).each do |pod|
      Dir.glob((support + pod + '*.xcconfig').to_s).each do |path|
        lines = File.readlines(path)
        kept = lines.reject { |line| line.strip == "#{SIMULATOR_EXCLUDED_ARCHS} = arm64" }
        File.write(path, kept.join) if kept.size != lines.size
      end
    end
  end

  def self.lipo(*args)
    system('xcrun', 'lipo', *args) || raise(Error, "lipo #{args.join(' ')} failed")
  end
end
