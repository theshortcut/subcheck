$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))

require 'minitest/spec'
require 'fakeweb'
require 'subcheck'

MiniTest::Unit.autorun

FakeWeb.allow_net_connect = false

FakeWeb.register_uri :any,
                     'https://sub.amphi.com/logOnInitAction.do',
                     :response => File.join(File.dirname(__FILE__), 'fixtures', 'login_page.html')
FakeWeb.register_uri :any,
                     'https://sub.amphi.com/logOnAction.do',
                     :response => File.join(File.dirname(__FILE__), 'fixtures', 'login_post_page.html')
FakeWeb.register_uri :any,
                     'https://sub.amphi.com/homeAction.do',
                     :response => File.join(File.dirname(__FILE__), 'fixtures', 'my_page.html')
FakeWeb.register_uri :any,
                     'https://sub.amphi.com/substituteAvailableJobInitAction.do',
                     :response => File.join(File.dirname(__FILE__), 'fixtures', 'search_page.html')
FakeWeb.register_uri :any,
                     'https://sub.amphi.com/substituteAvailableJobAction.do',
                     :response => File.join(File.dirname(__FILE__), 'fixtures', 'results_page.html')

describe Subcheck do
  before do
    @subcheck = Subcheck.new('1234', '123456')
  end

  describe "when creating a new Subcheck" do
    it "should accept a user_id" do
      @subcheck.user_id.must_equal '1234'
    end

    it "should accept a user_pin" do
      @subcheck.user_pin.must_equal '123456'
    end
  end

  describe "when checking results" do
    it "should return postings when available" do
      FakeWeb.register_uri :any,
                           'https://sub.amphi.com/substituteAvailableJobAction.do',
                           :response => File.join(File.dirname(__FILE__), 'fixtures', 'results_page.html')
      @subcheck.get_postings
      @subcheck.errors.length.must_equal 0
      @subcheck.postings.length.must_equal 1
      @subcheck.postings[0].school.must_equal 'Prince Elementary School'
      @subcheck.postings[0].classification.must_equal 'Elementary Reading'
    end

    it "should not return postings when unavailable" do
      FakeWeb.register_uri :any,
                           'https://sub.amphi.com/substituteAvailableJobAction.do',
                           :response => File.join(File.dirname(__FILE__), 'fixtures', 'noresults_page.html')
      @subcheck.get_postings
      @subcheck.errors.length.must_equal 1
      @subcheck.postings.length.must_equal 0
      @subcheck.errors[0].must_equal 'NO RECORDS FOUND'
    end

    it "should check against cached postings" do
      FakeWeb.register_uri :any,
                           'https://sub.amphi.com/substituteAvailableJobAction.do',
                           :response => File.join(File.dirname(__FILE__), 'fixtures', 'results_page.html')
      @subcheck.get_postings
      @subcheck.postings[0].new.must_equal true
      @subcheck.get_postings
      @subcheck.postings.length.must_equal 1
      @subcheck.postings[0].new.must_equal false
    end
  end
end
