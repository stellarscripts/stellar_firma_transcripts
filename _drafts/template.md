---
layout: post
title: Episode EPISODE NUMBER - EPISODE TITLE
date: 2019-02-05 00:05:09.000000000 +00:00
categories: episode
episode_number: EPISODE NUMBER
episode_title: EPISODE TITLE GOES HERE AGAIN
tags: [tags go here, separated by commas, if you want them, (but they don't actually work on GitHub Pages)]
content_warnings: CONTENT WARNINGS LIST GOES HERE
acast_url: ADDRESS OF ACTUAL EPISODE ON ACAST GOES HERE
summary: EPISODE SUMMARY GOES HERE
formats:
  HTML: HTML ADDRESS GOES HERE
  Google Doc: GOOGLE DOC ADDRESS GOES HERE
sources:
  stellarscripts: http://stellarscripts.tumblr.com/
official: false
---

## How to add a new episode:

* In GitHub, open this file in "Raw" mode (the "Raw" button is in the upper right corner). You'll know you're looking at the right version of the file because you'll be able to see a bunch of code-looking text in between two '---' bars. That's called the 'frontmatter,' and if you leave it out Jekyll will have trouble displaying the transcript, or won't display it at all.

* In another window tab, also in GitHub, open [the page for the '\_posts' directory](https://github.com/stellarscripts/stellar_firma_transcripts/tree/master/_posts).

* Click 'Add File', then 'Create new file'.

* For a normal episode, in the "Name your file..." field, you'd put something like

> 2019-02-15-001.md

Meaning that it's episode 1 (the 001 part at the end), and it aired on 2019-02-15 (February 15th, 2019).

For an episode without a number, you'd instead name it

> 2019-02-15-episodetitle.md

* Copy and paste everything in here (INCLUDING the stuff between the two '---'s above) into the text field.

* Edit the lines in the text field to add the episode name, number, air date, Google Doc URLs, etc.

* If the episode is a special, be sure to change 'categories: episode' to 'categories: special'.

* Replace everything but the frontmatter with the actual transcript. When you're done, click 'Commit new file'.

The formatting of the actual transcripts works like this: 

#### IMOGEN ('S NAME HAS 4 POUND SIGNS BEFORE IT, LIKE THIS)

Here is some dialog, with some *italic words* and some __bold words.__

Here is another line of dialog.

##### [CAPTIONS SHOULD HAVE 5 POUND SIGNS BEFORE THEM LIKE THIS]

If you want to add a divider between sections, you add six hypens in a row:

------

Like that.

> Quotations (blockquotes) have a 'greater than' sign before them, like this.

[Links look like this.](http://www.example.com/)

<span style="color: red;">And you can also use just plain HTML if you want.</span>