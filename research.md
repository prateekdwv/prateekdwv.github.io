---
layout: default
title: Research
subtitle: My papers in reverse chronological order
---

{% assign publication_years = site.data.publications | sort: "year" | reverse %}

<ul>
  {% for year_group in publication_years %}
    {% for publication in year_group.publications %}
      <li>
        <strong>{{ publication.title }}</strong><br>

        {% if publication.coauthors.size > 0 %}
          <em>with {% for coauthor in publication.coauthors %}{% if forloop.first %}{{ coauthor }}{% elsif forloop.last %}{% if forloop.length == 2 %} and {% else %}, and {% endif %}{{ coauthor }}{% else %}, {{ coauthor }}{% endif %}{% endfor %}</em><br>
        {% endif %}

        {% for detail in publication.details %}
          {% assign rendered_detail = detail | markdownify | remove: "<p>" | remove: "</p>" | strip %}
          <em>{{ rendered_detail }}</em><br>
        {% endfor %}

        {% for link in publication.links %}
          <a href="{{ link.url | escape }}">{{ link.label }}</a>{% unless forloop.last %} | {% endunless %}
        {% endfor %}
      </li>
    {% endfor %}
  {% endfor %}
</ul>
