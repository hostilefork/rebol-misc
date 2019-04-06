Rebol [
	file: %latest-of.reb
	date: 26-Mar-2019
	Author: "Graham"
	version: 0.1.1
  	note: "web and console utility"
]

idate-to-date: function [return: [date!] date [text!]] [
    digit: charset [#"0" - #"9"]
    alpha: charset [ #"A" - #"Z" #"a" - #"z" ]
    parse date [
        5 skip
        copy day: 2 digit
        space
        copy month: 3 alpha
        space
        copy year: 4 digit
        space
        copy time: to space
        space
        copy zone: to end
    ] else [
        fail ["Invalid idate:" date]
    ]
    if zone = "GMT" [zone: copy "+0"]
    to date! unspaced [day "-" month "-" year "/" time zone]
]

latest-of: function [os [tuple!]
	/commit [text!]
][
	if not commit [
		parse to text! read to url! unspaced [https://metaeducation.s3.amazonaws.com/travis-builds/ os %/zzz_git_commit.js]
     			[{git_commit = '} copy commit to {'} to end] 
	]
	root: https://s3.amazonaws.com/metaeducation/travis-builds/
	; commit: copy/part rebol/commit 7
	digit: charset [#"0" - #"6"]
	inf?: if find form rebol/version "2.102.0.16.2" [
		web: true
		fsize-of: function [o [object!]][to integer! o/content-length]
		fdate-of: function [o [object!]][
    		idate-to-date o/last-modified
		]
		pr: specialize 'replpad-write [html: true]
		:js-head
	] else [
		web: false
		fsize-of: function [o [object!]][o/size]
		fdate-of: function [o [object!]][
  			o/date    
		]
		pr: :print
		:info?
	]
	os: form os
	if parse os [ 1 digit "." 1 2 digit "." 1 2 digit end][
		; looks like it might be valid OS
		filename: unspaced ["r3-" commit]
		debugfilename: append copy filename "-debug"
		if find ["0.3.1" "0.3.40"] os [
			append filename %.exe
			append debugfilename %.exe
		]	
		latest: 1-Jan-1980
		print "searching ..."
		if error? entrap [
			filename.info: inf? filename.url: to-url unspaced [root os "/" filename]
			print ["File size:" round/to divide fsize-of filename.info 1000000 .01 "Mb" "Date:" latest: fdate-of filename.info]
			pr if web [
				unspaced ["<a href=" filename.url ">" filename.url </a> <br/>]
			] else [
				append form filename.url newline
			]
		][
			print ["file:" filename "doesn't exist, it may still be being deployed" newline]
		]
		if error? err: entrap [
			debugfilename.info: inf? debugfilename.url: to-url unspaced [root os "/" debugfilename]
			print ["File size:" round/to divide fsize-of debugfilename.info 1000000 .01 "Mb" "Date:" fdate-of debugfilename.info]
			pr if web [
				unspaced ["<a href=" debugfilename.url ">" debugfilename.url </a> <br/>]
			] else [
				form debugfilename.url
			]
		][
			; can appear here if 404 error in JS, or, inf is null
			if any [
				find err "id: 'no-value"			
				(difference now latest) < 2:00 
			][
				print ["file:" debugfilename "doesn't exist, it may still be being deployed"]
			]
			()
		]
			
	] else [
		print "Invalid OS"
	]
]
