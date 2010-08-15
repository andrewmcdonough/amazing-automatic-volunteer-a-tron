require 'volunteer_a_tron/reader'
require 'volunteer_a_tron/cachet'
require 'volunteer_a_tron/config'
require 'volunteer_a_tron/interesting_thing'
require 'nokogiri'

class VolunteerATron
  class Volunteer
    include VolunteerATron::Reader
    attr_accessor :github_user_name
    attr_accessor :repos
    
    def initialize(github_user_name)
      @github_user_name = github_user_name
      @repos = []
      if VolunteerATron.use_caching?
        self.class.class_eval do
          include VolunteerATron::Cachet
        end
      end
    end
    
    def to_s
      @github_user_name
    end
    
    def repo_url(for_language)
      u = "http://github.com/api/v2/xml/repos/show/#{@github_user_name}"
      # NOTE - this doesn't do anything
      # u += "?language=#{for_language}" unless for_language.nil?
      u
    end
    
    def fetch_all_repos(for_language = 'ruby')
      repos_page = Nokogiri::XML(read_page(repo_url(for_language)))

      get_repos_from_search(repos_page, for_language)
    end
    
    def get_repos_from_search(repos_page, for_language = 'ruby')
      repo_elems = repos_page.xpath('//repository')
      repo_elems.each do |repo|
        repo_language = repo.xpath('./language/text()')
        if (repo_language.nil?) || (repo_language.empty?) || (repo_language.text.downcase == for_language.downcase)
          @repos << VolunteerATron::InterestingThing.new(repo.xpath('./name/text()').text, repo.xpath('./description/text()').text, repo.xpath('./homepage/text()').text)
        end
      end
    end
  end
end