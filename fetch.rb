#!/usr/bin/ruby

require "open-uri"
require "work_queue"
require "./tmpdir.rb"
require "sqlite3"

trap("INT") do
	$stop = true
end

AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0"

db = SQLite3::Database.open "videos.db"

sql = "select id,handle from subscriptions where active = 'true';"

rs = db.execute(sql)

wq = WorkQueue.new 8

rs.shuffle[0..5].each do |rec|
	id = rec[0]
	file = "#{TMP}/#{id}.xml"
	feed = "https://www.youtube.com/feeds/videos.xml?channel_id=#{id}"
	handle = rec[1]
	wq.enqueue_b do
		puts "fetching  %-35s #{feed}.." % handle
        begin
		contents = URI.open(feed, {"User-Agent" => AGENT}).read
        rescue => e
            STDERR.puts e
            STDERR.puts handle
            next
        end
		File.open(file, "wb") do |fp|
			if contents.length > 0
				fp.write(contents)
			else
				puts "no contents?"
			end
		end
	end
end
wq.join
