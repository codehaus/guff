class JavaFileForTests
    def initialize(testcase,path)
        @testcase = testcase
        @path = path
        @bits_to_exclude = []
    end

    def without(*bits)
        @bits_to_exclude.concat(bits)
        self
    end

    def same_as(path)
        me = File.new(@path,"r")
        other_lines = read_lines(path)
        line_count=0
        me.each_line do |line|
            line = remove_section_delimiter_comments(exclude_bits(line))
            @testcase.assert_equal(line, other_lines[line_count])
            line_count = line_count + 1
        end
        me.close
        true
    end

    def remove_section_delimiter_comments(input)
        r1 = Regexp.new("\/\\*begin .*?\\*/")
        r2 = Regexp.new("\/\\*end .*?\\*/")
        input.gsub(r1,"").gsub(r2,"")
    end


    def exclude_bits(input)
        result = input
        @bits_to_exclude.each do |bit|
            result = exclude_bit(result,bit)
        end
        result
    end

    def exclude_bit(input,bit)
        r = Regexp.new("\/\\*begin #{bit}\\*\/.*?\/\\*end #{bit}\\*\/")
        input.gsub(r,"")
    end



    def read_lines(path)
        result = []
        f = File.new(path,"r")
        f.each_line do |line|
            result << line
        end
        f.close
        result
    end

end

module JavaSourceTestHelper
    def new_source_file
        Guff::JavaSource::SourceFile.new
    end

    def tmp_dir
        '.'
    end

    def prepared_file_for_tests(name)
        JavaFileForTests.new(self,File.dirname(__FILE__) + "/files/#{name}.java")
    end

    def assert_source_file_equals(source, expected)
        file_path = source.save_in(tmp_dir)
        assert expected.same_as(file_path)
    end
end

require 'test/unit'
require File.dirname(__FILE__) + '/../lib/guff/java_source.rb'
