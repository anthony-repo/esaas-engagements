require 'csv'

PROD_USERS = [
		%w(mutex@berkeley.edu Alex bdzr coach),
		%w(srujayk@gmail.com Srujay srujayk coach),
		%w(pgenerao516@gmail.com Peter autholius coach),
		%w(jwp@berkeley.edu Jeff jw-park coach),
    %w(aleasabrina@gmail.com Sabrina sabrina1 coach),
    %w(kingarthuralagao@gmail.com King kialagao coach),
    %w(anthonyshao@gmail.com Anthony anthony-repo coach)
]

if Rails.env == 'production'
	PROD_USERS.each do |user|
      User.find_or_create_by!(email: user[0]) do |u|
        u.name = user[1]
        u.github_uid = user[2]
        u.user_type = user[3]
      end
	end
end

def rand_org_user
	if Rails.env.to_sym == :production
		rand_user = PROD_USERS.sample
		User.find_by(email: rand_user[0])
	end
end

# create users and orgs
CSV.foreach("#{Rails.root}/db/user_orgs.csv", headers: true, header_converters: :symbol) do |row|
	user = User.find_or_create_by!(email: row[:user_email]) do |u|
		u.name = row[:user_name]
    u.github_uid = row[:github_uid]
    u.user_type = row[:user_type]
	end
	Org.find_or_create_by!(name: row[:org_name]) do |o|
		o.contact = if Rails.env.to_sym == :production
									rand_org_user
                else
                  user
                end
		o.description = row[:org_description]
		o.url = row[:org_url] || (user.email !~ /gmail|berkeley.edu/ && user.email =~ /@(.*)$/ ? "http://#{$1}" : nil)
	end
end

puts "#{Org.all.size} orgs, #{User.all.size} users"

# default coach/coaching org
coach = User.find_or_create_by(email: 'fox@cs.berekley.edu') do |fox|
	fox.name = "Armando Fox"
end

cs169 = Org.find_or_create_by(name: 'UCB CS169 Fox') do |ucbcs169|
	ucbcs169.description = 'CS 169 at UC Berkeley'
	ucbcs169.url = "http://cs169.saas-class.org"
	ucbcs169.contact = coach
end

# create orgs and engagements
CSV.foreach("#{Rails.root}/db/apps.csv",
	headers: true, header_converters: :symbol, encoding: 'iso-8859-1:utf-8') do |row|
	if (org = Org.find_by_name(row[:org_name]))
		app = App.find_or_create_by(name: row[:project]) do |a|
			a.org = org
			a.status = App.statuses.keys.sample # Status variety for dev env
			a.description = row[:description] || 'NA'
			a.deployment_url = row[:deployment]
			a.repository_url = row[:repo] || 'http://'
			a.pivotal_tracker_url = row[:tracker] || 'http://'
		end
    User.find_or_create_by(email: row[:contact_email]) do |c|
			c.name = row[:customer] || 'Unknown'
			c.email = row[:contact_email] || "#{row[:project]}_unknown@email.com"
		end
		app.engagements.create do |e|
			e.team_number = "#{row[:semester]}-#{row[:team]}"
			e.start_date = Time.parse(row[:start_date])
			e.coaching_org = cs169
			e.coach = coach
			e.screencast_url = row[:screencast]
			e.screenshot_url = row[:link_to_poster_preview_slides_your_particular_slide_in_the_classwide_slide_deck]
			e.poster_url = row[:poster_pdf]
			e.presentation_url = row[:link_to_presentation_slides]
			e.prototype_deployment_url = row[:deployment]
			e.student_names = row[:students] || 'Unknown'
		end
	else
		puts "No org #{row[:org_name]}"
	end
end
puts "#{App.all.size} apps, #{Engagement.all.size} engagements"

# login mockup
if %w(development test).include? Rails.env
	User.find_or_create_by YAML.load(File.read "#{Rails.root}/db/github_mock_login.yml")[Rails.env]
end