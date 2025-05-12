" File: ~/.vim/pack/grok_chat/start/grok_chat/plugin/grok_chat.vim
" Description: Vim plugin for chatting with xAI's Grok API
" Author: Grok (xAI)
" License: MIT

if exists('g:loaded_grok_chat')
  finish
endif
let g:loaded_grok_chat = 1

" Command to start the chat
command! GrokChat call s:GrokChat()

" Function to initialize the chat buffer
function! s:GrokChat()
  " Create a new scratch buffer
  enew
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal filetype=grokchat
  setlocal wrap
  setlocal linebreak
  file GrokChat

  " Insert initial instructions
  call append(0, ['# Grok Chat', 'Type your message and press <C-g> to send.', ''])
  normal! G

  " Map <C-g> to send the message
  nnoremap <buffer> <C-g> :call <SID>SendMessage()<CR>
endfunction

" Function to send the message
function! s:SendMessage()
  " Get the last non-empty line as the prompt
  let l:lines = getline(1, '$')
  let l:prompt = ''
  for l:line in reverse(l:lines)
    if l:line !~ '^\s*$'
      let l:prompt = l:line
      break
    endif
  endfor

  if empty(l:prompt)
    echomsg 'No prompt entered.'
    return
  endif

  " Append user prompt with prefix
  call append(line('$'), ['🗨: ' . l:prompt, ''])

  " Call Python to send the prompt to Grok API
  python3 << EOF
import vim
import sys
import os
# Use absolute path
python_dir = '/Users/xtrem/.vim/pack/grok_chat/start/grok_chat/python'
sys.path.append(python_dir)
try:
    import grok_chat
    prompt = vim.eval('l:prompt')
    response = grok_chat.send_to_grok(prompt)
    # Split response into lines and escape special characters
    lines = response.split('\n')
    escaped_lines = [line.replace("'", "''").replace('"', '\\"').replace('\n', ' ') for line in lines]
    # Prepare lines for Vim, with prefix on first line
    vim_lines = [f"🦜: {escaped_lines[0]}"] + [f"   {line}" for line in escaped_lines[1:]]
    # Append lines to buffer
    for line in vim_lines:
        vim.command(f"call append(line('$'), '{line}')")
    vim.command("call append(line('$'), '')")
except Exception as e:
    # Robust escaping of error message
    error_msg = str(e).replace("'", "''").replace('"', '\\"').replace('\n', ' ').replace(':', ' ')
    vim.command(f"echomsg 'Python error {error_msg}'")
EOF

  normal! G
endfunction
