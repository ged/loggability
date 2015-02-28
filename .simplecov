SimpleCov.start do
	add_filter 'spec'
	add_group "Tags" do |file|
		file.filename =~ /tag.rb$/
	end
	add_group "Needing tests" do |file|
		file.covered_percent < 90
	end
end
