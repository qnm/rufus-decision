
#
# testing rufus-decision
#
# 2007 something
#

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

require 'test/unit'
require 'rubygems'
require 'rufus/decision'


module DecisionTestMixin

  protected

  def do_test (table_data, h, expected_result, verbose=false)

    table = table_data.is_a?(Rufus::Decision::Table) ?
      table_data :
      Rufus::Decision::Table.new(table_data)

    if verbose
      puts
      puts 'table :'
      puts table.to_csv
      puts
      puts 'before :'
      p h
    end

    h = table.transform!(h)

    if verbose
      puts
      puts 'after :'
      p h
    end

    expected_result.each do |k, v|

      value = h[k]

      value = value.join(';') if value.is_a?(Array)

      assert_equal v, value
    end
  end

end

