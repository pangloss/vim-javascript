setlocal suffixesadd+=.js
if (v:version < 704 || (v:version == 704 && !has('patch002'))) && exists('&regexpengine')
  set re=1
end
