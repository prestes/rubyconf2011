namespace :utils do
  desc "sync avatars from the call for papers server"
  task :sync_avatars do
    `rsync -avz -e ssh root@akitaonrails.com:/var/webapps/rubyconf2011/public/system/ ./content/images/`
  end

  desc "sync the sqlite3 call for papers database"
  task :sync_papers do
    `scp root@akitaonrails.com:/var/webapps/rubyconf2011/db/production.sqlite3 ./tmp/`
  end

  desc "generate speakers profile and talk files"
  task :generate_talks do
    require 'sqlite3'
    require 'fileutils'
    require 'to_slug'
    require 'active_support/all'

    exit unless File.exists?("./tmp/production.sqlite3")
    FileUtils.mkdir_p "./lib/speakers"
    FileUtils.mkdir_p "./content/talks"

    db = SQLite3::Database.new "./tmp/production.sqlite3"
    db.results_as_hash = true
    row_index_rand = (0..27)
    db.execute "select * from talks where selected = 't'" do |row|
      row.delete_if { |key,value| row_index_rand.include?(key) }
      slug = "#{row["full_name"].to_slug}-#{row["id"]}"

      avatar_url = unless row["avatar_file_name"].blank?
        "/images/avatars/#{row["id"]}/__format__/#{row["avatar_file_name"]}"
      else
        "/images/speakers.jpg"
      end
      %w{twitter blog_url bio}.each { |key| row[key] = '' unless row[key] }
      speaker = {
        :id => row["id"],
        :slug => slug,
        :full_name => row["full_name"],
        :email => row["email"],
        :twitter => row["twitter"].gsub(/\@/,''),
        :blog_url => row["blog_url"].gsub(/http\:\/\//,''),
        :company => row["company"],
        :bio_br => row["bio"].gsub(/\r/, ""),
        :bio_en => row["bio"].gsub(/\r/, ""),
        :country => row["country"],
        :avatar_thumb_url => avatar_url.gsub(/__format__/,'thumb'),
        :avatar_medium_url => avatar_url.gsub(/__format__/,'medium'),
        :avatar_url => avatar_url.gsub(/__format__/, 'original'),
      }

      avatar_url = unless row["avatar_cospeaker_file_name"].blank?
        "/images/avatar_cospeakers/#{row["id"]}/__format__/#{row["avatar_cospeaker_file_name"]}"
      else
        "/images/speakers.jpg"
      end

      co_speaker_slug = ""
      co_speaker = unless row["cospeaker_name"].blank?
        %w{cospeaker_twitter cospeaker_blog_url cospeaker_bio}.each { |key| row[key] = '' unless row[key] }
        co_speaker_slug = "#{row["cospeaker_name"].to_slug}-#{row["id"]}"
        {
          :id => row["id"],
          :main_speaker_name => row["full_name"],
          :main_speaker_slug => slug,
          :slug => co_speaker_slug,
          :full_name => row["cospeaker_name"],
          :email => row["cospeaker_email"],
          :twitter => row["cospeaker_twitter"].gsub(/\@/,''),
          :blog_url => row["cospeaker_blog_url"].gsub(/http\:\/\//,''),
          :company => row["company"],
          :bio_br => row["cospeaker_bio"].gsub(/\r/, ""),
          :bio_en => row["cospeaker_bio"].gsub(/\r/, ""),
          :country => row["country"],
          :avatar_thumb_url => avatar_url.gsub(/__format__/,'thumb'),
          :avatar_medium_url => avatar_url.gsub(/__format__/,'medium'),
          :avatar_url => avatar_url.gsub(/__format__/, 'original'),
        }
      end

      row["description"] = '' unless row["description"]
      talk = {
        :id => row["id"],
        :main_speaker_slug => slug,
        :main_speaker_name => row["full_name"],
        :co_speaker_slug => co_speaker_slug,
        :co_speaker_name => row["cospeaker_name"],
        :title_br => row["title"],
        :title_en => row["title"],
        :description_br => row["description"].gsub(/\r/, ""),
        :description_en => row["description"].gsub(/\r/, ""),
        :country => row["country"],
        :confirmed => row["confirmed"] == 't',
        :selected => row["selected"] == 't'
      }

      unless File.exists?("./lib/speakers/#{slug}.yml")
        File.open("./lib/speakers/#{slug}.yml", "w+") do |file|
          file.write(speaker.to_yaml)
        end
      end
      unless File.exists?("./lib/speakers/#{co_speaker_slug}.yml")
        File.open("./lib/speakers/#{co_speaker_slug}.yml", "w+") do |file|
          file.write(co_speaker.to_yaml)
        end if co_speaker
      end
      unless File.exists?("./content/talks/#{slug}.html")
        File.open("./content/talks/#{slug}.html", "w+") do |file|
          file.write(talk.to_yaml)
          file.write("---\n")
        end
      end
    end
  end
end
