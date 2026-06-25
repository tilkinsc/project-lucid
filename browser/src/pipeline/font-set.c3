module pipeline;

import raylib6::rl;
import render;

fn RLFont FontSet.for_style(&self, FontStyle style)
{
    switch (style)
    {
        case FontStyle.BOLD:        return self.bold;
        case FontStyle.ITALIC:      return self.italic;
        case FontStyle.BOLD_ITALIC: return self.bold_italic;
        default:                    return self.regular;
    }
}

fn void FontSet.free(&self)
{
    rl::unload_font(self.regular);
    rl::unload_font(self.bold);
    rl::unload_font(self.italic);
    rl::unload_font(self.bold_italic);
}
