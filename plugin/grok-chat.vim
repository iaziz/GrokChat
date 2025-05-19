" File: ~/.vim/pack/grok_chat/start/grok_chat/plugin/grok_chat.vim
" Description: Vim plugin for chatting with xAI's Grok API
" Author: Grok (xAI)
" License: MIT

if exists('g:loaded_grok_chat')
  finish
endif
let g:loaded_grok_chat = 1

let s:plugin_root_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

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

  " No initial instructions; start with an empty line
  call append(0, [''])
  normal! G

  " Map <C-g> to send the message
  nnoremap <buffer> <C-g> :call <SID>SendMessage()<CR>
endfunction

" Function to animate typing text in the buffer
function! s:TypeText(text, speed)
  " Check if buffer is modifiable
  if !&modifiable
    setlocal modifiable
  endif
  " Validate inputs
  if empty(a:text)
    echoerr "Text cannot be empty!"
    return
  endif
  if a:speed <= 0
    echoerr "Speed must be positive!"
    return
  endif
  " Split text into characters
  let chars = split(a:text, '\zs')
  for char in chars
    execute "normal! a" . char
    redraw
    execute "sleep " . a:speed . "m"
  endfor
endfunction

" Function to send the message
function! s:SendMessage()
  " Get all lines in the buffer
  let l:lines = getline(1, '$')
  " Filter out empty lines and trim whitespace
  let l:non_empty_lines = filter(map(l:lines, 'trim(v:val)'), '!empty(v:val)')
  
  " Join non-empty lines into a single prompt
  let l:prompt = join(l:non_empty_lines, "\n")

  if empty(l:prompt)
    echomsg 'No prompt entered.'
    return
  endif

  " Append user prompt with prefix
  call append(line('$'), ['🗨: ' . l:non_empty_lines[0], join(l:non_empty_lines[1:], '   '), ''])

  " Store the original modifiable state
  let l:original_modifiable = &modifiable

  " Call Python to send the prompt to Grok API

python3 << EOF
import sys
from os.path import normpath, join
import vim
plugin_root_dir = vim.eval('s:plugin_root_dir')
python_dir = normpath(join(plugin_root_dir, '..', 'python'))
sys.path.append(python_dir)

try:
    import grok_chat
    prompt = vim.eval('l:prompt')
    response = grok_chat.send_to_grok(prompt)
    # Split response into lines
    lines = response.split('\n')
    # Append lines directly to the buffer
    vim.command("setlocal modifiable")
    for i, line in enumerate(lines):
        prefix = '🦜: ' if i == 0 else '   '
        # Escape single quotes and backslashes for Vim
        escaped_line = line.replace("'", "''").replace('\\', '\\\\')
        vim.command(f"call append(line('$'), '{prefix}{escaped_line}')")
    vim.command("call append(line('$'), '')")
    vim.command("normal! G")
except Exception as e:
    error_msg = str(e).replace("'", "''").replace('"', '\\"').replace('\n', ' ').replace(':', ' ')
    vim.command(f"echomsg 'Python error {error_msg}'")
EOF
  
  
  " Check if response_lines exists
  if !exists('s:response_lines')
    echomsg 'No response received from Grok API.'
    return
  endif

  " Ensure buffer is modifiable for typing
  setlocal modifiable

  " Append an empty line before the response
  call append(line('$'), '')

  " Process and animate each response line
  let l:first = 1
  for l:line in s:response_lines
    let l:prefix = l:first ? '🦜: ' : '   '
    let l:text = l:prefix . l:line
    call s:TypeText(l:text . "\n", 30) " 50ms per character
    let l:first = 0
  endfor

  " Append an empty line after the response
  call append(line('$'), '')

  " Restore original modifiable state
  if !l:original_modifiable
    setlocal nomodifiable
  endif

  " Clear response_lines
  unlet s:response_lines

  normal! G
endfunction
