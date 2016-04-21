#include "regex.hh"

#include "exception.hh"
#include "unit_tests.hh"
#include "containers.hh"

namespace Kakoune
{

#ifdef KAK_USE_STDREGEX

static String convert_regex(StringView re, Regex::flag_type& flags)
{
    if (re.substr(0_byte, 4_byte) == "(?i)")
    {
        flags |= Regex::icase;
        re = re.substr(4_byte);
    }

    String res;
    res.reserve(re.length());
    bool escaped = false;
    bool quoted = false;
    for (auto c : re)
    {
        if (not escaped and c == '\\')
        {}
        else if (quoted)
        {
            if (escaped and c == 'E')
                quoted = false;
            else
            {
                if (escaped)
                    res += "\\\\";
                if (contains("^$\\.*+?()[]{}|", c))
                    res.push_back('\\');
                res.push_back(c);
            }
        }
        else
        {
            if (escaped and c == 'h')
                res += "[ \\t]";
            else if (escaped and c == 'Q')
                quoted = true;
            else if (escaped and (c == '`' or c == 'A'))
                res += "^";
            else if (escaped and (c == '\'' or c == 'z'))
                res += "$";
            else if (not escaped and c == '$')
                res += "(?:$|(?=\n))";
            /* else if (not escaped and c == '^') How to emulate that ?
                res += "(?:^|\n)") */
            else
            {
                if (escaped)
                    res.push_back('\\');
                res.push_back(c);
            }
        }
        escaped = not escaped and c == '\\';
    }

    return res;
}

UnitTest test_convert_regex{[] {
    Regex::flag_type flags = Regex::ECMAScript;
    kak_assert(convert_regex(R"(\b\Q\b*+\E\b)", flags) == R"(\b\\b\*\+\b)" and
               flags == Regex::ECMAScript);
    kak_assert(convert_regex(R"((?i)\h+\Q*\h)", flags) == R"([ \t]+\*\\h)" and
               flags == (Regex::ECMAScript | Regex::icase));
}};

Regex::Regex(StringView re, flag_type flags)
    : m_str(re.str())
{
    String patched_re = convert_regex(re, flags);

    try
    {
        assign(patched_re.begin(), patched_re.end(), flags);
    }
    catch (std::runtime_error& err)
    {
        throw regex_error(err.what());
    }
}
#endif


String option_to_string(const Regex& re)
{
    return re.str();
}

void option_from_string(StringView str, Regex& re)
{
    re = Regex{str};
}

}
