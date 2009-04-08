require File.dirname(__FILE__) + '/test_helper.rb'

class AnnotationDeclarationTest < Test::Unit::TestCase
    include JavaSourceTestHelper, Guff::JavaSource::ClientSyntaxSupport

    def test_can_declare_annotations_on_classes_and_methods
        source = new_source_file.package('guff.test')
        source.begin_class('ClassWithAnnotatedMethods') {|c|
            c.add_annotation("javax.persistence.Entity")

            m = c.add_method("getAddressID").returns(:String)
            m.add_annotation("javax.persistence.Column") {|a|
                a.add_property("name", '"addressID"')
                a.add_property("table", '"EMP_DETAIL"')
            }
            m.body {|body|
                body.line('return "0";')
            }

            m = c.add_method("getSubscriptions").abstract.returns(:Collection)
            m.add_annotation("ManyToMany") {|a|
                a.add_property("fetch", "FetchType.EAGER")
            }

            m.add_annotation("JoinTable") {|a|
                a.add_property("name", '"CUSTOMERBEANSUBSCRIPTIONBEAN"')
                a.add_property("joinColumns", annotation("JoinColumn"){|aa|
                    aa.add_property("name", '"CUSTOMERBEAN_CUSTOMERID96"')
                    aa.add_property("referencedColumnName", '"customerid"')
                })
                a.add_property("inverseJoinColumns", annotation("JoinColumn"){|aa|
                    aa.add_property("name", '"SUBSCRIPTION_TITLE"')
                    aa.add_property("referencedColumnName", '"TITLE"')
                })
            }
        }

        assert_source_file_equals(source, prepared_file_for_tests('ClassWithAnnotatedMethods'))
    end

    def test_can_declare_annotations_on_fields
        source = new_source_file.package('guff.test')
        source.begin_class('ClassWithAnnotatedFields') {|c|
            c.add_field('id',:int).add_annotation("Id")
        }
        assert_source_file_equals(source, prepared_file_for_tests('ClassWithAnnotatedFields'))
    end
end
