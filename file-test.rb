require 'wacko_formatter.rb'

wf = WackoFormatter.new
res = wf.parse(IO.read('file.in'))

File.open('file.out.html', 'w') do |fl|
	fl << "<html><head>\n"
	fl << "<style>\n"
	fl << ".cite { color:#FF0000; }\n"
	fl << ".mark { background-color:#FFAAAA; }\n"
	fl << ".center { text-align:center; }\n"
	fl << "pre { margin:0px; background-color:#FFF; border:solid #888888 1px; font-family:Courier New; font-size:10pt; width:80%; padding:3px; }\n"
	fl << "ul, ol { margin-top:0px; margin-bottom:0px; padding-top:0px; padding-bottom:0px; }\n"
	fl << "dfn { border-bottom:1px dotted #000; }\n"
	fl << "blockquote { border-left:4px solid #CCC; margin-left:32px; padding-left:8px; padding-top:8px; padding-bottom:4px; margin-top:0px; margin-bottom:0px; }\n"
	fl << "table.maxw-tbl { width: 100%; }"
	fl << "table.maxw-tbl td { padding:2px; }"
	fl << "table.bord-tbl { border-left:1px solid #000; border-top:1px solid #000; }"
	fl << "table.bord-tbl td { padding:2px; border-right:1px solid #000; border-bottom:1px solid #000; }"
	fl << "</style>\n"
	fl << "</head><body>\n\n"
	fl << res
	fl << "\n</body></html>"
end
