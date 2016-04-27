hook global BufCreate .*\.(cc|cpp|cxx|C|hh|hpp|hxx|H)$ %{
    set buffer filetype cpp
    set buffer mimetype ''
}

hook global BufCreate .*\.c$ %{
    set buffer filetype c
    set buffer mimetype ''
}

hook global BufCreate .*\.h$ %{
    try %{
        exec %{%s\b::\b|\btemplate\h*<lt>|\bclass\h+\w+|\b(typename|namespace)\b|\b(public|private|protected)\h*:<ret>}
        set buffer filetype cpp
    } catch %{
        set buffer filetype c
    }
    set buffer mimetype ''
}

hook global BufSetOption mimetype=text/x-c %{
    set buffer filetype c
}

hook global BufSetOption mimetype=text/x-c\+\+ %{
    set buffer filetype cpp
}

hook global BufCreate .*\.m %{
    set buffer filetype objc
    set buffer mimetype ''
}

hook global BufSetOption mimetype=text/x-objc %{
    set buffer filetype objc
}

def -hidden _c-family-indent-on-new-line %~
    eval -draft -itersel %=
        # preserve previous line indent
        try %{ exec -draft \;K<a-&> }
        # indent after lines ending with { or (
        try %[ exec -draft k<a-x> <a-k> [{(]\h*$ <ret> j<a-gt> ]
        # cleanup trailing white space son previous line
        try %{ exec -draft k<a-x> s \h+$ <ret>d }
        # align to opening paren of previous line
        try %{ exec -draft [( <a-k> \`\([^\n]+\n[^\n]*\n?\' <ret> s \`\(\h*.|.\' <ret> '<a-;>' & }
        # align to previous statement start when previous line closed a parenthesis
        # try %{ exec -draft <a-?>\)M<a-k>\`\(.*\)[^\n()]*\n\h*\n?\'<ret>s\`|.\'<ret>1<a-&> }
        # copy // comments prefix
        try %{ exec -draft \;<c-s>k<a-x> 1s ^\h*(/{2,}) <ret> y<c-o><c-o>P<esc> }
        # indent after visibility specifier
        try %[ exec -draft k<a-x> <a-k> ^\h*(public|private|protected):\h*$ <ret> j<a-gt> ]
        # indent after if|else|while|for
        try %[ exec -draft \;<a-F>)MB <a-k> \`(if|else|while|for)\h*\(.*\)\h*\n\h*\n?\' <ret> s \`|.\' <ret> 1<a-&>1<a-space><a-gt> ]
    =
~

def -hidden _c-family-indent-on-opening-curly-brace %[
    # align indent with opening paren when { is entered on a new line after the closing paren
    try %[ exec -draft -itersel h<a-F>)M <a-k> \`\(.*\)\h*\n\h*\{\' <ret> s \`|.\' <ret> 1<a-&> ]
]

def -hidden _c-family-indent-on-closing-curly-brace %[
    # align to opening curly brace when alone on a line
    try %[ exec -itersel -draft <a-h><a-k>^\h+\}$<ret>hms\`|.\'<ret>1<a-&> ]
    # add ; after } if class or struct definition
    try %[ exec -draft "hm;<a-?>(class|struct|union)<ret><a-k>\`(class|struct|union)[^{}\n]+(\n)?\s*\{\'<ret><a-;>ma;<esc>" ]
]

# Regions definition are the same between c++ and objective-c
%sh{
    for ft in c cpp objc; do
        if [ "${ft}" = "objc" ]; then
            maybe_at='@?'
        else
            maybe_at=''
        fi

        printf %s\\n '
            addhl -group / regions -default code FT \
                string %{MAYBEAT(?<!QUOTE)"} %{(?<!\\)(\\\\)*"} "" \
                comment /\* \*/ "" \
                comment // $ "" \
                disabled ^\h*?#\h*if\h+(0|FALSE)\b "#\h*(else|elif|endif)" "#\h*if(def)?" \
                macro %{^\h*?\K#} %{(?<!\\)\n} ""

            addhl -group /FT/string fill string
            addhl -group /FT/comment fill comment
            addhl -group /FT/disabled fill rgb:666666
            addhl -group /FT/macro fill meta' | sed -e "s/FT/${ft}/g; s/QUOTE/'/g; s/MAYBEAT/${maybe_at}/;"
    done
}

# c specific
addhl -group /c/code regex %{\bNULL\b|\b-?(0x[0-9a-fA-F]+|\d+)[fdiu]?|'((\\.)?|[^'\\])'} 0:value
%sh{
    # Grammar
    keywords="while|for|if|else|do|switch|case|default|goto|asm|break|continue|return|sizeof"
    attributes="const|auto|register|inline|static|volatile|struct|enum|union|typedef|extern|restrict"
    types="void|char|short|int|long|signed|unsigned|float|double|size_t"

    # Add the language's grammar to the static completion list
    printf %s\\n "hook global WinSetOption filetype=c %{
        set window static_words '${keywords}'
        set -add window static_words '${attributes}'
        set -add window static_words '${types}'
    }" | sed 's,|,:,g'

    # Highlight keywords
    printf %s "
        addhl -group /c/code regex \b(${keywords})\b 0:keyword
        addhl -group /c/code regex \b(${attributes})\b 0:attribute
        addhl -group /c/code regex \b(${types})\b 0:type
    "
}

# c++ specific
addhl -group /cpp/code regex %{\b-?(0x[0-9a-fA-F]+|\d+)[fdiu]?|'((\\.)?|[^'\\])'} 0:value

%sh{
    # Grammar
    keywords="while|for|if|else|do|switch|case|default|goto|asm|break|continue"
    keywords="${keywords}|return|using|try|catch|throw|new|delete|and|and_eq|or"
    keywords="${keywords}|or_eq|not|operator|explicit|reinterpret_cast"
    keywords="${keywords}|const_cast|static_cast|dynamic_cast|sizeof|alignof"
    keywords="${keywords}|alignas|decltype"
    attributes="const|constexpr|mutable|auto|noexcept|namespace|inline|static"
    attributes="${attributes}|volatile|class|struct|enum|union|public|protected"
    attributes="${attributes}|private|template|typedef|virtual|friend|extern"
    attributes="${attributes}|typename|override|final"
    types="void|char|short|int|long|signed|unsigned|float|double|size_t|bool"
    values="this|true|false|NULL|nullptr"

    # Add the language's grammar to the static completion list
    printf %s\\n "hook global WinSetOption filetype=cpp %{
        set window static_words '${keywords}'
        set -add window static_words '${attributes}'
        set -add window static_words '${types}'
        set -add window static_words '${values}'
    }" | sed 's,|,:,g'

    # Highlight keywords
    printf %s "
        addhl -group /cpp/code regex \b(${keywords})\b 0:keyword
        addhl -group /cpp/code regex \b(${attributes})\b 0:attribute
        addhl -group /cpp/code regex \b(${types})\b 0:type
        addhl -group /cpp/code regex \b(${values})\b 0:value
    "
}

# objective-c specific
addhl -group /objc/code regex %{\b-?\d+[fdiu]?|'((\\.)?|[^'\\])'} 0:value

%sh{
    # Grammar
    keywords="while|for|if|else|do|switch|case|default|goto|break|continue|return"
    attributes="const|auto|inline|static|volatile|struct|enum|union|typedef"
    attributes="${attributes}|extern|__block|nonatomic|assign|copy|strong"
    attributes="${attributes}|retain|weak|readonly|IBAction|IBOutlet"
    types="void|char|short|int|long|signed|unsigned|float|bool|size_t"
    types="${types}|instancetype|BOOL|NSInteger|NSUInteger|CGFloat|NSString"
    values="self|nil|id|super|TRUE|FALSE|YES|NO|NULL"
    decorators="property|synthesize|interface|implementation|protocol|end"
    decorators="${decorators}|selector|autoreleasepool|try|catch|class|synchronized"

    # Add the language's grammar to the static completion list
    printf %s\\n "hook global WinSetOption filetype=objc %{
        set window static_words '${keywords}:${attributes}:${types}:${values}:${decorators}'
    }" | sed 's,|,:,g'

    # Highlight keywords
    printf %s "
        addhl -group /objc/code regex \b(${keywords})\b 0:keyword
        addhl -group /objc/code regex \b(${attributes})\b 0:attribute
        addhl -group /objc/code regex \b(${types})\b 0:type
        addhl -group /objc/code regex \b(${values})\b 0:value
        addhl -group /objc/code regex @(${decorators})\b 0:attribute
    "
}

hook global WinSetOption filetype=(c|cpp|objc) %[
    try %{ # we might be switching from one c-family language to another
        rmhooks window c-family-hooks
        rmhooks window c-family-indent
    }

    # cleanup trailing whitespaces when exiting insert mode
    hook window InsertEnd .* -group c-family-hooks %{ try %{ exec -draft <a-x>s^\h+$<ret>d } }

    hook window InsertChar \n -group c-family-indent _c-family-indent-on-new-line
    hook window InsertChar \{ -group c-family-indent _c-family-indent-on-opening-curly-brace
    hook window InsertChar \} -group c-family-indent _c-family-indent-on-closing-curly-brace

    alias window alt c-family-alternative-file

    set window formatcmd "astyle"
]

hook global WinSetOption filetype=(?!(c|cpp|objc)$).* %[
    rmhooks window c-family-hooks
    rmhooks window c-family-indent

    unalias window alt c-family-alternative-file
]

hook global WinSetOption filetype=c %[ addhl ref c ]
hook global WinSetOption filetype=(?!c$).* %[ rmhl c ]

hook global WinSetOption filetype=cpp %[ addhl ref cpp ]
hook global WinSetOption filetype=(?!cpp$).* %[ rmhl cpp ]

hook global WinSetOption filetype=objc %[ addhl ref objc ]
hook global WinSetOption filetype=(?!objc$).* %[ rmhl objc ]

decl str c_include_guard_style "ifdef"
def -hidden _c-family-insert-include-guards %{
    %sh{
        case "${kak_opt_c_include_guard_style}" in
            ifdef)
                echo 'exec ggi<c-r>%<ret><esc>ggxs\.<ret>c_<esc><space>A_INCLUDED<esc>ggxyppI#ifndef<space><esc>jI#define<space><esc>jI#endif<space>//<space><esc>O<esc>'
                ;;
            pragma)
                echo 'exec ggi#pragma<space>once<esc>'
                ;;
            *);;
        esac
    }
}

hook global BufNew .*\.(h|hh|hpp|hxx|H) _c-family-insert-include-guards

decl str-list alt_dirs ".;.."

def c-family-alternative-file -docstring "Jump to the alternate file (header/implementation)" %{ %sh{
    alt_dirs=$(printf %s\\n "${kak_opt_alt_dirs}" | sed -e 's/;/ /g')
    file=$(basename "${kak_buffile}")
    dir=$(dirname "${kak_buffile}")

    case ${file} in
        *.c|*.cc|*.cpp|*.cxx|*.C|*.inl|*.m)
            for alt_dir in ${alt_dirs}; do
                for ext in h hh hpp hxx H; do
                    altname="${dir}/${alt_dir}/${file%.*}.${ext}"
                    [ -f ${altname} ] && break
                done
                [ -f ${altname} ] && break
            done
        ;;
        *.h|*.hh|*.hpp|*.hxx|*.H)
            for alt_dir in ${alt_dirs}; do
                for ext in c cc cpp cxx C m; do
                    altname="${dir}/${alt_dir}/${file%.*}.${ext}"
                    [ -f ${altname} ] && break
                done
                [ -f ${altname} ] && break
            done
        ;;
        *)
            echo "echo -color Error 'extension not recognized'"
            exit
        ;;
    esac
    if [ -f ${altname} ]; then
       printf %s\\n "edit '${altname}'"
    else
       echo "echo -color Error 'alternative file not found'"
    fi
}}
