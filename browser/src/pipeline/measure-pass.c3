module pipeline;

import std::math::vector;
import raylib6::rl;
import render;

struct FontSet
{
    RLFont regular;
    RLFont bold;
    RLFont italic;
    RLFont bold_italic;
}

struct TextData
{
    String raw;        // source string, what WASM owns
    RichText richText; // computed lazily, owned by engine
    bool dirty;        // needs reparse
    float fontSize;
}

struct ImageData
{
	Vec2 size;
}

fn Vec2 measure_rich_text(TextData* data, FontSet* fonts)
{
    float cursor = 0.0f;
    foreach (TextRun run : data.richText.runs)
    {
        switch (run.kind)
        {
            case RunKind.RUN_TEXT:
                RLFont font = font_for_style(fonts, run.style);
                cursor += rl::measure_text_ex(font, (ZString)run.text, data.fontSize, 0).x;
            case RunKind.RUN_EMOJI:
                cursor += data.fontSize;
        }
    }
    return { cursor, data.fontSize };
}

fn RLFont font_for_style(FontSet* fonts, FontStyle style)
{
    switch (style)
    {
        case FontStyle.BOLD:        return fonts.bold;
        case FontStyle.ITALIC:      return fonts.italic;
        case FontStyle.BOLD_ITALIC: return fonts.bold_italic;
        default:                    return fonts.regular;
    }
}

fn void Scene.measure_pass(&self, Element* el)
{
    switch (el.kind)
    {
        case ElementKind.TEXT:
            TextData* td = (TextData*)el.data;
			if (td.dirty)
			{
				td.richText.free();
				td.richText = render::create_rich_text(td.raw);
				td.dirty = false;
			}
			el.measured.size = measure_rich_text(td, &self.fonts);
        case ElementKind.IMAGE:
            ImageData* id = (ImageData*)el.data;
            el.measured.size = id.size;
        case ElementKind.PANEL:
            // nothing, size comes purely from layout formula
    }

    foreach (Element* child : el.children)
    {
        self.measure_pass(child);
    }

    el.dirtyFlags &= ~DirtyFlags.MEASURE;
}
