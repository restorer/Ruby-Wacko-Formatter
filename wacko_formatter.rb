class WackoFormatter

	def dbg(var)
		print '{' + var.inspect + "}\n"
	end

# **             - :tag_strong
# //             - :tag_em
# __             - :tag_u
# ++             - :tag_small
# ##             - :tag_tt
# --             - :tag_s
# ---            - :tag_br
# ---[-]+        - :tag_hr
# %%             - :tag_code
# >>             - :center_bg
# <<             - :center_en
# \n\r           - :newline
# \s\s           - :indent
# \s\s\*         - :list_ul
# \s\s[0-9]+\.   - :list_ol
# \s\s[A-Z]\.    - :list_upper
# \s\s[a-z]\.    - :list_lower
# \s\s[I]+\.     - :list_urome
# \s\s[i]+\.     - :list_lrome
# ^^             - :upper_index
# vv             - :lower_index
# ==             - :tag_h1
# ===            - :tag_h2
# ====           - :tag_h3
# =====          - :tag_h4
# ======         - :tag_h5
# =======        - :tag_h6
# [[ | ((        - :url_bg
# ]] | ))        - :url_en
# ""             - :unformatted
# """"           - :brk
# !!             - :tag_cite
# ??             - :tag_mark
# (?             - :term_bg
# ?)             - :term_en
# ==             - :term_delimer - if !is_newline
# #|             - :table_bord_bg
# |#             - :table_bord_en
# #||            - :table_bg
# ||#            - :table_en
# ||             - :table_row
# <[             - :cite_bg
# ]>             - :cite_en
# (c)            - :tag_copy

	def lex_parser
		@parsed = []
		state = :none
		buf = nil
		prev = nil
		is_newline = true
		indent_level = 0

		@input_string.split(//).each do |char|
			chars = [char]

			while chars.length > 0
				ch = chars.shift()
				ch = ' ' if ch == "\t"

				case state
					when :none
						if is_newline && ch=='='
							state = :wait_h1
						elsif ['*','/','_','+','#','%','>','<','[','(',']',')','!','?','^','v','=','-','|','"'].include?(ch)
							state = :wait_markup
						elsif ch=="\n" || ch=="\r"
							buf = ch
							state = :wait_newline
						elsif is_newline && ch==' '
							indent_level = 1
							state = :wait_indent
						else
							is_newline = false
							@parsed << ch
						end

					when :wait_newline
						if ch!="\n" || ch!="\r" || ch==buf
							chars << ch
						end

						@parsed << :newline
						is_newline = true
						state = :none

					when :wait_indent
						if ch == ' '
							indent_level += 1
						else
							is_newline = false

							if indent_level > 1
								for i in 1 .. (indent_level / 2).to_i
									@parsed << :indent
								end

								buf = [ch]

								if ch == '*'
									@parsed << :list_ul
									state = :none
								elsif ch>='0' && ch<='9'
									state = :wait_list_ol
								elsif ch == 'I'
									state = :wait_list_urome
								elsif ch == 'i'
									state = :wait_list_lrome
								elsif ch>='A' && ch<='Z'
									state = :wait_list_upper
								elsif ch>='a' && ch<='z'
									state = :wait_list_lower
								elsif ch == '='
									state = :wait_h1
								else
									chars << ch
									state = :none
								end
							else
								@parsed << ' '
								chars << ch
								state = :none
							end
						end

					when :wait_markup
						state = :none
						is_newline = false

						if prev == ch
							case ch
								when '*'
									@parsed << :tag_strong
								when '/'
									@parsed << :tag_em
								when '_'
									@parsed << :tag_u
								when '+'
									@parsed << :tag_small
								when '#'
									@parsed << :tag_tt
								when '%'
									@parsed << :tag_code
								when '>'
									@parsed << :center_bg
								when '<'
									@parsed << :center_en
								when '['
									@parsed << :url_bg
								when '('
									@parsed << :url_bg
								when ']'
									@parsed << :url_en
								when ')'
									@parsed << :url_en
								when '!'
									@parsed << :tag_cite
								when '?'
									@parsed << :tag_mark
								when '^'
									@parsed << :upper_index
								when 'v'
									@parsed << :lower_index
								when '='
									@parsed << :term_delimer
								when '-'
									state = :wait_br_hr
								when '|'
									state = :wait_table_row
								when '"'
									state = :wait_brk
							end
						elsif prev=='(' && ch=='?'
							@parsed << :term_bg
						elsif prev=='?' && ch==')'
							@parsed << :term_en
						elsif prev=='<' && ch=='['
							@parsed << :cite_bg
						elsif prev==']' && ch=='>'
							@parsed << :cite_en
						elsif prev=='#' && ch=='|'
							state = :wait_table
						elsif prev=='|' && ch=='#'
							@parsed << :table_bord_en
						elsif prev=='(' && ['c','C'].include?(ch)
							state = :wait_copy
						else
							@parsed << prev
							chars << ch
						end

					when :wait_copy
						if ch == ')'
							@parsed << :tag_copy
							state = :none
						else
							@parsed << '('
							chars << prev
							chars << ch
							state = :none
						end

					when :wait_table
						if ch == '|'
							@parsed << :table_bg
						else
							@parsed << :table_bord_bg
							chars << ch
						end
						state = :none

					when :wait_table_row
						if ch == '#'
							@parsed << :table_en
						else
							@parsed << :table_row
							chars << ch
						end
						state = :none

					when :wait_br_hr
						if ch == '-'
							state = :wait_hr
						else
							@parsed << :tag_s
							chars << ch
							state = :none
						end

					when :wait_hr
						if ch == '-'
							@parsed << :tag_hr
							state = :skip_minus
						else
							@parsed << :tag_br
							chars << ch
							state = :none
						end

					when :skip_minus
						if ch != '-'
							chars << ch
							state = :none
						end

					when :wait_list_ol
						if ch == '.'
							@parsed << :list_ol
							state = :none
						elsif ch<'0' || ch>'9'
							chars += buf
							chars << ch
							state = :none
						else
							buf << ch
						end

					when :wait_list_urome
						if ch == '.'
							@parsed << :list_urome
							state = :none
						elsif ch != 'I'
							chars += buf
							chars << ch
							state = :none
						else
							buf << ch
						end

					when :wait_list_lrome
						if ch == '.'
							@parsed << :list_lrome
							state = :none
						elsif ch != 'i'
							chars += buf
							chars << ch
							state = :none
						else
							buf << ch
						end

					when :wait_list_upper
						if ch == '.'
							@parsed << :list_upper
						else
							chars += buf
							chars << ch
						end
						state = :none

					when :wait_list_lower
						if ch == '.'
							@parsed << :list_lower
						else
							chars += buf
							chars << ch
						end
						state = :none

					when :wait_h1
						if ch == '='
							state = :wait_h2
						else
							chars += buf
							chars << ch
							state = :none
						end

					when :wait_h2
						if ch == '='
							state = :wait_h3
						else
							@parsed << :tag_h1
							chars << ch
							state = :none
						end

					when :wait_h3
						if ch == '='
							state = :wait_h4
						else
							@parsed << :tag_h2
							chars << ch
							state = :none
						end

					when :wait_h4
						if ch == '='
							state = :wait_h5
						else
							@parsed << :tag_h3
							chars << ch
							state = :none
						end

					when :wait_h5
						if ch == '='
							state = :wait_h6
						else
							@parsed << :tag_h4
							chars << ch
							state = :none
						end

					when :wait_h6
						if ch == '='
							state = :skip_eq
						else
							@parsed << :tag_h5
							chars << ch
							state = :none
						end

					when :skip_eq
						if ch != '='
							@parsed << :tag_h6
							chars << ch
							state = :none
						end

					when :wait_brk
						if ch == '"'
							state = :check_brk
						else
							@parsed << :unformatted
							chars << ch
							state = :unformatted_block
						end

					when :check_brk
						if ch == '"'
							@parsed << :brk
							state = :none
						else
							@parsed << :unformatted
							@parsed << '"'
							chars << ch
							state = :unformatted_block
						end

					when :unformatted_block
						if ch == '"'
							state = :unformatted_block_end
						elsif ch=="\n" || ch=="\r"
							buf = ch
							state = :unformatted_block_newline
						else
							@parsed << ch
						end

					when :unformatted_block_newline
						if ch!="\n" || ch!="\r" || ch==buf
							chars << ch
						end

						@parsed << :newline
						state = :unformatted_block

					when :unformatted_block_end
						if ch == '"'
							@parsed << :unformatted
							state = :none
						else
							@parsed << '"'
							chars << ch
							state = :unformatted_block
						end
				end

				prev = ch
			end
		end
	end

	def render_tagdef(tag)
		case tag
			when :tag_strong
				'**'
			when :tag_em
				'//'
			when :tag_u
				'__'
			when :tag_small
				'++'
			when :tag_tt
				'##'
			when :tag_s
				'--'
			when :tag_br
				'---'
			when :tag_hr
				'----'
			when :tag_code
				'%%'
			when :center_bg
				'&gt;&gt;'
			when :center_en
				'&lt;&lt;'
			when :upper_index
				'^^'
			when :lower_index
				'vv'
			when :tag_h1
				'=='
			when :tag_h2
				'==='
			when :tag_h3
				'===='
			when :tag_h4
				'====='
			when :tag_h5
				'======'
			when :tag_h6
				'======='
			when :url_bg
				'[['
			when :url_en
				']]'
			when :unformatted
				'""'
			when :brk
				'""""'
			when :tag_cite
				'!!'
			when :tag_mark
				'??'
			when :term_bg
				'(?'
			when :term_en
				'?)'
			when :term_delimer
				'=='
			when :table_bord_bg
				'#|'
			when :table_bord_en
				'|#'
			when :table_bg
				'#||'
			when :table_en
				'||#'
			when :table_row
				'||'
			when :cite_bg
				'&lt;['
			when :cite_en
				']&gt;'
			when :tag_copy
				'&copy;'
			else
				''
		end
	end

	def render_tagbg(tag)
		res = case tag
			when :tag_strong
				'strong'
			when :tag_em
				'em'
			when :tag_u
				'u'
			when :tag_small
				'small'
			when :tag_tt
				'tt'
			when :tag_s
				's'
			when :tag_code
				'pre'
			when :tag_h1
				'h1'
			when :tag_h2
				'h2'
			when :tag_h3
				'h3'
			when :tag_h4
				'h4'
			when :tag_h5
				'h5'
			when :tag_h6
				'h6'
			when :center_bg
				'div class="center"'
			when :cite_bg
				'blockquote'
			when :lower_index
				'sub'
			when :upper_index
				'sup'
			when :tag_cite
				'span class="cite"'
			when :tag_mark
				'span class="mark"'
			else
				''
		end

		res == '' ? '' : '<'+res+'>'
	end

	def render_tagen(tag)
		res = case tag
			when :tag_strong
				'strong'
			when :tag_em
				'em'
			when :tag_u
				'u'
			when :tag_small
				'small'
			when :tag_tt
				'tt'
			when :tag_s
				's'
			when :tag_code
				'pre'
			when :tag_h1
				'h1'
			when :tag_h2
				'h2'
			when :tag_h3
				'h3'
			when :tag_h4
				'h4'
			when :tag_h5
				'h5'
			when :tag_h6
				'h6'
			when :center_en
				'div'
			when :cite_en
				'blockquote'
			when :lower_index
				'sub'
			when :upper_index
				'sup'
			when :tag_cite
				'span'
			when :tag_mark
				'span'
			else
				''
		end

		res == '' ? '' : '</'+res+'>'
	end

	def href_encode(str)
		return str
	end

	def encode(str)
		res = ''

		str.each do |ch|
			if ch == '<'
				res += '&lt;'
			elsif ch == '>'
				res += '&gt;'
			else
				res += ch
			end
		end

		return res
	end

	def lookup(arr, ind, chrs, nochrs = [])
		while ind < arr.length
			ch = arr[ind]
			return nil if nochrs.include?(ch)
			return ind if chrs.include?(ch)
			ind += 1
		end

		return nil
	end

	def close_lists
		res = ''

		while @lists.length > 0
			res += '</' + @lists.pop + '>'
			@lists_indent.pop
		end

		return res
	end

	def render_plain(arr)
		res = ''

		arr.each do |ch|
			if ch.class == Symbol
				res += render_tagdef(ch)
			else
				res += ch
			end
		end

		return res
	end

	def render_encoded(arr, br2nl = false)
		res = ''

		arr.each do |ch|
			if ch.class == Symbol
				if ch == :newline
					res += br2nl ? "\n" : "<br />\n"
				else
					res += render_tagdef(ch)
				end
			else
				res += encode(ch)
			end
		end

		return res
	end

	def render(arr, br2nl = false)
		res = ''
		ind = 0

		while ind < arr.length
			ch = arr[ind]
			ind += 1

			if ch.class == Symbol
				if ch == :tag_br
					res += "<br />\n"
					@ignore_nl = true

				elsif ch == :tag_hr
					res += close_lists()
					res += "<hr />\n"
					@ignore_nl = true

				elsif [:tag_strong, :tag_em, :tag_u, :tag_small, :tag_tt, :tag_s, :tag_code].include?(ch)
					eind = lookup(arr, ind, [ch], (ch == :tag_code) ? [] : [:newline])

					if eind
						res += render_tagbg(ch)
						res += render(arr.slice(ind, eind-ind), ( ch == :tag_code ))
						res += render_tagen(ch)
						ind = eind + 1
						@ignore_nl = (ch == :tag_code)
					else
						res += render_tagdef(ch)
						@ignore_nl = false
					end

				elsif [:tag_h1, :tag_h2, :tag_h3, :tag_h4, :tag_h5, :tag_h6].include?(ch)
					eind = lookup(arr, ind, [:term_delimer], [:newline])

					if eind
						res += render_tagbg(ch)
						res += render(arr.slice(ind, eind-ind))
						res += render_tagen(ch)
						ind = eind + 1

						while ind<arr.length && ((arr[ind] == '=') || (arr[ind] == :term_delimer))
							ind += 1
						end

						@ignore_nl = true
					else
						res += render_tagdef(ch)
						@ignore_nl = false
					end

				elsif ch == :center_bg
					eind = lookup(arr, ind, [:center_en], [:center_bg])

					if eind
						res += render_tagbg(:center_bg)
						res += render(arr.slice(ind, eind-ind))
						res += render_tagen(:center_en)
						ind = eind + 1
						@ignore_nl = true
					else
						res += render_tagdef(ch)
						@ignore_nl = false
					end

				elsif ch == :cite_bg
					eind = lookup(arr, ind, [:cite_en])

					if eind
						res += render_tagbg(:cite_bg)
						res += render(arr.slice(ind, eind-ind))
						res += render_tagen(:cite_en)
						ind = eind + 1
						@ignore_nl = true
					else
						res += render_tagdef(ch)
						@ignore_nl = false
					end

				elsif ch == :brk
					unless ( (ind < arr.length) && ( [:lower_index, :upper_index].include?(arr[ind]) ) ) ||
					  ( (ind-2 > 0) && ( [:lower_index, :upper_index].include?(arr[ind - 2]) ) )
						res += render_tagdef(ch)
						@ignore_nl = false
					end

				elsif [:lower_index, :upper_index].include?(ch)
					eind = lookup(arr, ind, [ch], [' ', :newline, :tag_br])

					if eind
						if ( (ind-2 > 0) && (eind+1 < arr.length) &&
								((ch == :upper_index) ||
									( ([' ', :brk, :newline].include?(arr[ind-2])) && ([' ', :brk, :newline].include?(arr[eind+1])) )
								) &&
								(![' ', :newline].include?(arr[ind])) && (![' ', :newline].include?(arr[eind-1])) )
							res += render_tagbg(ch)
							res += render(arr.slice(ind, eind-ind))
							res += render_tagen(ch)
							ind = eind + 1
							@ignore_nl = false
						else
							res += render_tagdef(ch)
							@ignore_nl = false
						end
					else
						res += render_tagdef(ch)
						@ignore_nl = false
					end

				elsif [:tag_cite, :tag_mark].include?(ch)
					eind = lookup(arr, ind, [ch], [:newline, :tag_br])

					if eind
						if (arr[ind] != ' ') && (arr[eind-1] != ' ')
							res += render_tagbg(ch)
							res += render(arr.slice(ind, eind-ind))
							res += render_tagen(ch)
							ind = eind + 1
							@ignore_nl = false
						else
							res += render_tagdef(ch)
							@ignore_nl = false
						end
					else
						res += render_tagdef(ch)
						@ignore_nl = false
					end

				elsif ch == :url_bg
					eind = lookup(arr, ind, [:url_en], [:newline, :tag_br])

					if eind
						if (arr[ind] != ' ') # && (arr[eind-1] != ' ')
							str = render_plain(arr.slice(ind, eind-ind))
							si = str.index(' ')

							if si
								res += '<a href="' + href_encode(str.slice(0, si)) + '">'
								res += encode(str.slice(si + 1, str.length - si - 1))
								res += '</a>'
							else
								res += '<a href="' + href_encode(str) + '">'
								res += encode(str)
								res += '</a>'
							end

							ind = eind + 1
							@ignore_nl = false
						else
							res += render_tagdef(ch)
							@ignore_nl = false
						end
					else
						res += render_tagdef(ch)
						@ignore_nl = false
					end

				elsif ch == :term_bg
					eind = lookup(arr, ind, [:term_en], [:newline, :tag_br])

					if eind
						if (arr[ind] != ' ') && (arr[eind-1] != ' ')
							str = render_plain(arr.slice(ind, eind-ind))
							si = str.index(/[^ ]==[^ ]/)

							if si
								si -= 1
								sa = 2
								sb = 4
							else
								si = str.index(' ')
								sa = 0
								sb = 1
							end

							if si
								res += '<dfn title="' + encode(str.slice(0, si + sa)) + '">'
								res += encode(str.slice(si + sb, str.length - si - sb))
								res += '</dfn>'
							else
								res += '<dfn title="' + encode(str) + '">'
								res += encode(str)
								res += '</dfn>'
							end

							ind = eind + 1
							@ignore_nl = false
						else
							res += render_tagdef(ch)
							@ignore_nl = false
						end
					else
						res += render_tagdef(ch)
						@ignore_nl = false
					end

				elsif ch == :unformatted
					eind = lookup(arr, ind, [ch])

					if eind
						res += render_encoded(arr.slice(ind, eind-ind), br2nl)
						ind = eind + 1
						@ignore_nl = false
					else
						res += render_tagdef(ch)
						@ignore_nl = false
					end

				elsif ch == :newline
					if @indent_lv != 0
						if @lists.length > 0
							res += "</li>\n"
						else
							res += '</div>'
						end

						@indent_lv = 0
					else
						res += close_lists()

						if @ignore_nl
							@ignore_nl = false
							res += "\n" unless br2nl
						else
							res += br2nl ? "\n" : "<br />\n"
						end
					end

				elsif ch == :indent
					eind = ind
					while (eind < arr.length) && (arr[eind] == :indent)
						eind += 1
					end

					@indent_lv = eind - ind + 1
					ind = eind

					if [:list_ul, :list_ol, :list_upper, :list_lower, :list_urome, :list_lrome].include?(arr[ind])
						case arr[ind]
							when :list_ul
								ltype = 'ul'
								lbg = 'ul'

							when :list_ol
								ltype = 'ol'
								lbg = 'ol type="1"'

							when :list_upper
								ltype = 'ol'
								lbg = 'ol type="A"'

							when :list_lower
								ltype = 'ol'
								lbg = 'ol type="a"'

							when :list_urome
								ltype = 'ol'
								lbg = 'ol type="I"'

							else # :list_lrome
								ltype = 'ol'
								lbg = 'ol type="i"'
						end

						nl = true

						if @lists.length > 0
							if @lists_indent.last == @indent_lv
								if @lists.last != ltype
									res += '</' + @lists.pop + '>'
									@lists_indent.pop
								else
									nl = false
								end
							elsif @lists_indent.last > @indent_lv
								res += '</' + @lists.pop + '>'
								@lists_indent.pop

								nl = (@lists.last != ltype)
							end
						end

						if nl
							@lists << ltype
							@lists_indent << @indent_lv
							res += '<' + lbg + ">\n"
						end

						res += '<li>'
					else
						res += '<div style="padding-left:' + (@indent_size * @indent_lv).to_s + 'px;">'
						res += close_lists()
						@ignore_nl = true
					end

				elsif [:table_bord_bg, :table_bg].include?(ch)
					case ch
						when :table_bord_bg
							tbg = '<table cellspacing="0" cellpadding="0" class="bord-tbl">'
							et = :table_bord_en

						else # :table_bg
							tbg = '<table cellspacing="0" cellpadding="0" class="maxw-tbl">'
							et = :table_en
					end

					eind = ind + 1
					rec = 0

					while eind<arr.length && (arr[eind]!=et || rec!=0)
						if arr[eind] == ch
							rec += 1
						elsif arr[eind] == et
							rec -= 1
						end

						eind += 1
					end

					if eind < arr.length
						rows = []
						wi = ind

						while wi < eind
							rec = 0

							while wi<eind && (arr[wi]!=:table_row || rec!=0)
								if [:table_bord_bg, :table_bg].include?(arr[wi])
									rec += 1
								elsif [:table_bord_en, :table_en].include?(arr[wi])
									rec -= 1
								end

								wi += 1
							end

							wi += 1
							break if wi >= eind

							cells = []
							onecell = []
							rec = 0
							unform = false

							while wi<eind && (arr[wi]!=:table_row || rec!=0 || unform)
								if [:table_bord_bg, :table_bg].include?(arr[wi])
									rec += 1
								elsif [:table_bord_en, :table_en].include?(arr[wi])
									rec -= 1
								elsif arr[wi] == :unformatted
									unform = !unform
								end

								if !unform && rec==0 && arr[wi]=='|'
									cells << onecell
									onecell = []
								else
									onecell << arr[wi]
								end

								wi += 1
							end

							wi += 1
							break if wi >= eind

							cells << onecell
							rows << cells
						end

						max_cells = (rows.max { |a, b| a.length <=> b.length }).length
						res += tbg + "\n"

						rows.each do |cells|
							res += '<tr valign="top">' + "\n"
							cells_count = cells.length
							curr_cell = 0

							cells.each do |onecell|
								curr_cell += 1

								if curr_cell==cells_count && max_cells!=cells_count
									res += '<td colspan="' + (max_cells - curr_cell + 1).to_s + '">'
								else
									res += '<td>'
								end

								@ignore_nl = true

								res += "\n"
								res += render(onecell)
								res += "\n</td>\n"
							end

							res += "</tr>\n"
						end

						res += "</table>\n"
						ind = eind + 1
					end

				else
					res += render_tagdef(ch)
					@ignore_nl = false
				end
			else
				res += encode(ch)
				@ignore_nl = false
			end
		end

		return res
	end

	def render_all
		@ignore_nl = false
		@indent_lv = 0
		@lists = []
		@lists_indent = []
		@tables_cols = []
		@tables_inrow = []

		@result = render(@parsed)

		if @indent_lv != 0
			if @lists.length > 0
				@result += '</li>'
			else
				@result += '</div>'
			end

			@indent_lv = 0
		end

		@result += close_lists()
	end

	def parse(input_str)
		@input_string = input_str
		lex_parser()

		@indent_size = 32
		render_all()

		return @result
	end
end
