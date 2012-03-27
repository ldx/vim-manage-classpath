"
" Plugin to manage classpath for javacomplete
"
if exists('g:loaded_manage_classpath') || version < 700 || &cp
  finish
endif
let g:loaded_manage_classpath = 1

function! s:AppendToClasspath(path)
  let sep = javacomplete#GetClassPathSep()
  let cp = javacomplete#GetClassPath()
  let cpl = split(cp, sep)
  let i = index(cpl, a:path)
  if i == -1
    call add(cpl, a:path)
    call javacomplete#SetClassPath(join(cpl, sep))
  endif
endfunction

function! s:AppendAndroidToClasspath(sdkdir)
  let platforms = split(glob(a:sdkdir . '/platforms/android-*'), '\n')
  let maxn = -1
  for p in platforms
    let n = str2nr(matchstr(p, '[0-9]\+$'))
    if n > maxn
      let maxn = n
    endif
  endfor
  if maxn != -1
    call s:AppendToClasspath(a:sdkdir . '/platforms/android-' . maxn . '/android.jar')
  endif
endfunction

function! s:ImportClasspathFile(file) " Import Eclipse .classpath
  if !has('python')
    return
  endif
  python << EOP
import os
import vim
from xml.dom import minidom
file = vim.eval('a:file')
dom = minidom.parse(file)
for node in dom.getElementsByTagName('classpathentry'):
  kind = node.attributes['kind'].value
  path = node.attributes['path'].value
  if not os.path.isabs(path):
    path = os.path.join(os.path.dirname(file), path)
  if kind == 'src':
    vim.command('call javacomplete#AddSourcePath(\'%s\')' % path)
    print 'src:', path
  elif kind == 'lib':
    vim.command('call s:AppendToClasspath(\'%s\')' % path)
    print 'lib:', path
EOP
endfunction

function! classpath#UpdateClasspath(file)
  let path = findfile('.classpath', a:file . ';')
  if !empty(path)
    call s:ImportClasspathFile(path)
  endif
  if !empty($ANDROID_SDK_ROOT)
    call s:AppendAndroidToClasspath($ANDROID_SDK_ROOT)
  endif
endfunction
