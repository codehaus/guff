require 'test/unit'

class TestConstructors < Test::Unit::TestCase
    
    def test_constructor_supports_for_field_clause
      the_class = Guff::JavaSource::Class.new("MyClass", "", nil)
      the_class.add_field("testcase","org.jmock.cglib.MockObjectTestCase")
      constructor = the_class.add_constructor.for_field("testcase")
      expected = <<END
public MyClass(org.jmock.cglib.MockObjectTestCase testcase){
    this.testcase=testcase;
}      
END
      printer = Guff::JavaSource::Printer.new
      constructor.write_to(printer)
      assert_equal expected.strip, printer.contents.strip
    end
end
