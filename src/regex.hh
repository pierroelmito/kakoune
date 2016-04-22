#ifndef regex_hh_INCLUDED
#define regex_hh_INCLUDED

#include "string.hh"
#include "exception.hh"

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
struct Regex : std::regex
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

template<typename Iterator>
using RegexIterator = std::regex_iterator<Iterator>;

template<typename Iterator>
using MatchResults = std::match_results<Iterator>;

namespace RegexConstant = std::regex_constants;

inline RegexConstant::match_flag_type match_flags(bool bol, bool eol, bool eow)
{
    return (bol ? RegexConstant::match_default : RegexConstant::match_not_bol |
                                                 RegexConstant::match_prev_avail) |
           (eol ? RegexConstant::match_default : RegexConstant::match_not_eol);/* |
           (eow ? RegexConstant::match_default : RegexConstant::match_not_eow);*/
}

String option_to_string(const Regex& re);
void option_from_string(StringView str, Regex& re);

}

#endif // regex_hh_INCLUDED
