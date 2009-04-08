require File.dirname(__FILE__) + '/test_helper.rb'

class ClassDeclarationTest < Test::Unit::TestCase
    include JavaSourceTestHelper

    def test_can_generate_an_empty_class
        source = new_source_file.package('guff.test')
        source.begin_class('EmptyClass') {}

        assert_source_file_equals(source, prepared_empty_class.without('extends','implements'))
    end

    def test_can_generate_a_class_extending_another_class
        source = new_source_file.package('guff.test')
        source.begin_class('EmptyClass') do |empty|
            empty.extends('guff.test.SuperClass')
        end

        assert_source_file_equals(source, prepared_empty_class.without('implements'))
    end

    def test_can_generate_a_class_implementing_interfaces
        source = new_source_file.package('guff.test')
        source.begin_class('EmptyClass') do |empty|
            empty.implements('guff.test.Interface','java.io.Serializable')
        end

        assert_source_file_equals(source, prepared_empty_class.without('extends'))
    end

    def test_can_generate_a_class_extending_another_class_and_implementing_interfaces
        source = new_source_file.package('guff.test')
        source.begin_class('EmptyClass') do |empty|
            empty.implements('guff.test.Interface','java.io.Serializable')
            empty.extends('guff.test.SuperClass')
        end

        assert_source_file_equals(source, prepared_empty_class)
    end

    def prepared_empty_class
        prepared_file_for_tests('EmptyClass')
    end
end
