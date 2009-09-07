#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


require 'csv'
require 'open-uri'

require 'rubygems'
require 'rufus/dollar'

require 'rufus/hashes'


module Rufus
module Decision

  VERSION = '1.1.0'

  #
  # A decision table is a description of a set of rules as a CSV (comma
  # separated values) file. Such a file can be edited / generated by
  # a spreadsheet (Excel, Google spreadsheets, Gnumeric, ...)
  #
  # == Disclaimer
  #
  # The decision / CSV table system is no replacement for
  # full rule engines with forward and backward chaining, RETE implementation
  # and the like...
  #
  #
  # == Usage
  #
  # The following CSV file
  #
  #   in:topic,in:region,out:team_member
  #   sports,europe,Alice
  #   sports,,Bob
  #   finance,america,Charly
  #   finance,europe,Donald
  #   finance,,Ernest
  #   politics,asia,Fujio
  #   politics,america,Gilbert
  #   politics,,Henry
  #   ,,Zach
  #
  # embodies a rule for distributing items (piece of news) labelled with a
  # topic and a region to various members of a team.
  # For example, all news about finance from Europe are to be routed to
  # Donald.
  #
  # Evaluation occurs row by row. The "in out" row states which field
  # is considered at input and which are to be modified if the "ins" do
  # match.
  #
  # The default behaviour is to change the value of the "outs" if all the
  # "ins" match and then terminate.
  # An empty "in" cell means "matches any".
  #
  # Enough words, some code :
  #
  #   require 'rufus/decision'
  #
  #   table = Rufus::Decision::Table.new(%{
  #     in:topic,in:region,out:team_member
  #     sports,europe,Alice
  #     sports,,Bob
  #     finance,america,Charly
  #     finance,europe,Donald
  #     finance,,Ernest
  #     politics,asia,Fujio
  #     politics,america,Gilbert
  #     politics,,Henry
  #     ,,Zach
  #   })
  #
  #   h = {}
  #   h["topic"] = "politics"
  #
  #   table.transform!(h)
  #
  #   puts h["team_member"]
  #     # will yield "Henry" who takes care of all the politics stuff,
  #     # except for Asia and America
  #
  # '>', '>=', '<' and '<=' can be put in front of individual cell values :
  #
  #   table = Rufus::Decision::Table.new(%{
  #     ,
  #     in:fx, out:fy
  #     ,
  #     >100,a
  #     >=10,b
  #     ,c
  #   })
  #
  #   h = { 'fx' => '10' }
  #   h = table.transform(h)
  #
  #   p h # => { 'fx' => '10', 'fy' => 'b' }
  #
  # Such comparisons are done after the elements are transformed to float
  # numbers. By default, non-numeric arguments will get compared as Strings.
  #
  #
  # == transform and transform!
  #
  # The method transform! acts directly on its parameter hash, the method
  # transform will act on a copy of it. Both methods return their transformed
  # hash.
  #
  #
  # == [ruby] ranges
  #
  # Ruby-like ranges are also accepted in cells.
  #
  #   in:f0,out:result
  #   ,
  #   0..32,low
  #   33..66,medium
  #   67..100,high
  #
  # will set the field 'result' to 'low' for f0 => 24
  #
  #
  # == Options
  #
  # You can put options on their own in a cell BEFORE the line containing
  # "in:xxx" and "out:yyy" (ins and outs).
  #
  # Three options are supported, "ignorecase", "through" and "accumulate".
  #
  # * "ignorecase", if found by the decision table will make any match (in the
  #   "in" columns) case unsensitive.
  #
  # * "through", will make sure that EVERY row is evaluated and potentially
  #   applied. The default behaviour (without "through"), is to stop the
  #   evaluation after applying the results of the first matching row.
  #
  # * "accumulate", behaves as with "through" set but instead of overriding
  #   values each time a match is found, will gather them in an array.
  #
  # an example of 'accumulate'
  #
  #   accumulate
  #   in:f0,out:result
  #   ,
  #   ,normal
  #   >10,large
  #   >100,xl
  #
  #   will yield { result => [ 'normal', 'large' ]} for f0 => 56
  #
  # === Setting options at table initialization
  #
  # It's OK to set the options at initialization time :
  #
  #   table = Rufus::Decision::Table.new(
  #     csv, :ruby_eval => true, :accumulate => true)
  #
  #
  # == Cross references
  #
  # By using the 'dollar notation', it's possible to reference a value
  # already in the hash (that is, the hash undergoing 'transformation').
  #
  #   in:value,in:roundup,out:newvalue
  #   0..32,true,32
  #   33..65,true,65
  #   66..99,true,99
  #   ,,${value}
  #
  # Here, if 'roundup' is set to true, newvalue will hold 32, 65 or 99
  # as value, else it will simply hold the 'value'.
  #
  # The value is the value as currently found in the transformed hash, not
  # as found in the original (non-transformed) hash.
  #
  #
  # == Ruby code evaluation
  #
  # The dollar notation can be used for yet another trick, evaluation of
  # ruby code at transform time.
  #
  # Note though that this feature is only enabled via the :ruby_eval
  # option of the transform!() method.
  #
  #   decisionTable.transform!(h, :ruby_eval => true)
  #
  # That decision table may look like :
  #
  #   in:value,in:result
  #   0..32,${r:Time.now.to_f}
  #   33..65,${r:call_that_other_function()}
  #   66..99,${r:${value} * 3}
  #
  # (It's a very simplistic example, but I hope it demonstrates the
  # capabilities of this technique)
  #
  # It's OK to set the :ruby_eval parameter when initializing the decision
  # table :
  #
  #   table = Rufus::Decision::Table.new(csv, :ruby_eval => true)
  #
  # so that there is no need to specify it at transform() call time.
  #
  #
  # == See also
  #
  # * http://jmettraux.wordpress.com/2007/02/11/ruby-decision-tables/
  #
  class Table

    IN = /^in:/
    OUT = /^out:/
    IN_OR_OUT = /^(in|out):/
    NUMERIC_COMPARISON = /^([><]=?)(.*)$/

    # when set to true, the transformation process stops after the
    # first match got applied.
    #
    attr_accessor :first_match

    # when set to true, matches evaluation ignores case.
    #
    attr_accessor :ignore_case

    # when set to true, multiple matches result get accumulated in
    # an array.
    #
    attr_accessor :accumulate

    # The constructor for DecisionTable, you can pass a String, an Array
    # (of arrays), a File object. The CSV parser coming with Ruby will take
    # care of it and a DecisionTable instance will be built.
    #
    # Options are :through, :ignore_case, :accumulate (which
    # forces :through to true when set) and :ruby_eval. See
    # Rufus::Decision::Table for more details.
    #
    # Options passed to this method do override the options defined
    # in the CSV itself.
    #
    # == options
    #
    # * :through : when set, all the rows of the decision table are considered
    # * :ignore_case : case is ignored (not ignored by default)
    # * :accumulate : gather instead of overriding (implies :through)
    # * :ruby_eval : ruby code evaluation is OK
    #
    def initialize (csv, options={})

      @rows = Rufus::Decision.csv_to_a(csv)

      extract_options

      parse_header_row

      @first_match = false if options[:through] == true
      @first_match = true if @first_match.nil?

      set_opt(options, :ignore_case, :ignorecase)
      set_opt(options, :accumulate)
      set_opt(options, :ruby_eval)

      @first_match = false if @accumulate
    end

    # Like transform, but the original hash doesn't get touched,
    # a copy of it gets transformed and finally returned.
    #
    def transform (hash)

      transform!(hash.dup)
    end

    # Passes the hash through the decision table and returns it,
    # transformed.
    #
    def transform! (hash)

      hash = Rufus::Decision::EvalHashFilter.new(hash) if @ruby_eval

      @rows.each do |row|
        next unless matches?(row, hash)
        apply(row, hash)
        break if @first_match
      end

      hash.is_a?(Rufus::Decision::HashFilter) ? hash.parent_hash : hash
    end

    alias :run :transform

    # Outputs back this table as a CSV String
    #
    def to_csv

      @rows.inject([ @header.to_csv ]) { |a, row|
        a << row.join(',')
      }.join("\n")
    end

    protected

    def set_opt (options, *optnames)

      optnames.each do |oname|

        v = options[oname]
        next unless v != nil
        instance_variable_set("@#{optnames.first.to_s}", v)
        return
      end
    end


    # Returns true if the hash matches the in: values for this row
    #
    def matches? (row, hash)

      @header.ins.each do |x, in_header|

        in_header = "${#{in_header}}"

        value = Rufus::dsub(in_header, hash)

        cell = row[x]

        next if cell == nil || cell == ''

        cell = Rufus::dsub(cell, hash)

        b = if m = NUMERIC_COMPARISON.match(cell)

          numeric_compare(m, value, cell)
        else

          range = to_ruby_range(cell)
          range ? range.include?(value) : string_compare(value, cell)
        end

        return false unless b
      end

      true
    end

    def string_compare (value, cell)

      modifiers = 0
      modifiers += Regexp::IGNORECASE if @ignore_case

      #rcell = Regexp.new(cell, modifiers)
      rcell = Regexp.new("^#{cell}$", modifiers)

      rcell.match(value)
    end

    def numeric_compare (match, value, cell)

      comparator = match[1]
      cell = match[2]

      nvalue = Float(value) rescue value
      ncell = Float(cell) rescue cell

      value, cell = if nvalue.is_a?(String) or ncell.is_a?(String)
        [ "\"#{value}\"", "\"#{cell}\"" ]
      else
        [ nvalue, ncell ]
      end

      s = "#{value} #{comparator} #{cell}"

      Rufus::Decision::check_and_eval(s) rescue false
    end

    def apply (row, hash)

      @header.outs.each do |x, out_header|

        value = row[x]

        next if value == nil || value == ''

        value = Rufus::dsub(value, hash)

        hash[out_header] = if @accumulate
          #
          # accumulate

          v = hash[out_header]

          if v and v.is_a?(Array)
            v + Array(value)
          elsif v
            [ v, value ]
          else
            value
          end
        else
          #
          # override

          value
        end
      end
    end

    def extract_options

      row = @rows.first

      return unless row
        # end of table somehow

      return if row.find { |cell| cell && cell.match(IN_OR_OUT) }
        # just hit the header row

      row.each do |cell|

        cell = cell.downcase

        if cell == 'ignorecase' or cell == 'ignore_case'
          @ignore_case = true
        elsif cell == 'through'
          @first_match = false
        elsif cell == 'accumulate'
          @first_match = false
          @accumulate = true
        end
      end

      @rows.shift

      extract_options
    end

    # Returns true if the first row of the table contains just an "in:" or
    # an "out:"
    #
    def is_vertical_table? (first_row)

      bin = false
      bout = false

      first_row.each do |cell|
        bin ||= cell.match(IN)
        bout ||= cell.match(OUT)
        return false if bin and bout
      end

      true
    end

    def parse_header_row

      row = @rows.first

      return unless row

      if is_vertical_table?(row)
        @rows = @rows.transpose
        row = @rows.first
      end

      @rows.shift

      row.each_with_index do |cell, x|
        next unless cell.match(IN_OR_OUT)
        (@header ||= Header.new).add(cell, x)
      end
    end

    # A regexp for checking if a string is a numeric Ruby range
    #
    RUBY_NUMERIC_RANGE_REGEXP = Regexp.compile(
      "^\\d+(\\.\\d+)?\\.{2,3}\\d+(\\.\\d+)?$")

    # A regexp for checking if a string is an alpha Ruby range
    #
    RUBY_ALPHA_RANGE_REGEXP = Regexp.compile(
      "^([A-Za-z])(\\.{2,3})([A-Za-z])$")

    # If the string contains a Ruby range definition
    # (ie something like "93.0..94.5" or "56..72"), it will return
    # the Range instance.
    # Will return nil else.
    #
    # The Ruby range returned (if any) will accept String or Numeric,
    # ie (4..6).include?("5") will yield true.
    #
    def to_ruby_range (s)

      range = if RUBY_NUMERIC_RANGE_REGEXP.match(s)

        eval(s)

      else

        m = RUBY_ALPHA_RANGE_REGEXP.match(s)

        m ? eval("'#{m[1]}'#{m[2]}'#{m[3]}'") : nil
      end

      class << range

        alias :old_include? :include?

        def include? (elt)

          elt = first.is_a?(Numeric) ? (Float(elt) rescue '') : elt
          old_include?(elt)
        end

      end if range

      range
    end

    class Header

      attr_accessor :ins, :outs

      def initialize

        @ins = {}
        @outs = {}
      end

      def add (cell, x)

        if cell.match(IN)

          @ins[x] = cell[3..-1]

        elsif cell.match(OUT)

          @outs[x] = cell[4..-1]

        end
        # else don't add
      end

      def to_csv

        (@ins.keys.sort.collect { |k| "in:#{@ins[k]}" } +
         @outs.keys.sort.collect { |k| "out:#{@outs[k]}" }).join(',')
      end
    end
  end

  # Given a CSV string or the URI / path to a CSV file, turns the CSV
  # into an array of array.
  #
  def self.csv_to_a (csv)

    return csv if csv.is_a?(Array)

    csv = csv.to_s if csv.is_a?(URI)
    csv = open(csv) if is_uri?(csv)

    csv_lib = defined?(CSV::Reader) ? CSV::Reader : CSV
      # no CSV::Reader for Ruby 1.9.1

    csv_lib.parse(csv).inject([]) { |rows, row|
      row = row.collect { |cell| cell ? cell.strip : '' }
      rows << row if row.find { |cell| (cell != '') }
      rows
    }
  end

  # Returns true if the string is a URI false if it's something else
  # (CSV data ?)
  #
  def self.is_uri? (string)

    return false if string.index("\n") # quick one

    begin
      URI::parse(string); return true
    rescue
    end

    false
  end

  # Turns an array of array (rows / columns) into an array of hashes.
  # The first row is considered the "row of keys".
  #
  #   [
  #     [ 'age', 'name' ],
  #     [ 33, 'Jeff' ],
  #     [ 35, 'John' ]
  #   ]
  #
  # =>
  #
  #  [
  #    { 'age' => 33, 'name' => 'Jeff' },
  #    { 'age' => 35, 'name' => 'John' }
  #  ]
  #
  # You can also pass the CSV as a string or the URI/path to the actual CSV
  # file.
  #
  def self.transpose (a)

    a = csv_to_a(a) if a.is_a?(String)

    return a if a.empty?

    first = a.first

    if first.is_a?(Hash)

      keys = first.keys.sort
      [ keys ] + a.collect { |row|
        keys.collect { |k| row[k] }
      }
    else

      keys = first
      a[1..-1].collect { |row|
        (0..keys.size - 1).inject({}) { |h, i| h[keys[i]] = row[i]; h }
      }
    end
  end

end
end

module Rufus

  #
  # An 'alias' for the class Rufus::Decision::Table
  #
  # (for backward compatibility)
  #
  class DecisionTable < Rufus::Decision::Table
  end
end

