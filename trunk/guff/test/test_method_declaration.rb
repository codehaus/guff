require File.dirname(__FILE__) + '/test_helper.rb'

class MethodDeclarationTest < Test::Unit::TestCase
    include JavaSourceTestHelper
    
    def test_can_declare_methods_throwing_exceptions
      the_class=Guff::JavaSource::Class.new('MyClass','',nil)
      method=the_class.add_method('throwsSomething').throws("java.lang.NullPointerException").throws("SomeOtherException")
      expected = "public void throwsSomething() throws java.lang.NullPointerException, SomeOtherException;"
      printer = Guff::JavaSource::Printer.new
      method.write_to(printer)
      assert_equal expected.strip, printer.contents.strip
    end

    def test_can_declare_methods
        source = new_source_file.package('guff.test')
        source.begin_class('ClassWithMethods') {|c|
            c.add_method("getName").private.static.final.returns(:String).body { |body|
                body.line('return "Fred";')
            }

            c.add_method('isHappy').protected.takes('name', :String).takes('p', 'pkg.Person').takes('f', 'pkg.Friend').returns(:boolean).body { |body|
                body.append('if(f.hasMoney())').body { |nested|
                    nested.append('if(p.hasHealth())').body { |nested2|
                        nested2.line('return true;')
                    }
                }
                body.line("return false;")
            }
        }

        assert_source_file_equals(source, prepared_file_for_tests('ClassWithMethods'))
    end
    
    def test_only_first_version_of_methods_with_same_declaration_get_written
        source = new_source_file.package('guff.test')
        source.begin_class('ClassWithMethods') {|c|
            c.add_method("getName").private.static.final.returns(:String).body { |body|
                body.line('return "Fred";')
            }

            c.add_method("getName").private.static.final.returns(:String).body { |body|
                body.line('return "Fred";')
            }

            c.add_method('isHappy').protected.takes('name', :String).takes('p', 'pkg.Person').takes('f', 'pkg.Friend').returns(:boolean).body { |body|
                body.append('if(f.hasMoney())').body { |nested|
                    nested.append('if(p.hasHealth())').body { |nested2|
                        nested2.line('return true;')
                    }
                }
                body.line("return false;")
            }

            c.add_method('isHappy').protected.takes('myName', :String).takes('myPerson', 'pkg.Person').takes('myFriend', 'pkg.Friend').returns(:boolean).body { |body|
                body.line("return false;")
            }
        }
        assert_source_file_equals(source, prepared_file_for_tests('ClassWithMethods'))
    end
end
