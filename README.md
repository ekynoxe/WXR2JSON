WordPress eXtended RSS file to Json comments script
========

This script parses a WordPress eXtended RSS file and extracts the comments for each post and page providing the permalink structure is one of:

    <domain>/YYYY/MM/DD/slug
    <domain>/YYYY/MM/DD/slug/
    <domain>slug
    <domain>slug/

The output will be done in a json file named 'posts_comments.json' in the out/ directory and will contain the following object structure:

    {
        "YYYY-MM-DD-slug": {
            "slug": "YYYY-MM-DD-slug"
            "comments": [
                {
                    "comment_date": "2010-04-05 16:19:01",
                    "comment_date_gmt": "2010-04-05 15:19:01",
                    "comment_author": "John Doe",
                    "comment_author_email": "john.doe@domain.com",
                    "comment_author_url": "http://johndoe.com",
                    "comment_content": "blah blah blah"
                },
                {
                    "comment_date": "2010-04-05 16:19:01",
                    "comment_date_gmt": "2010-04-05 15:19:01",
                    "comment_author": "John Doe",
                    "comment_author_email": "john.doe@domain.com",
                    "comment_author_url": "http://johndoe.com",
                    "comment_content": "blah blah blah"
                }
                ...
            ]
        },
            "YYYY-MM-DD-slug": {
            "slug": "YYYY-MM-DD-slug"
            "comments": []
        }
        ...
    }

http://www.ekynoxe.com/
Version: 0.0.2 (2014-01-31)

Copyright (c) 2014 Mathieu Davy - ekynoxe - http://ekynoxe.com/
Licensed under the MIT license
(http://www.opensource.org/licenses/mit-license.php)