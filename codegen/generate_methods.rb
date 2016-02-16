require 'active_support/inflector'
require 'erb'
require 'pathname'
require_relative 'codegen_helpers'

class GenerateMethods
  include CodegenHelpers

  attr_reader :xml

  def initialize(xml)
    @xml = xml
  end

  def chassis_names(method)
    method.xpath('chassis').map {|c| c[:name]}
  end

  def outgoing?(method)
    chassis_names(method).include?('server')
  end

  def header
    <<-OBJC
#{header_start}
@import Mantle;
#import "AMQProtocolValues.h"

      OBJC
  end

  def implementation
    <<-OBJC
#{implementation_start}
#import "AMQProtocolMethods.h"

    OBJC
  end

  def generate_header
    xml.xpath("//method").reduce(header) { |acc, method|
      fields = camelized_fields(method.xpath('field'))
      constructor = constructor(fields)
      protocols = ["AMQMethod"]
      class_name = objc_class_name(method)
      acc + template('methods_header_template').result(binding)
    }
  end

  def generate_implementation
    xml.xpath("//method").reduce(implementation) { |acc, method|
      fields = camelized_fields(method.xpath('field'))
      class_name = objc_class_name(method)
      class_id = method.xpath('..').first[:index]
      method_id = method[:index]
      constructor = constructor(fields)
      class_part = method.xpath('..').first[:name].capitalize
      acc + template('methods_implementation_template').result(binding)
    }
  end
end
