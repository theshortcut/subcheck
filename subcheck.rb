# coding: utf-8

require 'mechanize'
require 'mail'

class Subcheck
  attr_reader :user_id, :user_pin, :errors, :postings

  def initialize(user_id, user_pin)
    @user_id = user_id
    @user_pin = user_pin
    @errors = []
    @postings = []
  end

  def get_postings
    @errors   = []
    @postings = []
    a = Mechanize.new
    a.get('https://sub.amphi.com/logOnInitAction.do') do |login_page|

      my_page = login_page.form_with(:name => 'logOnForm') do |form|
        form.userID  = user_id
        form.userPin = user_pin
      end.submit

      search_page = a.get('https://sub.amphi.com/substituteAvailableJobInitAction.do')

      results_page = search_page.form_with(:name => 'reviewAssignForm') do |form|
        today = Time.now
        later = today + (60 * 60 * 24 * 365)
        form.startDate = today.strftime('%m/%d/%Y')
        form.endDate   = later.strftime('%m/%d/%Y')
      end.submit

      errors = results_page.parser.xpath("//font[@class='error']")
      errors.each do |error|
        @errors.push error.text if error.text.length > 0
      end

      cache_file = File.open(File.join(File.dirname(__FILE__), 'tmp', 'cache.txt'))
      cache      = cache_file.readlines
      cache.each do |line|
        line.gsub('\n', '')
      end
      postings = results_page.parser.xpath("//td/a/font[@class='heading'][text()='Details']")
      postings.each do |posting|
        post_info = posting.parent.parent.parent
        post = Posting.new
        post.startdate      = post_info.search("td[2]/font").first.text.gsub(' ',' ').strip
        post.enddate        = post_info.next_sibling.search("td[2]/font").first.text.gsub(' ',' ').strip
        post.school         = post_info.search("td[3]/font").first.text.gsub(' ',' ').strip
        post.classification = post_info.next_sibling.search("td[3]/font").first.text.gsub(' ',' ').strip
        post.new = !cache.include?(post.to_s)
        @postings.push post
      end

      cache_file = File.new(File.join(File.dirname(__FILE__), 'tmp', 'cache.txt'), 'w+')
      @postings.each do |posting|
        cache_file.puts posting.to_s
      end
      cache_file.close
    end
  end

  def mail_results(email_address)
    Mail.defaults do
      delivery_method :smtp, { :address => 'smtp.gmail.com',
                               :port => 587,
                               :user_name => ENV['gmail_username'],
                               :password => ENV['gmail_password'],
                               :authentication => 'plain',
                               :enable_starttls_auto => true }
    end

    email_body = "<p>New posting(s) found:</p>"
    @postings.each do |posting|
      email_body << posting.to_html if posting.new
    end

    mail = Mail.new do
      from    ENV['gmail_username']
      to      email_address
      subject 'Substitute Job Posting'
      text_part do
        body email_body
      end
      html_part do
        content_type 'text/html; charset=UTF-8'
        body email_body
      end
    end

    mail.deliver
  end
end

class Posting
  attr_accessor :startdate, :enddate, :school, :classification, :new

  def to_s
    "Start: #{startdate}, End: #{enddate}, School: #{school}, Classification: #{classification}"
  end

  def to_html
    "<p>School: #{school}<br/>Class: #{classification}<br/>Start: #{startdate}<br/>End: #{enddate}</p>"
  end
end
