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

      postings = results_page.parser.xpath("//td/a/font[@class='heading'][text()='Details']")
      postings.each do |posting|
        post = posting.parent.parent.parent
        @postings.push({ :start  => post.search("td[2]/font").first.text.gsub(' ',' ').strip,
                         :school => post.search("td[3]/font").first.text.gsub(' ',' ').strip,
                         :end    => post.next_sibling.search("td[2]/font").first.text.gsub(' ',' ').strip,
                         :class  => post.next_sibling.search("td[3]/font").first.text.gsub(' ',' ').strip })
      end
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

    email_body = "<p>#{@postings.count} new posting(s) found.</p>"
    @postings.each do |posting|
      email_body << "<p>School: #{posting[:school]}<br/>Classification: #{posting[:class]}<br/>Start Date: #{posting[:start]}<br/>End Date: #{posting[:end]}</p>"
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
