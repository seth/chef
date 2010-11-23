require File.expand_path(File.join("#{File.dirname(__FILE__)}", '..', '..', 'spec_helper'))

describe Chef::Solr::Query do
  before(:each) do
    @query = Chef::Solr::Query.new
  end

  describe "transform queries correctly" do
    testcase_file = "#{CHEF_SOLR_SPEC_DATA}/search_queries_to_transform.txt"
    lines = File.readlines(testcase_file).map { |line| line.strip }
    lines = lines.select { |line| !line.empty? }
    testcases = Hash[*(lines)]
    testcases.each do |input, expected|
      it "from> #{input}\n    to> #{expected}\n" do
        @query.transform_search_query(input).should == expected
      end
    end
  end

end

