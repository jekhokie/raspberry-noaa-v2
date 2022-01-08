#ifndef INIPARSER_H
#define INIPARSER_H

#include <algorithm>
#include <cctype>
#include <cstring>
#include <functional>
#include <iostream>
#include <list>
#include <locale>
#include <map>
#include <memory>
#include <sstream>
#include <string>

//Original source code: https://github.com/mcmtroffaes/inipp

namespace ini {

// trim functions based on http://stackoverflow.com/a/217605

template <class CharT>
inline void ltrim(std::basic_string<CharT> & s, const std::locale & loc) {
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [&loc](CharT ch) { return !std::isspace(ch, loc); }));
}

template <class CharT>
inline void rtrim(std::basic_string<CharT> & s, const std::locale & loc) {
    s.erase(std::find_if(s.rbegin(), s.rend(), [&loc](CharT ch) { return !std::isspace(ch, loc); }).base(), s.end());
}

// string replacement function based on http://stackoverflow.com/a/3418285

template <class CharT>
inline bool replace(std::basic_string<CharT> & str, const std::basic_string<CharT> & from, const std::basic_string<CharT> & to) {
    auto changed = false;
    size_t start_pos = 0;
    while ((start_pos = str.find(from, start_pos)) != std::basic_string<CharT>::npos) {
        str.replace(start_pos, from.length(), to);
        start_pos += to.length();
        changed = true;
    }
    return changed;
}

template <typename CharT, typename T>
inline bool extract(const std::basic_string<CharT> & value, T & dst, const T &defaultValue) {
    CharT c;
    std::basic_istringstream<CharT> is{ value };
    T result;
    if ((is >> std::boolalpha >> result) && !(is >> c)) {
        dst = result;
        return true;
    }
    else {
        dst = defaultValue;
        return false;
    }
}

template <typename CharT>
inline bool extract(const std::basic_string<CharT> & value, std::basic_string<CharT> & dst) {
    dst = value;
    return true;
}

template<class CharT>
class Format
{
public:
    // used for generating
    const CharT char_section_start;
    const CharT char_section_end;
    const CharT char_assign;
    const CharT char_comment;

    // used for parsing
    virtual bool is_section_start(CharT ch) const { return ch == char_section_start; }
    virtual bool is_section_end(CharT ch) const { return ch == char_section_end; }
    virtual bool is_assign(CharT ch) const { return ch == char_assign; }
    virtual bool is_comment(CharT ch) const { return ch == char_comment; }

    // used for interpolation
    const CharT char_interpol;
    const CharT char_interpol_start;
    const CharT char_interpol_sep;
    const CharT char_interpol_end;

    Format(CharT section_start, CharT section_end, CharT assign, CharT comment, CharT interpol, CharT interpol_start, CharT interpol_sep, CharT interpol_end)
        : char_section_start(section_start)
        , char_section_end(section_end)
        , char_assign(assign)
        , char_comment(comment)
        , char_interpol(interpol)
        , char_interpol_start(interpol_start)
        , char_interpol_sep(interpol_sep)
        , char_interpol_end(interpol_end) {}

    Format() : Format('[', ']', '=', ';', '$', '{', ':', '}') {}

    const std::basic_string<CharT> local_symbol(const std::basic_string<CharT>& name) const {
        return char_interpol + (char_interpol_start + name + char_interpol_end);
    }

    const std::basic_string<CharT> global_symbol(const std::basic_string<CharT>& sec_name, const std::basic_string<CharT>& name) const {
        return local_symbol(sec_name + char_interpol_sep + name);
    }
};

template<class CharT>
class IniParser
{
public:
    using String = std::basic_string<CharT>;
    using Section = std::map<String, String>;
    using Sections = std::map<String, Section>;

    Sections sections;
    std::list<String> errors;
    std::shared_ptr<Format<CharT>> format;

    IniParser() : format(std::make_shared<Format<CharT>>()) {}
    IniParser(std::shared_ptr<Format<CharT>> fmt) : format(fmt) {}

    void generate(std::basic_ostream<CharT>& os) const {
        for (auto const & sec : sections) {
            os << format->char_section_start << sec.first << format->char_section_end << std::endl;
            for (auto const & val : sec.second) {
                os << val.first << format->char_assign << val.second << std::endl;
            }
            os << std::endl;
        }
    }

    void parse(std::basic_istream<CharT> & is) {
        String line;
        String section;
        const std::locale loc{"C"};
        while (std::getline(is, line)) {
            ltrim(line, loc);
            rtrim(line, loc);
            const auto length = line.length();
            if (length > 0) {
                const auto pos = std::find_if(line.begin(), line.end(), [this](CharT ch) { return format->is_assign(ch); });
                const auto & front = line.front();
                if (format->is_comment(front)) {
                }
                else if (format->is_section_start(front)) {
                    if (format->is_section_end(line.back()))
                        section = line.substr(1, length - 2);
                    else
                        errors.push_back(line);
                }
                else if (pos != line.begin() && pos != line.end()) {
                    String variable(line.begin(), pos);
                    String value(pos + 1, line.end());
                    rtrim(variable, loc);
                    ltrim(value, loc);
                    auto & sec = sections[section];
                    if (sec.find(variable) == sec.end())
                        sec.insert(std::make_pair(variable, value));
                    else
                        errors.push_back(line);
                }
                else {
                    errors.push_back(line);
                }
            }
        }
    }

    void clear() {
        sections.clear();
        errors.clear();
    }
};

} // namespace ini

#endif // INIPARSER_H
