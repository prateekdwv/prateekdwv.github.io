---
layout: page
title: Reading
subtitle: My Literary Escapades
---
A list of books I am currently reading or have read in the past. Strongly recommended books are marked with a star.

{% for entry in site.data.reading %}
## {{ entry.year}}

{% for book in entry.books %}
- {{ book.title }} {% if book.star %} ★ {% endif %}
: *{{ book.author }}* <br/>
Status: {{ book.status }} | Format: {{ book.format }}
{% endfor %}
{% endfor %}