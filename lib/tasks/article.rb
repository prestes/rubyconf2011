namespace :article do

  desc "Creates a new article. Params: title, order, lang"
  task :create do
    require 'active_support/all'
    @ymd = Time.now.to_s(:db).split(' ')[0]
    if !ENV['title']
      $stderr.puts "\t[error] Missing title argument.\n\tusage: rake create:article title='article title' order=1 lang=en"
      exit 1
    end
    @lang = ENV['lang'] || 'en'
    @order = ENV['order']

    title = ENV['title'].capitalize
    path, filename, full_path = calc_path(title)

    if File.exists?(full_path)
      $stderr.puts "\t[error] Exists #{full_path}"
      exit 1
    end

    template = <<TEMPLATE
---
language: #{@lang}
created_at: #{@ymd}
excerpt:
kind: article
publish: true
title: "#{title.titleize}"
---

TODO: Add content to `#{full_path}.`
TEMPLATE

    FileUtils.mkdir_p(path) if !File.exists?(path)
    File.open(full_path, 'w') { |f| f.write(template) }
    $stdout.puts "\t[ok] Edit #{full_path}"
  end

  def calc_path(title)
    path = "content/whatsup/"
    filename = @ymd + "-" + (@order ? @order + "-" : "") + title.parameterize('_') + ".html"
    [path, filename, path + filename]
  end
end


