require 'fileutils'

module ArgumentsHelper
    def ensure_array(a)
        if (a.respond_to? :[])
            return a
        end
        [a]
    end
end

class String
    def ends_with?(s)
        reverse.index(s) == 0
    end
end

class Array
    def each_joined(joiner)
        last = size - 1
        for i in 0..last
            joiner.call if i > 0
            yield self[i]
        end
    end
end

module Guff
    module JavaSource

        module ClientSyntaxSupport
            def annotation(type)
                a = Annotation.new(type)
                yield a if block_given?
                a
            end
        end

        module AnnotationSupport
            def add_annotation(type)
                annotation = Annotation.new(type)
                @annotations << annotation
                yield annotation if block_given?
                self
            end

            def write_annotations_to(writer)
                @annotations.each {|a|
                    a.write_to(writer)
                    writer.new_line
                }
            end
        end

        module ParameterSupport
            def takes(name, type)
                @parameters << Parameter.new(name, type)
                self
            end
        end

        module ScopeSupport
            def package_local
                @scope = ''
                self
            end

            def protected
                @scope = 'protected'
                self
            end

            def public
                @scope = 'public'
                self
            end

            def private
                @scope = 'private'
                self
            end
        end

        module ModifierSupport
            def static
                @modifiers << 'static'
                self
            end

            def final
                @modifiers << 'final'
                self
            end

            def abstract
                @modifiers << 'abstract'
                self
            end
        end

        class Property
            def initialize(name, value)
                @name = name
                @value = value
            end

            def write_to(writer)
                writer.append(@name).append("=")
                @value.write_to(writer) if @value.respond_to? :write_to
                writer.append(@value) unless @value.respond_to? :write_to
            end
        end

        class Annotation
            def initialize(type)
                @type = type
                @properties = []
            end

            def write_to(writer)
                writer.append("@#{@type}")
                write_properties_to(writer) unless @properties.empty?
            end

            def write_properties_to(writer)
                writer.append("(").indent.new_line
                joiner = proc {
                    writer.append(",").new_line
                }
                writer.append_all(@properties, joiner)
                writer.outdent.new_line.append(")")
            end

            def add_property(name, value)
                @properties << Property.new(name, value)
                self
            end
        end

        class Parameter
            def initialize(n, t)
                @name=n
                @guff_type=t
            end

            def as_source
                "#{guff_type} #{@name}"
            end

            def name
                @name
            end

            def guff_type
                @guff_type
            end
        end

        class Constructor
            include ArgumentsHelper, ParameterSupport, AnnotationSupport

            def initialize(declaring_class,name)
                @declaring_class=declaring_class
                @name = name
                @parameters = []
                @annotations = []
                @body = Body.default_body
            end
            
            def for_field(field_name)
              takes(field_name,@declaring_class.field(field_name).declared_type).body {|body|
                body.line("this.#{field_name}=#{field_name};")
              }
            end

            def body
                @body = Body.new
                yield @body
                self
            end

            def parameters_as_types
                result = []
                @parameters.each {|p|
                    result << p.guff_type
                }
                result.join(',')
            end

            def parameters
                result = []
                @parameters.each {|p|
                    result << p.as_source
                }
                result.join(',')
            end

            def write_to(writer)
                writer.ensure_member_separation_line
                write_annotations_to(writer)
                write_declaration(writer)
                @body.write_to(writer) unless @body.nil?
            end

            def write_declaration(writer)
                writer.append("public #{@name}(" ).append(parameters).append(")")
            end
        end

        module BodyBits
            class Line
                def initialize(l)
                    @line = l
                end

                def write_to(writer)
                    writer.line(@line)
                end
            end

            class Text
                def initialize(t)
                    @text = t
                end

                def write_to(writer)
                    writer.append(@text)
                end
            end

            class NestedBody
                def initialize(body)
                    @body = body
                end

                def write_to(writer)
                    @body.write_to(writer)
                end
            end
        end

        class Body
            def self.default_body
                EmptyBody.new
            end

            def initialize
                @bits = []
            end

            def line(l)
                @bits << BodyBits::Line.new(l)
                self
            end

            def append(t)
                @bits << BodyBits::Text.new(t)
                self
            end

            def body
                nested = Body.new
                @bits << BodyBits::NestedBody.new(nested)
                yield nested
                self
            end

            def write_to(writer)
                writer.open_brace
                @bits.each {|bit|
                    bit.write_to(writer)
                }
                writer.close_brace
            end
        end

        class EmptyBody < Body
            def write_to(writer)
                writer.semi_colon.new_line
            end
        end

        class Method < Constructor
            include ScopeSupport, ModifierSupport, AnnotationSupport

            def initialize(declaring_class,name)
                super(declaring_class,name)
                @return_type = 'void'
                @modifiers = []
                @scope = 'public'
                @annotations = []
                @exceptions=[]
            end

            def returns(t)
                @return_type = t
                self
            end
            
            def throws(e)
                @exceptions << e
                self
            end

            def returns_list_of(t)
                @return_type= "List<#{t}>"
                self
            end

            def return_type
                @return_type
            end

            def write_declaration(writer)
                writer.word(@scope).words(@modifiers).word(@return_type).word("#{@name}(").append(parameters).append(")")
                if (!@exceptions.empty?)
                    writer.append(' throws ').append(@exceptions.join(', '))
                end
            end

            def write_declaration_as_types(writer)
                writer.word(@scope).words(@modifiers).word(@return_type).word("#{@name}(").append(parameters_as_types).append(")")
                if (!@exceptions.empty?)
                    writer.append(' throws ').append(@exceptions.join(', '))
                end
            end            
            
            def declaration_signature
              p=Printer.new
              write_declaration_as_types(p)
              p.new_line
              p.contents
            end
        end

        class Field
            include ScopeSupport, ModifierSupport, AnnotationSupport
            attr_reader :name
            
            def initialize(name, type)
                @name = name
                @type = type
                @scope = 'private'
                @modifiers = []
                @initializer = ''
                @annotations = []
            end
            
            def declared_type
              @type
            end

            def write_to(writer)
                write_annotations_to(writer)
                writer.word(@scope).words(@modifiers).word(@type).word(@name).word(@initializer).semi_colon.new_line
            end

            def initial(i)
                @initializer = "= #{i}"
                self
            end
        end

        class Class
            include ScopeSupport, ModifierSupport, AnnotationSupport

            def initialize(name, package, source_file)
                @name = name;
                @package = package
                @modifiers = ['public']
                @extends = nil
                @implements=nil
                @instance_methods = []
                @fields = []
                @constructors = []
                @source_file=source_file
                @genericized_using = ''
                @interfaces = nil
                @annotations = []
            end

            def add_field(name, type)
                f = Field.new(name, type)
                @fields << f
                f
            end
            
            def field(field_name)
              (@fields.select {|f| f.name == field_name}).first
            end

            def genericized_using(g)
                @genericized_using = g
                self
            end

            def name
                @name
            end

            def fully_qualified_name
                "#{@package}.#{@name}"
            end

            def extends(d)
                @extends = d
                self
            end

            def implements(*interfaces)
                @implements = interfaces
                self
            end

            def add_method(name)
                result = Method.new(self,name)
                @instance_methods << result
                result
            end

            def add_constructor
                result = Constructor.new(self,@name)
                @constructors << result
                result
            end
            
            def import(i)
                @source_file.import(i)
                self
            end

            def write_to(writer)
                write_annotations_to(writer)
                writer.words(@modifiers).word("class").word(@name).append(@genericized_using).word_with_prefix('extends', @extends).list_with_prefix('implements', @implements).open_brace

                @fields.each {|f|
                    f.write_to(writer)
                }
                @constructors.each {|c|
                    c.write_to(writer)
                }
                written_method_signatures=[]
                @instance_methods.each {|m|
                    if(!written_method_signatures.include?(m.declaration_signature)) 
                      m.write_to(writer)
                      written_method_signatures << m.declaration_signature
                    end
                }
                writer.close_brace
            end
        end

        class SourceFile
            def initialize
                @package = 'set the package'
                @classes = []
                @imports = []
            end

            def save_in(root)
                writer = Printer.new
                write_to(writer)
                directory = "#{root}/#{package_as_directory}"
                if (!FileTest.exist?(directory))
                    FileUtils.mkdir_p(directory)
                end
                filename =  directory << "/" << @name << ".java"
                file = File.new(filename, "w")
                file.write(writer.contents)
                file.close
                filename
            end

            def package_as_directory
                @package.split('.').join('/')
            end

            def package(p)
                @package=p
                self
            end

            def begin_class(name)
                @name = name
                result = Class.new(name, @package, self)
                @classes << result
                yield result if block_given?
                self
            end

            def write_to(writer)
                writer.line(package_def).line
                @imports.each do |import|
                    writer.line("import #{import};")
                end
                if (!@imports.empty?)
                    writer.line
                end
                @classes.each {|c|
                    c.write_to(writer)
                }
                writer
            end

            def package_def
                "package #{@package};"
            end
            
            def import(i)
                (@imports << i) unless @imports.include?(i)
                self
            end
        end

        class Printer
            def initialize
                @text=""
                @indent=0
                @current_line = nil
            end

            def line(s="")
                append(s)
                new_line
            end

            def append(s)
                if (@current_line.nil?)
                    @current_line = indent_text
                end
                @current_line << s.to_s
                self
            end

            def append_all(writers, joiner)
                writers.each_joined(joiner) {|w|
                    w.write_to(self)
                }
            end

            def word_with_prefix(prefix, w)
                if (w.to_s.size>0)
                    word(prefix).word(w)
                end
                self
            end

            def words_with_prefix(prefix, ww)
                if (ww.nil? == false && ww.size > 0)
                    word(prefix).words(ww)
                end
                self
            end

            def list_with_prefix(prefix, list, joiner=',')
                if (list.nil? == false && list.size > 0)
                    word(prefix).word(list.join(joiner))
                end
                self
            end

            def ensure_member_separation_line
                if (!@text.ends_with?("\n\n"))
                    new_line
                end
            end

            def word(w)
                if (w.to_s.size > 0)
                    if (!@current_line.nil? && !@text.ends_with?(' '))
                        w = " #{w}"
                    end
                    append(w)
                end
                self
            end

            def words(ww)
                ww.each {|w|
                    word(w)
                }
                self
            end

            def semi_colon
                append(';')
            end

            def indent_text
                result = ""
                @indent.times {
                    result << "    "
                }
                result
            end


            def new_line
                @text << @current_line unless @current_line.nil?
                @text << "\n"
                @current_line=nil
                self
            end

            def indent
                @indent += 1
                self
            end

            def outdent
                @indent -= 1
                self
            end

            def open_brace
                line("{")
                indent
            end

            def close_brace
                outdent
                line("}")
            end

            def contents
                @text
            end
        end
    end
end
