#ifndef regex_hh_INCLUDED
#define regex_hh_INCLUDED

#include "string.hh"
#include "exception.hh"
#include "utf8_iterator.hh"

#include <regex>

namespace Kakoune
{

struct regex_error : runtime_error
{
    regex_error(StringView desc)
        : runtime_error{format("regex error: '{}'", desc)}
    {}
};

// Regex that keeps track of its string representation
struct Regex : std::wregex
{
    Regex() = default;

    explicit Regex(StringView re, flag_type flags = ECMAScript);
    bool empty() const { return m_str.empty(); }
    bool operator==(const Regex& other) const { return m_str == other.m_str; }
    bool operator!=(const Regex& other) const { return m_str != other.m_str; }

    const String& str() const { return m_str; }

private:
    String m_str;
};

template<typename It>
using RegexUtf8It = utf8::iterator<It, wchar_t, ssize_t>;

namespace RegexConstant = std::regex_constants;

template<typename Iterator>
struct RegexIterator : std::regex_iterator<RegexUtf8It<Iterator>>
{
    using ParentType = std::regex_iterator<RegexUtf8It<Iterator>>;
    using Utf8It = RegexUtf8It<Iterator>;

    RegexIterator() = default;
    RegexIterator(Iterator begin, Iterator end, const Regex& re,
                  RegexConstant::match_flag_type flags = RegexConstant::match_default)
        : ParentType{Utf8It{begin, begin, end}, Utf8It{end, begin, end}, re, flags} {}
};

template<typename Iterator>
using MatchResults = std::match_results<RegexUtf8It<Iterator>>;

inline RegexConstant::match_flag_type match_flags(bool bol, bool eol, bool eow)
{
    return (bol ? RegexConstant::match_default : RegexConstant::match_not_bol |
                                                 RegexConstant::match_prev_avail) |
           (eol ? RegexConstant::match_default : RegexConstant::match_not_eol);/* |
           (eow ? RegexConstant::match_default : RegexConstant::match_not_eow);*/
}

template<typename It>
bool regex_match(It begin, It end, const Regex& re)
{
    using Utf8It = RegexUtf8It<It>;
    return std::regex_match(Utf8It{begin, begin, end}, Utf8It{end, begin, end}, re);
}

template<typename It>
bool regex_match(It begin, It end, MatchResults<It>& res, const Regex& re)
{
    using Utf8It = RegexUtf8It<It>;
    return std::regex_match(Utf8It{begin, begin, end}, Utf8It{end, begin, end}, res, re);
}

template<typename It>
bool regex_search(It begin, It end, const Regex& re,
                  RegexConstant::match_flag_type flags = RegexConstant::match_default)
{
    using Utf8It = RegexUtf8It<It>;
    return std::regex_search(Utf8It{begin, begin, end}, Utf8It{end, begin, end}, re);
}

template<typename It>
bool regex_search(It begin, It end, MatchResults<It>& res, const Regex& re,
                  RegexConstant::match_flag_type flags = RegexConstant::match_default)
{
    using Utf8It = RegexUtf8It<It>;
    return std::regex_search(Utf8It{begin, begin, end}, Utf8It{end, begin, end}, res, re);
}

String option_to_string(const Regex& re);
void option_from_string(StringView str, Regex& re);

}

#endif // regex_hh_INCLUDED
