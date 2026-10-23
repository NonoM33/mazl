# ruby ios/test/mlkit_simulator_test.rb
#
# The fixtures are built from the formats themselves (<mach-o/loader.h>,
# BSD ar with "#1/<len>" long names), not from the code under test.
require 'minitest/autorun'
require_relative '../mlkit_simulator'

class MlkitSimulatorTest < Minitest::Test
  MH_MAGIC_64 = 0xfeedfacf
  CPU_TYPE_ARM64 = 0x0100000c
  MH_OBJECT = 1
  LC_SYMTAB = 0x2
  LC_BUILD_VERSION = 0x32
  LC_VERSION_MIN_IPHONEOS = 0x25

  # A minimal arm64 object: header + the given load commands.
  def object(*commands)
    body = commands.join
    header = [MH_MAGIC_64, CPU_TYPE_ARM64, 0, MH_OBJECT, commands.size, body.bytesize, 0, 0].pack('V8')
    (header + body).b
  end

  def build_version(platform)
    # cmd, cmdsize, platform, minos 15.5, sdk 18.0, ntools
    [LC_BUILD_VERSION, 24, platform, 0x000f0500, 0x00120000, 0].pack('V6')
  end

  def symtab
    [LC_SYMTAB, 24, 0, 0, 0, 0].pack('V6')
  end

  def version_min
    [LC_VERSION_MIN_IPHONEOS, 16, 0x000f0500, 0x00120000].pack('V4')
  end

  def archive(members)
    out = +"!<arch>\n"
    members.each do |name, data|
      padded_name = name + "\0" * ((4 - name.bytesize % 4) % 4)
      content = padded_name + data
      header = format('%-16s%-12s%-6s%-6s%-8s%-10s`', "#1/#{padded_name.bytesize}", 0, 0, 0, 644, content.bytesize) + "\n"
      out << header << content
      out << "\n" if out.bytesize.odd?
    end
    out.b
  end

  def platforms(data)
    data.enum_for(:scan, [LC_BUILD_VERSION, 24].pack('VV').b).map do
      offset = Regexp.last_match.begin(0)
      data.byteslice(offset + 8, 4).unpack1('V')
    end
  end

  def test_retags_every_object_of_an_archive_including_duplicate_names
    data = archive([
      ['__.SYMDEF SORTED', 'not a mach-o'],
      ['a.o', object(symtab, build_version(2))],
      ['a.o', object(build_version(2), symtab)],
      ['b.o', object(build_version(2))],
    ])
    size = data.bytesize

    assert_equal 3, MlkitSimulator.retag(data, 'Fixture')
    assert_equal [7, 7, 7], platforms(data)
    assert_equal size, data.bytesize, 'the archive must keep its exact size'
  end

  def test_retags_a_single_object
    data = object(symtab, build_version(2))
    assert_equal 1, MlkitSimulator.retag(data, 'Single')
    assert_equal [7], platforms(data)
  end

  def test_leaves_simulator_objects_alone
    data = object(build_version(7))
    assert_equal 0, MlkitSimulator.retag(data, 'Already')
    assert_equal [7], platforms(data)
  end

  def test_leaves_objects_without_a_platform_alone
    data = object(symtab)
    original = data.dup
    assert_equal 0, MlkitSimulator.retag(data, 'Prelinked')
    assert_equal original, data
  end

  def test_refuses_an_unexpected_platform
    error = assert_raises(MlkitSimulator::Error) { MlkitSimulator.retag(object(build_version(1)), 'Mac') }
    assert_match(/unexpected platform 1/, error.message)
  end

  def test_refuses_version_min_commands_it_cannot_rewrite_in_place
    error = assert_raises(MlkitSimulator::Error) { MlkitSimulator.retag(object(version_min), 'Old') }
    assert_match(/LC_VERSION_MIN_IPHONEOS/, error.message)
  end
end
