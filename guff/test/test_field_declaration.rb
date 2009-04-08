require File.dirname(__FILE__) + '/test_helper.rb'

class FieldDeclarationTest < Test::Unit::TestCase
    include JavaSourceTestHelper

    def test_can_declare_fields
        source = new_source_file.package('guff.test')
        source.begin_class('ClassWithFields') {|c|
            c.add_field('name',:String).static.final.initial('"Fred"')
            c.add_field('id',:long).initial('0')
            c.add_field('user','some.other.pkg.User').initial('new some.other.pkg.User(0,2)')
            c.add_field('otherId',:int).package_local
            c.add_field('c',:char).protected
            c.add_field('flag',:boolean).public.initial('false')
        }

        assert_source_file_equals(source, prepared_file_for_tests('ClassWithFields'))
    end
end
