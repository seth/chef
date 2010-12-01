require File.expand_path(File.join("#{File.dirname(__FILE__)}", '..', '..', 'spec_helper'))
require 'chef/solr/query_transform'

describe "Chef::Solr::QueryTransform" do
  before(:each) do
    @parser = Chef::Solr::QueryTransform
    @parseError = Chef::Exceptions::QueryParseError
  end

  describe "single term queries" do
    basic_terms = %w(a ab 123 a1 2b foo_bar baz-baz)
    basic_terms << "  leading"
    basic_terms << "trailing "
    basic_terms += %w(XAND ANDX XOR ORX XNOT NOTX)
    basic_terms.each do |term|
      expect = "(T:#{term.strip})"
      it "'#{term}' => #{expect}" do
        @parser.parse(term).should == expect
      end
    end
    describe "invalid" do
      %w(AND OR NOT :).each do |t|
        it "'#{t}' => ParseError" do
          lambda { @parser.parse(t) }.should raise_error(@parseError)
        end
      end
    end

    describe "escaped special characters in terms" do
      special_chars = ["!", "(", ")", "{", "}", "[", "]", "^", "\"",
                       "~", "*", "?", ":", "\\"]
      example_fmts = ['foo%sbar', '%sb', 'a%s', 'a%sb']
      special_chars.each do |char|
        example_fmts.each do |fmt|
          input = fmt % ("\\" + char)
          expect = "(T:#{input})"
          it "'#{input}' => #{expect}" do
            @parser.parse(input).should == expect
          end
        end
      end
    end
  end

  describe "multiple terms" do
    it "should allow multiple terms" do
      @parser.parse("a b cdefg").should == "(T:a T:b T:cdefg)"
    end
  end

  describe "boolean queries" do
    describe "two term basic and/or" do
      binary_operators = [['AND', 'AND'], ['&&', 'AND'], ['OR', 'OR'], ['||', 'OR']]
      binary_operators.each do |op, op_name|
        expect = "((OP:#{op_name} T:t1 (T:t2)))"
        it "should parse 't1 #{op} t2' => #{expect}" do
          @parser.parse("t1 #{op} t2").should == expect
        end
      end
    end

    it "should allow a string of terms with ands and ors" do
      expect = "((OP:AND T:t1 ((OP:OR T:t2 ((OP:AND T:t3 (T:t4)))))))"
      @parser.parse("t1 AND t2 OR t3 AND t4").should == expect
    end
  end

  describe "grouping with parens" do
    it "should create a single group for (aterm)" do
      @parser.parse("(aterm)").should == "((T:aterm))"
    end

    describe "and booleans" do

      %w(AND &&).each do |op|
        expect = "(((OP:AND T:a (T:b))))"
        input = "(a #{op} b)"
        it "parses #{input} => #{expect}" do
          @parser.parse(input).should == expect
        end
      end

      %w(OR ||).each do |op|
        expect = "(((OP:OR T:a (T:b))))"
        input = "(a #{op} b)"
        it "parses #{input} => #{expect}" do
          @parser.parse(input).should == expect
        end
      end

      it "should handle a LHS group" do
        expect = "((OP:OR ((OP:AND T:a (T:b))) (T:c)))"
        @parser.parse("(a && b) OR c").should == expect
        @parser.parse("(a && b) || c").should == expect
      end

      it "should handle a RHS group" do
        expect = "((OP:OR T:c (((OP:AND T:a (T:b))))))"
        @parser.parse("c OR (a && b)").should == expect
        @parser.parse("c OR (a AND b)").should == expect
      end

      it "should handle both sides as groups" do
        expect = "((OP:OR ((OP:AND T:c (T:d))) (((OP:AND T:a (T:b))))))"
        @parser.parse("(c AND d) OR (a && b)").should == expect
      end
    end
  end

  describe "NOT queries" do
    # input, output
    [
     ["a NOT b", "(T:a (OP:NOT T:b))"],
     ["a ! b", "(T:a (OP:NOT T:b))"],
     ["a !b", "(T:a (OP:NOT T:b))"],
     ["a NOT (b || c)", "(T:a (OP:NOT ((OP:OR T:b (T:c)))))"],
     ["a ! (b || c)", "(T:a (OP:NOT ((OP:OR T:b (T:c)))))"],
     ["a !(b || c)", "(T:a (OP:NOT ((OP:OR T:b (T:c)))))"]
    ].each do |input, expected|
      it "should parse '#{input}' => #{expected.inspect}" do
        @parser.parse(input).should == expected
      end
    end

    ["NOT", "a NOT", "(NOT)"].each do |d|
      it "should raise a ParseError on '#{d}'" do
        lambda { @parser.parse(d) }.should raise_error(@parseError)
      end
    end
  end

  describe 'required and prohibited prefixes (+/-)' do
    ["+", "-"].each do |kind|
      [
       ["#{kind}foo", "((OP:#{kind} T:foo))"],
       ["bar #{kind}foo", "(T:bar (OP:#{kind} T:foo))"],
       ["(#{kind}oneA twoA) b", "(((OP:#{kind} T:oneA) T:twoA) T:b)"]
      ].each do |input, expect|
        it "should parse '#{input} => #{expect.inspect}" do
          @parser.parse(input).should == expect
        end
      end
    end

    it 'ignores + embedded in a term' do
      @parser.parse("one+two").should == "(T:one+two)"
    end
    
    it 'ignores - embedded in a term' do
      @parser.parse("one-two").should == "(T:one-two)"
    end
  end

  describe "phrases (strings)" do
    phrases = [['"single"', '(STR:"single")'],
               ['"two term"', '(STR:"two term")'],
               ['"has \"escaped\" quote\"s"', '(STR:"has \"escaped\" quote\"s")']
              ]
    phrases.each do |phrase, expect|
      it "'#{phrase}' => #{expect}" do
        @parser.parse(phrase).should == expect
      end
    end

    describe "invalid" do
      bad = ['""', '":not:a:term"', '"a :bad:']
      bad.each do |t|
        it "'#{t}' => ParseError" do
          lambda { @parser.parse(t) }.should raise_error(@parseError)
        end
      end
    end

    it "allows phrases to be required with '+'" do
      @parser.parse('+"a b c"').should == '((OP:+ STR:"a b c"))'
    end

    it "allows phrases to be prohibited with '-'" do
      @parser.parse('-"a b c"').should == '((OP:- STR:"a b c"))'
    end

    it "allows phrases to be excluded with NOT" do
      @parser.parse('a NOT "b c"').should == '(T:a (OP:NOT STR:"b c"))'
    end

  end

  describe "fields" do
    it "parses a term annotated with a field" do
      @parser.parse("afield:aterm").should == "((F:afield T:aterm))"
    end

    it "allows underscore in a field name" do
      @parser.parse("a_field:aterm").should == "((F:a_field T:aterm))"
    end

    it "parses a group annotated with a field" do
      @parser.parse("afield:(a b c)").should == "((F:afield (T:a T:b T:c)))"
    end

    it "parses a phrase annotated with a field" do
      @parser.parse('afield:"a b c"').should == '((F:afield STR:"a b c"))'
    end

    describe "and binary operators" do
      examples = [
                  ['term1 AND afield:term2', "((OP:AND T:term1 ((F:afield T:term2))))"],
                  ['afield:term1 AND term2', "((OP:AND (F:afield T:term1) (T:term2)))"],
                  ['afield:term1 AND bfield:term2',
                   "((OP:AND (F:afield T:term1) ((F:bfield T:term2))))"]]
      examples.each do |input, want|
        it "'#{input}' => '#{want}'" do
          @parser.parse(input).should == want
        end
      end
    end
  end

  describe "range queries" do
    before(:each) do
      @kinds = {
        "inclusive" => {:left => "[", :right => "]"},
        "exclusive" => {:left => "{", :right => "}"}
      }
    end
    
    def make_expect(kind, field, s, e)
      expect_fmt = "((FR:%s %s%s%s %s%s%s))"
      left = @kinds[kind][:left]
      right = @kinds[kind][:right]
      expect_fmt % [field, left, s, right, left, e, right]
    end

    def make_query(kind, field, s, e)
      query_fmt = "%s:%s%s TO %s%s"
      left = @kinds[kind][:left]
      right = @kinds[kind][:right]
      query_fmt % [field, left, s, e, right]
    end

    ["inclusive", "exclusive"].each do |kind|
      tests = [["afield", "start", "end"],
               ["afield", "start", "*"],
               ["afield", "*", "end"],
               ["afield", "*", "*"]
              ]
      tests.each do |field, s, e|
        it "parses an #{kind} range query #{s} TO #{e}" do
          expect = make_expect(kind, field, s, e)
          query = make_query(kind, field, s, e)
          @parser.parse(query).should == expect
        end
      end
    end

    describe "and binary operators" do
      [["afield:[start TO end] AND term",
        "((OP:AND (FR:afield [start] [end]) (T:term)))"],
       ["term OR afield:[start TO end]",
        "((OP:OR T:term ((FR:afield [start] [end]))))"],
       ["f1:[s1 TO e1] OR f2:[s2 TO e2]",
        "((OP:OR (FR:f1 [s1] [e1]) ((FR:f2 [s2] [e2]))))"]
      ].each do |q, want|
        it "parses '#{q}'" do
          @parser.parse(q).should == want
        end
      end
    end
  end

  describe "proximity query" do
    [
     ['"one two"~10', '((OP:~ STR:"one two" 10))'],
     ['word~', '((OP:~ T:word))'],
     ['word~0.5', '((OP:~ T:word 0.5))']
    ].each do |input, expect|
      it "'#{input}' => #{expect}" do
        @parser.parse(input).should == expect
      end
    end
  end

  describe "term boosting" do
    [
     ['"one two"^10', '((OP:^ STR:"one two" 10))'],
     ['word^0.5', '((OP:^ T:word 0.5))']
    ].each do |input, expect|
      it "'#{input}' => #{expect}" do
        @parser.parse(input).should == expect
      end
    end

    it "should fail to parse if no boosting argument is given" do
      lambda { @parser.parse("foo^")}.should raise_error(@parseError)
    end
  end

  describe "examples" do
    examples = [['tags:apples*.for.eating.com', "((F:tags T:apples*.for.eating.com))"],
                ['ohai_time:[1234.567 TO *]', "((FR:ohai_time [1234.567] [*]))"],
                ['ohai_time:[* TO 1234.567]', "((FR:ohai_time [*] [1234.567]))"],
                ['ohai_time:[* TO *]', "((FR:ohai_time [*] [*]))"]]
                # ['aterm AND afield:aterm', "((OP:AND T:aterm ((F:afield T:aterm))))"],
                # ['role:prod AND aterm', "blah"],
                # ['role:prod AND xy:true', "blah"]]
    examples.each do |input, want|
      it "'#{input}' => '#{want}'" do
        @parser.parse(input).should == want
      end
    end
  end
end
