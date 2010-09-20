require 'test/unit'
require 'fakeweb'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))
require 'subcheck'

FakeWeb.allow_net_connect = false

FakeWeb.register_uri(:any, 'https://sub.amphi.com/logOnInitAction.do', :response => File.join(File.dirname(__FILE__), 'fixtures', 'login_page.html'))
FakeWeb.register_uri(:any, 'https://sub.amphi.com/logOnAction.do', :response => File.join(File.dirname(__FILE__), 'fixtures', 'login_post_page.html'))
FakeWeb.register_uri(:any, 'https://sub.amphi.com/homeAction.do', :response => File.join(File.dirname(__FILE__), 'fixtures', 'my_page.html'))
FakeWeb.register_uri(:any, 'https://sub.amphi.com/substituteAvailableJobInitAction.do', :response => File.join(File.dirname(__FILE__), 'fixtures', 'search_page.html'))
FakeWeb.register_uri(:any, 'https://sub.amphi.com/substituteAvailableJobAction.do', :response => File.join(File.dirname(__FILE__), 'fixtures', 'results_page.html'))

class TestSubcheck < Test::Unit::TestCase
  def test_user_id
    assert_equal(Subcheck.new('6225', '123456').user_id, '6225')
  end

  def test_user_pin
    assert_equal(Subcheck.new('6225', '123456').user_pin, '123456')
  end

  def test_results
    FakeWeb.register_uri(:any, 'https://sub.amphi.com/substituteAvailableJobAction.do', :response => File.join(File.dirname(__FILE__), 'fixtures', 'results_page.html'))
    subcheck = Subcheck.new('1234', '123456')
    subcheck.get_postings
    assert_equal(subcheck.errors.length, 0)
    assert_equal(subcheck.postings.length, 1)
    assert_equal(subcheck.postings[0][:school], 'Prince Elementary School')
    assert_equal(subcheck.postings[0][:class], 'Elementary Reading')
  end

  def test_no_results
    FakeWeb.register_uri(:any, 'https://sub.amphi.com/substituteAvailableJobAction.do', :response => File.join(File.dirname(__FILE__), 'fixtures', 'noresults_page.html'))
    subcheck = Subcheck.new('1234', '123456')
    subcheck.get_postings
    assert_equal(subcheck.errors.length, 1)
    assert_equal(subcheck.postings.length, 0)
    assert_equal(subcheck.errors[0], 'NO RECORDS FOUND')
  end
end
