$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'java'
require 'fileutils'
require 'guff/java_source'

include_class 'com.thoughtworks.qdox.JavaDocBuilder'

module Java
    include_class 'java.io.File'
end



class String
    def java_package
        bits = split('.')
        bits.pop
        bits.join('.')
    end

    def capitalize_initial
        result = dup
        "#{result[0, 1].upcase}#{result[1, length-1]}"
    end

    def lowercase_initial
        result = dup
        "#{result[0, 1].downcase}#{result[1, length-1]}"
    end

end


module Guff
    VERSION = '0.5.1'

    module ConstructorSyntax
        def param(name, value)
            Guff::JavaSource::Parameter.new(name,value)
        end
    end

    class Class
        include ConstructorSyntax

        def initialize(java_environment, underlying)
            @java_environment = java_environment
            @underlying = underlying
            @method_inclusion_filter = all_pass
            @method_exclusion_filter = none_pass
        end

        def new_java_source_file
            JavaSource::SourceFile.new
        end

        def underlying_package
            @underlying.package
        end

        def underlying_type_name
            @underlying.name
        end

        def fully_qualified_underlying_type_name
            @underlying.fully_qualified_name
        end

        def methods
            result = @underlying.methods.select {|m|
                @method_inclusion_filter.call(m)
            }
            result.reject {|m|
                @method_exclusion_filter.call(m)
            }
        end

        def type_named(name)
            @java_environment.type_named(name)
        end

        def array_of_type_named(name)
            @java_environment.array_of_type_named(name)
        end

        def foreach_public_instance_method
            methods.each {|m|
                if (m.public_instance_method?)
                    yield m
                end
            }
        end

        def all_pass
            proc{|thing|
                true
            }
        end

        def none_pass
            proc{|thing|
                false
            }
        end

        def excluding_methods_matching(filter)
            @method_exclusion_filter = filter
            self
        end

        def including_methods_matching(filter)
            @method_inclusion_filter = filter
            self
        end
    end

    class JavaEnvironment
        def initialize()
            @qdox_builder = JavaDocBuilder.new
        end

        def add_source_tree(root)
            @qdox_builder.add_source_tree(Java::File.new(root))
            self
        end

        def type_named(name)
            @qdox_builder.get_class_by_name(name).as_type
        end

        def array_of_type_named(name)
            type_named(name).as_array
        end

        def with_class(name)
            yield Class.new(self, @qdox_builder.get_class_by_name(name))
            self
        end
    end
end


module QDox
    include_class 'com.thoughtworks.qdox.model.JavaClass'
    include_class 'com.thoughtworks.qdox.model.JavaMethod'
    include_class 'com.thoughtworks.qdox.model.Type'

    class JavaMethod
        include Guff::ConstructorSyntax

        def arguments
            result=[]
            parameters.each {|p|
                result << param(p.name.to_sym, p.type)
            }
            result
        end

        def public_instance_method?
            public? && !constructor?  &&!static
        end

        def named?(s)
            name == s
        end

        def takes_arguments?
            return parameters.length > 0
        end

        def begins_with?(b)
            name.index(b) == 0
        end

        def getter?
            begins_with?('get') && !takes_arguments? && returns_non_void?
        end

        def setter?
            begins_with?('set') && takes_one_argument? && returns_void?
        end

        def takes_one_argument?
            parameters.length == 1
        end

        def getter_renamed_with(p)
            name.sub('get', p)
        end

        def returns_boolean?
            ['boolean'].include?(returns.value)
        end

        def returns_void?
            returns.void?
        end

        def returns_non_void?
            !returns.void?
        end
    end
end
