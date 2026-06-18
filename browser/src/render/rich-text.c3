module render;

import raylib6::rl;
import std::collections::list;
import std::core::mem;
import std::core::string;
import std::io;

enum FontStyle
{
    NORMAL,
    BOLD,
    ITALIC,
    BOLD_ITALIC,
}

enum RunKind
{
    RUN_TEXT,
    RUN_EMOJI,
}

struct TextRun
{
    RunKind kind;
    String text;
    FontStyle style;
}

struct RichText
{
    List{TextRun} runs;
}

fn void RichText.init(&self, Allocator allocator)
{
	self.runs.init(allocator);
}

fn void RichText.free(&self)
{
    foreach (TextRun run : self.runs)
    {
        free(run.text);
    }
    self.runs.free();
}

fn FontStyle compute_style(List{FontStyle} stack) @local
{
    bool bold = false;
    bool italic = false;
    foreach (FontStyle s : stack)
    {
        if (s == FontStyle.BOLD)   bold   = true;
        if (s == FontStyle.ITALIC) italic = true;
    }
    if (bold && italic) return FontStyle.BOLD_ITALIC;
    if (bold)           return FontStyle.BOLD;
    if (italic)         return FontStyle.ITALIC;
    return FontStyle.NORMAL;
}

fn usz utf8_seq_len(char lead) @local
{
    if ((lead & 0x80) == 0)    return 1;
    if ((lead & 0xE0) == 0xC0) return 2;
    if ((lead & 0xF0) == 0xE0) return 3;
    if ((lead & 0xF8) == 0xF0) return 4;
    return 1;
}

fn uint decode_codepoint(String s, usz i) @local
{
    switch (utf8_seq_len(s[i]))
    {
        case 1: return s[i];
        case 2: return ((uint)(s[i]   & 0x1F) << 6)
                     |  (uint)(s[i+1] & 0x3F);
        case 3: return ((uint)(s[i]   & 0x0F) << 12)
                     | ((uint)(s[i+1] & 0x3F) << 6)
                     |  (uint)(s[i+2] & 0x3F);
        case 4: return ((uint)(s[i]   & 0x07) << 18)
                     | ((uint)(s[i+1] & 0x3F) << 12)
                     | ((uint)(s[i+2] & 0x3F) << 6)
                     |  (uint)(s[i+3] & 0x3F);
        default: return 0;
    }
}

fn bool is_emoji_codepoint(uint cp) @local
{
    return cp >= 0x1F000
        || cp == 0x2764
        || cp == 0x2665
        || cp == 0x2B50
        || cp == 0x2B55
        || cp == 0x2600
        || cp == 0x2603;
}

fn bool is_fitzpatrick(uint cp) @local
{
    return cp >= 0x1F3FB && cp <= 0x1F3FF;
}

fn bool is_zwj_or_vs(uint cp) @local
{
    return cp == 0x200D || cp == 0xFE0F;
}

fn usz consume_emoji_sequence(String input, usz i) @local
{
    usz seq = 0;
    while (i + seq < input.len)
    {
        usz cplen = utf8_seq_len(input[i + seq]);
        if (i + seq + cplen > input.len) break;
        uint cp = decode_codepoint(input, i + seq);
        if (seq == 0 && !is_emoji_codepoint(cp)) break;
        if (seq > 0 && !is_zwj_or_vs(cp) && !is_fitzpatrick(cp) && !is_emoji_codepoint(cp)) break;
        seq += cplen;
        if (!is_zwj_or_vs(cp))
        {
            if (i + seq >= input.len) break;
            uint nextcp = decode_codepoint(input, i + seq);
            if (!is_zwj_or_vs(nextcp) && !is_fitzpatrick(nextcp)) break;
        }
    }
    return seq;
}

fn String emoji_key_from_text(String text) @local
{
    DString key;
    usz i = 0;
    bool first = true;
    while (i < text.len)
    {
        usz cplen = utf8_seq_len(text[i]);
        uint cp = decode_codepoint(text, i);
        if (!first) key.append_char('-');
        key.appendf("%x", cp);
        first = false;
        i += cplen;
    }
    key.append(".png");
    return key.str_view().copy(mem);
}

fn RichText create_rich_text(String input)
{
    RichText out;
    List{FontStyle} style_stack;
    out.runs.init(mem);
    style_stack.init(mem);

    usz run_start = 0;
    usz i = 0;

    while (i < input.len)
    {
        char c = input[i];

        if (c == '*' || c == '_')
        {
            if (i > run_start)
            {
                out.runs.push({
                    .kind  = RunKind.RUN_TEXT,
                    .text  = input[run_start..i-1].copy(mem),
                    .style = compute_style(style_stack),
                });
            }

            FontStyle toggle = (c == '*') ? FontStyle.BOLD : FontStyle.ITALIC;
            while (i < input.len && input[i] == c) i++;

            bool found = false;
            foreach (sz j, FontStyle s : style_stack)
            {
                if (s == toggle)
                {
                    style_stack.remove_at(j);
                    found = true;
                    break;
                }
            }
            if (!found) style_stack.push(toggle);

            run_start = i;
            continue;
        }

        uint cp = decode_codepoint(input, i);
        if (is_emoji_codepoint(cp))
        {
            if (i > run_start)
            {
                out.runs.push({
                    .kind  = RunKind.RUN_TEXT,
                    .text  = input[run_start..i-1].copy(mem),
                    .style = compute_style(style_stack),
                });
            }

            usz seq = consume_emoji_sequence(input, i);
            out.runs.push({
                .kind  = RunKind.RUN_EMOJI,
                .text  = emoji_key_from_text(input[i..i+seq-1]),
                .style = FontStyle.NORMAL,
            });

            i += seq;
            run_start = i;
            continue;
        }

        i++;
    }

    if (run_start < input.len)
    {
        out.runs.push({
            .kind  = RunKind.RUN_TEXT,
            .text  = input[run_start..].copy(mem),
            .style = compute_style(style_stack),
        });
    }

    style_stack.free();
    return out;
}
