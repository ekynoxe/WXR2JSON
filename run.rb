# encoding: utf-8
#
# WordPress eXtended RSS file to Json comments script
# http://www.ekynoxe.com/
# Version: 0.0.2 (2014-01-31)
#
# Copyright (c) 2014 Mathieu Davy - ekynoxe - http://ekynoxe.com/
# Licensed under the MIT license
# (http://www.opensource.org/licenses/mit-license.php)
#
# This script parses a WordPress eXtended RSS file and extracts the comments
#   for each post and page providing the permalink structure is one of:
#
#    <domain>/YYYY/MM/DD/slug
#    <domain>/YYYY/MM/DD/slug/
#    <domain>slug
#    <domain>slug/
#
# The output will be done in a json file named 'posts_comments.json' in the out/ directory
#   and will contain the following object structure:
#
#    {
#       "YYYY-MM-DD-slug": {
#           "slug": "YYYY-MM-DD-slug"
#           "comments": [
#               {
#                   "comment_date": "2010-04-05 16:19:01",
#                   "comment_date_gmt": "2010-04-05 15:19:01",
#                   "comment_author": "John Doe",
#                   "comment_author_email": "john.doe@domain.com",
#                   "comment_author_url": "http://johndoe.com",
#                   "comment_content": "blah blah blah"
#               },
#               {
#                   "comment_date": "2010-04-05 16:19:01",
#                   "comment_date_gmt": "2010-04-05 15:19:01",
#                   "comment_author": "John Doe",
#                   "comment_author_email": "john.doe@domain.com",
#                   "comment_author_url": "http://johndoe.com",
#                   "comment_content": "blah blah blah"
#               }
#
#               ...
#
#           ]
#       },
#       "YYYY-MM-DD-slug": {
#           "slug": "YYYY-MM-DD-slug"
#           "comments": []
#       }
#
#       ...
#
#    }

require 'rubygems'
require 'fileutils'
require 'nokogiri'
require 'json'

@out = "./out/"
@outFileName = "posts_comments.json"

class Object
    def present?
      !blank?
    end

    def blank?
      respond_to?(:empty?) ? empty? : !self
    end
end

filePath = ARGV[0]

if !filePath.blank?
    @filePath = filePath
else
    puts "no file name provided."
    exit
end

if !File.exists?(@filePath)
    puts "file " + @filePath + " not found."
    exit
end

FileUtils.mkdir_p @out

def getDoc()
    begin
        puts "> Trying to read " + @filePath
        puts ""
        f = File.open(@filePath)
        doc = Nokogiri::XML(f)
        f.close
    rescue
        puts "> Oops, something went wrong here. Are you sure you've entered the WXR file path correctly?"
        exit
    end

    return doc
end

def attachComments(parentId, comments)
    children = []
    grandChildren = []

    comments.each do |comment|
        if parentId == comment["comment_parent"]
            children << comment
        else
            grandChildren << comment
        end
    end

    if !grandChildren.empty?
        children.each do |child|
            child["replies"] = attachComments(child["id"], grandChildren)
        end
    end

    return children
end

def run
    puts "> Let's reformat that massive WXR file shall we?"
    puts ""
    doc = getDoc()
    puts "> Ok, we've got a document in memory, let's extract what we need"
    puts ""
    posts = {}

    if(doc != nil)

        # Only extract comments from posts and pages
        doc.xpath("//item[contains(.//wp:post_type, 'post') or contains(.//wp:post_type, 'page')]").each do |post|
            post_url = post.xpath("link")[0].text
            post_title = post.xpath("title")[0].text

            # Excluding pingbacks
            post_comments = post.xpath("wp:comment[not(contains(.//wp:comment_type, 'pingback'))]")

            puts "> Processing post " +  post_title

            # Is it a post matching a  /YYYY/MM/DD/slug/  url?
            url_parts = post_url.match(/[http|https]:\/\/.+\..+\/([0-9]{4})\/([0-9]{2})\/([0-9]{2})\/([^\/]+)\/?/i)
            if url_parts.blank?
                # No match, so maybe a page not using the same url structure than a post
                # Let's extract the simple slug
                url_parts = post_url.match(/[http|https]:\/\/.+\..+\/([^\/]+)\/?/i)
            end

            if url_parts.blank?
                puts "/!\ Well, it looks like this post doesn't match the url structures we want (<domain>/YYYY/MM/DD/slug,  <domain>/YYYY/MM/DD/slug/,  <domain>slug  or  <domain>slug/). Moving on to the next one"
                puts ""

                next
            end

            comments = []

            puts "> Now processing comments for this post"
            post_comments.each do |comment|

                comments << {
                    "id" => comment.xpath("wp:comment_id")[0].text,
                    "comment_date" => comment.xpath("wp:comment_date")[0].text,
                    "comment_date_gmt" => comment.xpath("wp:comment_date_gmt")[0].text,
                    "comment_author" => comment.xpath("wp:comment_author")[0].text,
                    "comment_author_email" => comment.xpath("wp:comment_author_email")[0].text,
                    "comment_author_url" => comment.xpath("wp:comment_author_url")[0].text,
                    "comment_content" => comment.xpath("wp:comment_content")[0].text,
                    "comment_parent" => comment.xpath("wp:comment_parent")[0].text,
                    "replies" => []
                }
            end

            attachedComments = attachComments("0", comments)

            posts[url_parts.captures.join("-")] = {
                "slug" => url_parts.captures.join("-"),
                "comments" => attachedComments
            } if !(comments.size == 0)

            puts ""
        end
    end

    File.open(File.join( @out, @outFileName ), 'w') do |f|
        f.write posts.to_json
        f.close
    end
    puts "Done! Checkout the results in " + File.join( @out, @outFileName )
end

run